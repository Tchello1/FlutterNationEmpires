import '../persistencia/entidade/nacao.dart';
import '../persistencia/entidade/unidade_militar.dart';
import 'unit_types.dart';

typedef EventSink = void Function(String type, String message);

class MilitarService {
  // Buffer para acumular frações de soldados recrutados (por Nação)
  static final Map<int, double> _recrutBuffer = {};

  // Suaviza ganho de XP quando já está alto
  static double _xpDamp(double xp) =>
      xp <= 80 ? 1.0 : (1.0 - (xp - 80) / 20).clamp(0.0, 1.0);

  static double manutencaoNecessariaDia(Nacao n) {
    double soma = 0.0;
    for (final u in n.exercito) {
      final t = UnitTypes.get(u.typeId);
      soma += (u.efetivo / 1000.0) * t.upkeepPer1000Dia;
    }
    return soma;
  }

  /// Automático, sem pool e sem attrition:
  /// - "Unidades" define um CAP (referência quando alvo=0)
  /// - alvo > 0 força acima do CAP
  /// - Recrut = fR * militarDia (constante), limitado pelo que falta até o alvo
  /// - Treino = fT * militarDia
  /// - Contabiliza déficit/superávit militar no caixa/saldo
  static void updateAuto({
    required Nacao n,
    required double dtDays,
    required double militarDia,
    EventSink? onEvent,
  }) {
    // 0) Normaliza fatias internas
    double fU = n.alocMilUnidadesPct.clamp(0, 1);
    double fR = n.alocMilRecrutPct.clamp(0, 1);
    double fT = n.alocMilTreinoPct.clamp(0, 1);
    final soma = fU + fR + fT;
    if (soma <= 1e-9) { fU = 0.6; fR = 0.3; fT = 0.1; } else { fU /= soma; fR /= soma; fT /= soma; }

    // 1) Parâmetros (infantaria como proxy)
    final t = UnitTypes.infantry;
    final upkeepPerSoldierDia = t.upkeepPer1000Dia / 1000.0;
    final recruitCostPerSoldier = t.recruitCostPer1000 / 1000.0;
    final trainCostPerXpPerSoldier = t.trainCostPerXPper1000 / 1000.0;

    // 2) Garante ao menos 1 unidade
    if (n.exercito.isEmpty) {
      n.exercito = [
        UnidadeMilitar(
          id: 'u${DateTime.now().microsecondsSinceEpoch}',
          nacaoId: n.id,
          typeId: t.id,
          efetivo: 0,
          xp: 10.0,
          hp: 100.0,
        )
      ];
    }

    // 3) Estado atual e CAP (referência)
    int efetivoAtual = n.exercito.fold<int>(0, (a, u) => a + u.efetivo);
    final capDouble = (fU * militarDia) / (upkeepPerSoldierDia > 0 ? upkeepPerSoldierDia : 1e9);
    final capEfetivo = capDouble.isFinite ? capDouble.round() : 0;

    // 4) Alvo: 0 => seguir CAP; >0 => forçar alvo
    final targetEfetivo = (n.milAlvoEfetivo > 0) ? n.milAlvoEfetivo : capEfetivo;

    // 5) DEMOBILIZAÇÃO imediata se estiver acima do alvo
    if (efetivoAtual > targetEfetivo) {
      int excesso = efetivoAtual - targetEfetivo;
      for (int i = n.exercito.length - 1; i >= 0 && excesso > 0; i--) {
        final u = n.exercito[i];
        final take = excesso < u.efetivo ? excesso : u.efetivo;
        u.efetivo -= take;
        excesso -= take;
      }
      // mantém pelo menos 1 unidade
      n.exercito = n.exercito.where((u) => u.efetivo > 0 || n.exercito.length == 1).toList();
      efetivoAtual = targetEfetivo;
      if (onEvent != null) onEvent('mil_demob', 'Efetivo reduzido para $targetEfetivo');
    }

    // 6) RECRUTAMENTO (limitado ao que falta até o alvo)
    double gastoRecrutDia = 0.0;
    if (recruitCostPerSoldier > 0 && efetivoAtual < targetEfetivo) {
      final verbaRecrutPasso = (militarDia * fR) * dtDays;
      final falta = (targetEfetivo - efetivoAtual).clamp(0, 1<<31);
      final maxVerbaPorAlvo = falta * recruitCostPerSoldier;

      final verbaUsada = verbaRecrutPasso.clamp(0.0, maxVerbaPorAlvo.toDouble());
      gastoRecrutDia = verbaUsada / dtDays;

      final prevFrac = _recrutBuffer[n.id] ?? 0.0;
      final novosFrac = verbaUsada / recruitCostPerSoldier;
      double totalFrac = prevFrac + (novosFrac.isFinite ? novosFrac : 0.0);

      int add = totalFrac.floor();
      totalFrac -= add;

      if (add > falta) { totalFrac += (add - falta); add = falta; }

      if (add > 0) {
        n.exercito.last.efetivo += add;
        efetivoAtual += add;
        if (onEvent != null) onEvent('mil_recruit', 'Recrutados $add soldados');
      }
      _recrutBuffer[n.id] = totalFrac;
    }

    // 7) TREINO (sempre consegue gastar; se não houver efetivo, gasto=0)
    double gastoTreinoDia = 0.0;
    final verbaTreino = (militarDia * fT) * dtDays;
    if (verbaTreino > 0 && trainCostPerXpPerSoldier > 0 && efetivoAtual > 0) {
      gastoTreinoDia = verbaTreino / dtDays;

      final totalPeso = n.exercito.fold<double>(0.0, (acc, u) {
        final peso = (u.efetivo.toDouble()) * (u.priorTreino ? 2.0 : 1.0);
        return acc + peso;
      });

      if (totalPeso > 0) {
        for (final u in n.exercito) {
          final peso = (u.efetivo.toDouble()) * (u.priorTreino ? 2.0 : 1.0);
          if (peso <= 0) continue;

          final share = peso / totalPeso;
          final verbaU = verbaTreino * share;

          final custoXPUnit = u.efetivo * trainCostPerXpPerSoldier;
          if (custoXPUnit <= 0) continue;

          final ganhoXP = (verbaU / custoXPUnit) * _xpDamp(u.xp);
          if (ganhoXP > 0) {
            u.xp = (u.xp + ganhoXP).clamp(0.0, 100.0);
          }
        }
      } else {
        gastoTreinoDia = 0.0;
      }
    }

    // 8) MANUTENÇÃO após (de)mobilização e eventual recrutamento
    final manutDia = manutencaoNecessariaDia(n);

    // 9) CONTABILIDADE: superávit/deficit vs militarDia
    final gastoTotalDia = manutDia + gastoRecrutDia + gastoTreinoDia;
    final delta = militarDia - gastoTotalDia; // + => superávit | - => déficit

    if (delta.abs() > 1e-12) {
      n.economia.caixa += delta * dtDays;
      n.economia.saldo += delta;
      if (onEvent != null) {
        if (delta >= 0) {
          onEvent('mil_superavit', 'Superávit militar diário: ${delta.toStringAsFixed(2)}');
        } else {
          onEvent('mil_deficit', 'Déficit militar diário: ${(-delta).toStringAsFixed(2)}');
        }
      }
    }

    // 10) Sem attrition e sem pool
  }
}

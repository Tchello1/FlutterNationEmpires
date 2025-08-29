import '../persistencia/entidade/nacao.dart';

class EconomiaService {
  // ---------------- Balance / parâmetros ----------------
  static const double gBase = 0.012;   // +1.2% a.a. base
  static const double kInfra = 0.10;   // infraSharePIB * 0.10 (pp/ano)
  static const double kSatisf = 0.02;  // (satisf-0.5) * 2% a.a.

  static const double taxSweet = 0.20;    // “ponto doce” de imposto
  static const double kTaxExcess = 0.05;  // excesso * 5% (pp/ano)

  static const double infraNeedShare = 0.015; // 1.5% do PIB/ano
  static const double kInfraGap = 0.70;       // gap * 0.70 (pp/ano)

  static const double basePop = 0.010;     // 1% a.a.
  static const double kPopHappy = 0.010;   // +1% * (satisf - 0.5) a.a.

  static const double caixaDebtWarn = 0.20; // se caixa < -20% do PIB
  static const double kHappyDebt = 0.01;    // -0.01/ano na satisfação

  static double _clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

  // Normaliza shares das três rubricas; se tudo 0, distribui 1/3 cada
  static ({double p, double m, double i}) normalizeShares(double p, double m, double i) {
    final total = (p + m + i);
    if (total <= 1e-9) {
      return (p: 1/3, m: 1/3, i: 1/3);
    }
    return (p: p / total, m: m / total, i: i / total);
  }

  // ---------------- Breakdown (p/ painel) ----------------
  static GrowthBreakdown breakdown(Nacao n) {
    final e = n.economia;

    // Receita e orçamento
    final receitaAno = e.pib * e.impostoPct;
    final orcAno = receitaAno * e.orcamentoPct;

    // Shares normalizados
    final sh = normalizeShares(e.pesquisaPct, e.militarPct, e.infraPct);

    // Gasto efetivo em infra como fração do PIB
    final despInfraAno = orcAno * sh.i;
    final infraSharePIB = (e.pib <= 0) ? 0.0 : (despInfraAno / e.pib);

    // Termos de crescimento
    final base = gBase;
    final infra = infraSharePIB * kInfra;
    final satisf = (n.satisfacao - 0.5) * kSatisf;

    final excesso = (e.impostoPct - taxSweet);
    final taxPenalty = (excesso > 0 ? excesso : 0) * kTaxExcess;

    final gap = infraNeedShare - infraSharePIB;
    final infraGapPenalty = (gap > 0 ? gap : 0) * kInfraGap;

    const researchBonus = 0.0; // gancho p/ futuro (ex.: techs)

    final total = base + infra + satisf - taxPenalty - infraGapPenalty + researchBonus;

    return GrowthBreakdown(
      base: base,
      infra: infra,
      satisf: satisf,
      taxPenalty: taxPenalty,
      infraGapPenalty: infraGapPenalty,
      researchBonus: researchBonus,
      total: total,
      receitaAno: receitaAno,
      orcamentoAno: orcAno,
      despInfraAno: despInfraAno,
      infraSharePIB: infraSharePIB,
    );
  }

  static double calcularGrowthAnual(Nacao n) => breakdown(n).total;

  // Passo de simulação
  static double step(Nacao n, double dtDays) {
    final e = n.economia;
    final years = dtDays / 365.0;

    // Receita e orçamento
    final receitaAno = e.pib * e.impostoPct;
    final orcAno = receitaAno * e.orcamentoPct;

    // Shares
    final sh = normalizeShares(e.pesquisaPct, e.militarPct, e.infraPct);

    // Despesas anuais por rubrica
    final despPesquisaAno = orcAno * sh.p;
    final despMilitarAno  = orcAno * sh.m;
    final despInfraAno    = orcAno * sh.i;

    // Fluxo de caixa
    final despAno = despPesquisaAno + despMilitarAno + despInfraAno; // = orcAno
    final saldoAno = receitaAno - despAno;
    final saldoDia = saldoAno / 365.0;

    e.caixa += saldoDia * dtDays;
    e.saldo = saldoDia;

    // Satisfação
    final infraSharePIB = (e.pib <= 0) ? 0.0 : (despInfraAno / e.pib);
    final gapInfraHappy = infraSharePIB - infraNeedShare;
    final excessoImp = (e.impostoPct - taxSweet);

    double dHappy = 0.0;
    dHappy += 0.5 * gapInfraHappy; // mesmo coeficiente do breakdown, mas acumulado
    dHappy -= (excessoImp > 0 ? 0.6 * excessoImp : 0.0);
    if (e.caixa < -caixaDebtWarn * e.pib) dHappy -= kHappyDebt;

    n.satisfacao = _clamp01(n.satisfacao + dHappy * years);

    // Crescimento do PIB
    final g = calcularGrowthAnual(n);
    e.pib *= (1.0 + g * years);

    // População
    final rPop = basePop + kPopHappy * (n.satisfacao - 0.5);
    n.populacao = (n.populacao * (1.0 + rPop * years)).round();

    e.crescimento = g;
    return g;
  }
}

class GrowthBreakdown {
  final double base;
  final double infra;
  final double satisf;
  final double taxPenalty;
  final double infraGapPenalty;
  final double researchBonus;
  final double total;

  // extras p/ painel
  final double receitaAno;
  final double orcamentoAno;
  final double despInfraAno;
  final double infraSharePIB;

  const GrowthBreakdown({
    required this.base,
    required this.infra,
    required this.satisf,
    required this.taxPenalty,
    required this.infraGapPenalty,
    required this.researchBonus,
    required this.total,
    required this.receitaAno,
    required this.orcamentoAno,
    required this.despInfraAno,
    required this.infraSharePIB,
  });
}

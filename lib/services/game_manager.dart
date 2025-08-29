import 'dart:async';
import 'package:flutter/foundation.dart';

import '../persistencia/entidade/nacao.dart';
import '../persistencia/entidade/economia.dart';
import '../persistencia/entidade/mapa_hex.dart';
import '../persistencia/entidade/pesquisas.dart';
import '../persistencia/entidade/area.dart';
import '../persistencia/entidade/tecnologia.dart';

import 'mapa_service.dart';
import 'tech_tree.dart';

class GameEvent {
  final String type;
  final String message;
  final DateTime time;
  GameEvent(this.type, this.message) : time = DateTime.now();
}

class GameManager extends ChangeNotifier {
  // ---------- Config ----------
  final int largura;
  final int altura;

  double _speed = 1.0;
  bool _paused = false;
  final Duration _tickInterval = const Duration(milliseconds: 100);

  Timer? _timer;
  DateTime _lastUpdate = DateTime.now();
  double simDays = 0;

  // ---------- Estado ----------
  late List<MapaHex> mapa;
  late Nacao jogador;
  late Nacao ia;

  final List<GameEvent> _events = [];
  List<GameEvent> get events => List.unmodifiable(_events);
  void _pushEvent(String type, String message) {
    _events.add(GameEvent(type, message));
    if (_events.length > 200) {
      _events.removeRange(0, _events.length - 200);
    }
  }

  double get speed => _speed;
  bool get paused => _paused;
  double get growthAnnual => jogador.economia.crescimento; // usado no HUD

  GameManager({this.largura = 10, this.altura = 10}) {
    _initWorld();
    start();
  }

  // ---------- Mundo inicial ----------
  void _initWorld() {
    mapa = MapaService.gerarMapa(largura: largura, altura: altura);

    Pesquisas pesquisasDefault() {
      return Pesquisas(
        alocPctPorArea: {
          Area.economia: 0.35,
          Area.militar: 0.30,
          Area.infraestrutura: 0.20,
          Area.sociedade: 0.10,
          Area.ciencia: 0.05,
        },
        trilhas: {
          for (final a in Area.values) a: ResearchTrackState(),
        },
      );
    }

    jogador = Nacao(
      id: 1,
      nome: 'Jogador',
      populacao: 1_000_000,
      satisfacao: 0.65, // 65%
      economia: Economia(
        pib: 1000.0,
        crescimento: 0.03,
        inflacao: 0.04,
        impostoPct: 0.20,
        orcamentoPct: 1.00,   // % da arrecadação que vira orçamento (0..2.0)
        pesquisaPct: 0.34,    // shares do orçamento (somam 1 após normalização)
        militarPct:  0.33,
        infraPct:    0.33,
        caixa: 200.0,
        saldo: 0.0,
      ),
      pesquisas: pesquisasDefault(),
      exercito: const [],
      territorios: [],
      diplomacia: const {},
    );

    ia = Nacao(
      id: 2,
      nome: 'IA',
      populacao: 1_000_000,
      satisfacao: 0.60,
      economia: Economia(
        pib: 950.0,
        crescimento: 0.028,
        inflacao: 0.05,
        impostoPct: 0.18,
        orcamentoPct: 1.00,
        pesquisaPct: 0.30,
        militarPct:  0.40,
        infraPct:    0.30,
        caixa: 180.0,
        saldo: 0.0,
      ),
      pesquisas: pesquisasDefault(),
      exercito: const [],
      territorios: [],
      diplomacia: const {},
    );

    // Capital inicial
    _claimHex(jogador, _hexAt(largura ~/ 3, altura ~/ 2));
    _claimHex(ia, _hexAt(2 * largura ~/ 3, altura ~/ 2));

    // Escolhe algo inicial em cada área (só para ter barras andando)
    for (final a in Area.values) {
      _autoPickIfNull(jogador, a);
      _autoPickIfNull(ia, a);
    }
  }

  MapaHex _hexAt(int q, int r) => mapa.firstWhere((h) => h.q == q && h.r == r);

  void _claimHex(Nacao n, MapaHex hex) {
    if (hex.nacaoId == null) {
      hex.nacaoId = n.id;
      n.territorios.add(hex);
    }
  }

  // ---------- Loop ----------
  void start() {
    _timer?.cancel();
    _lastUpdate = DateTime.now();
    _timer = Timer.periodic(_tickInterval, (_) => _tick());
  }

  void pause() {
    _paused = true;
    notifyListeners();
  }

  void resume() {
    _paused = false;
    _lastUpdate = DateTime.now();
    notifyListeners();
  }

  void togglePause() => _paused ? resume() : pause();

  void setSpeed(double value) {
    _speed = value.clamp(0.0, 8.0);
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    if (_paused) return;

    final now = DateTime.now();
    final dtRealSec = now.difference(_lastUpdate).inMilliseconds / 1000.0;
    _lastUpdate = now;
    if (dtRealSec <= 0) return;

    final dtDays = dtRealSec * _speed; // 1 seg real = speed dias de jogo
    simDays += dtDays;

    _updateNation(jogador, dtDays);
    _updateNation(ia, dtDays);

    notifyListeners();
  }

  // ---------- Economia & Pesquisa ----------
  void _updateNation(Nacao n, double dtDays) {
    final e = n.economia;

    // 1) Arrecadação/dia (impostos)
    final impostosDia = (e.pib * e.impostoPct) / 365.0;

    // 2) Orçamento/dia (0..200% da arrecadação)
    final orcPct = e.orcamentoPct.clamp(0.0, 2.0);
    final orcamentoDia = impostosDia * orcPct;

    // 3) Shares do orçamento (normalizados para somar 1.0)
    var pShare = e.pesquisaPct.clamp(0.0, 1.0);
    var mShare = e.militarPct.clamp(0.0, 1.0);
    var iShare = e.infraPct.clamp(0.0, 1.0);
    final sum = (pShare + mShare + iShare);
    if (sum <= 0) {
      // fallback: divide igualmente
      pShare = mShare = iShare = 1 / 3;
    } else {
      pShare /= sum;
      mShare /= sum;
      iShare /= sum;
    }

    // 4) Montantes/dia por categoria
    final pAndDDia   = orcamentoDia * pShare;
    final militarDia = orcamentoDia * mShare;
    final infraDia   = orcamentoDia * iShare;

    // 5) Saldo e caixa
    e.saldo = impostosDia - orcamentoDia; // superávit/deficit
    e.caixa += e.saldo * dtDays;

    // 6) Pesquisa multi-área (consome pAndDDia)
    _normalizeResearchAlloc(n);
    for (final area in Area.values) {
      final track = n.pesquisas.trilhas[area]!;
      if (track.atual == null) _autoPickIfNull(n, area);

      final aloc = n.pesquisas.alocPctPorArea[area] ?? 0.0;
      if (aloc <= 0) continue;

      final cienciaDia = pAndDDia * aloc; // “pontos”/dia
      if (track.atual != null) {
        track.progresso += cienciaDia * dtDays;
        final custo = track.atual!.custoPesquisa <= 0 ? 1.0 : track.atual!.custoPesquisa;
        if (track.progresso >= custo) {
          n.pesquisas.concluidas.add(track.atual!.id);
          _pushEvent('research_done', '${n.nome}: ${track.atual!.nome} concluída');
          if (track.fila.isNotEmpty) {
            final proxId = track.fila.removeAt(0);
            track.atual = TechTree.byId[proxId];
            track.progresso = 0.0;
          } else {
            track.atual = null;
            track.progresso = 0.0;
            _autoPickIfNull(n, area);
          }
        }
      }
    }

    // 7) Efeitos simples de macro: crescimento do PIB e satisfação
    //    - Base: e.crescimento (anual)
    //    - Infra maior que ~33% do orçamento ajuda crescimento e satisfação; 0% piora
    //    - P&D também ajuda um pouco o crescimento
    //    - Imposto muito alto reduz satisfação
    final infraBias = (iShare - (1 / 3)); // -0.33..+0.66
    final pesqBias  = (pShare - (1 / 3));

    final extraGrowth =
        0.02 * infraBias + // até ±2% ao ano pela infra
        0.03 * pesqBias;   // até ±3% ao ano por P&D

    final effGrowthAnnual = (e.crescimento + extraGrowth).clamp(-0.10, 0.20); // segurança
    // aplica crescimento em passos diários
    e.pib += e.pib * (effGrowthAnnual * (dtDays / 365.0));

    // Satisfação: efeito de infra + efeito de impostos
    final taxBias = (e.impostoPct - 0.20); // acima de 20% começa a pesar
    final dSatPerYear =
        0.30 * infraBias    // infra alta melhora, baixa piora (até ±0.30/ano)
        - 0.25 * taxBias;   // impostos altos reduzem (±0.25/ano na faixa)

    n.satisfacao = (n.satisfacao + dSatPerYear * (dtDays / 365.0))
        .clamp(0.0, 1.0);

    // População: depende levemente de satisfação e infra
    final basePopGrowth = 0.008; // ~0.8%/ano base
    final popGrowth = (basePopGrowth + 0.01 * infraBias + 0.01 * (n.satisfacao - 0.5))
        .clamp(-0.01, 0.03); // limites razoáveis
    n.populacao = (n.populacao * (1 + popGrowth * (dtDays / 365.0))).round();
  }

  void _normalizeResearchAlloc(Nacao n) {
    final m = n.pesquisas.alocPctPorArea;
    for (final a in Area.values) {
      m[a] = (m[a] ?? 0).clamp(0.0, 1.0);
    }
    final s = Area.values.fold<double>(0, (acc, a) => acc + (m[a] ?? 0.0));
    if (s > 0) {
      for (final a in Area.values) {
        m[a] = (m[a]! / s);
      }
    }
  }

  void _autoPickIfNull(Nacao n, Area area) {
    final tk = n.pesquisas.trilhas[area]!;
    if (tk.atual != null) return;
    final disp = TechTree.disponiveisPara(n, area);
    if (disp.isNotEmpty) {
      tk.atual = disp.first;
      tk.progresso = 0.0;
    }
  }

  // ---------- UI helpers ----------
  void ajustarPoliticas({
    required Nacao n,
    double? impostoPct,
    double? orcamentoPct,   // 0..2
    double? pesquisaShare,  // 0..1
    double? militarShare,   // 0..1
    double? infraShare,     // 0..1
  }) {
    final e = n.economia;
    if (impostoPct   != null) e.impostoPct   = impostoPct.clamp(0.0, 1.0);
    if (orcamentoPct != null) e.orcamentoPct = orcamentoPct.clamp(0.0, 2.0);
    if (pesquisaShare!= null) e.pesquisaPct  = pesquisaShare.clamp(0.0, 1.0);
    if (militarShare != null) e.militarPct   = militarShare.clamp(0.0, 1.0);
    if (infraShare   != null) e.infraPct     = infraShare.clamp(0.0, 1.0);
    notifyListeners();
  }

  void ajustarDistPesquisa(Nacao n, Map<Area, double> dist) {
    n.pesquisas.alocPctPorArea = {
      for (final a in Area.values) a: (dist[a] ?? 0.0).clamp(0.0, 1.0),
    };
    _normalizeResearchAlloc(n);
    notifyListeners();
  }

  // P&D: seleção/fila
  void definirPesquisaArea(Nacao n, Area area, String techId) {
    final t = TechTree.byId[techId]!;
    final tk = n.pesquisas.trilhas[area]!;
    tk.atual = t;
    tk.progresso = 0.0;
    notifyListeners();
  }

  void adicionarFilaPesquisa(Nacao n, Area area, String techId) {
    final tk = n.pesquisas.trilhas[area]!;
    if (!tk.fila.contains(techId)) {
      tk.fila.add(techId);
      notifyListeners();
    }
  }

  void removerDaFilaPesquisa(Nacao n, Area area, String techId) {
    final tk = n.pesquisas.trilhas[area]!;
    tk.fila.remove(techId);
    notifyListeners();
  }

  void tomarHex(Nacao n, int q, int r) {
    final h = _hexAt(q, r);
    if (h.nacaoId == n.id) return;
    if (h.nacaoId != null) {
      final outro = (h.nacaoId == jogador.id) ? jogador : ia;
      outro.territorios.removeWhere((x) => x.q == q && x.r == r);
    }
    h.nacaoId = n.id;
    n.territorios.add(h);
    notifyListeners();
  }
}

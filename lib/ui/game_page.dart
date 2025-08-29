import 'package:flutter/material.dart';

import 'widgets/policy_sheet.dart';
import 'widgets/hud_bar.dart';
import 'widgets/map_canvas.dart';
import 'widgets/hex_composition_card.dart';
import 'widgets/research_status_sheet.dart';
import 'widgets/economy_panel.dart';
import '../services/game_manager.dart';
import '../persistencia/entidade/mapa_hex.dart';
import '../services/economia_service.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});
  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late final GameManager gm;

  MapaHex? _selecionado;
  double _zoom = 1.0;

  @override
  void initState() {
    super.initState();
    gm = GameManager(largura: 10, altura: 10);
  }

  @override
  void dispose() {
    gm.dispose();
    super.dispose();
  }

  Future<void> _abrirPesquisaStatus() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ResearchStatusSheet(gm: gm),
    );
  }

  Future<void> _abrirPoliticas() async {
    final e = gm.jogador.economia;
    final dist = gm.jogador.pesquisas.alocPctPorArea;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => PolicySheet(
        pib: e.pib,
        impostoPct: e.impostoPct,
        orcamentoPct: e.orcamentoPct,
        pesquisaShare: e.pesquisaPct,
        militarShare:  e.militarPct,
        infraShare:    e.infraPct,
        pesquisaDist: dist,
        onApply: (imp, orc, pShare, mShare, iShare, distPesquisa) {
          gm.ajustarPoliticas(
            n: gm.jogador,
            impostoPct:   imp,
            orcamentoPct: orc,
            pesquisaShare: pShare,
            militarShare:  mShare,
            infraShare:    iShare,
          );
          gm.ajustarDistPesquisa(gm.jogador, distPesquisa);
        },
      ),
    );
  }

  Future<void> _abrirEconomia() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => EconomyPanel(nacao: gm.jogador),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: gm,
      builder: (_, __) {
        final e = gm.jogador.economia;

        // crescimento anual calculado pelo EconomiaService (para o HUD)
        final breakdown = EconomiaService.breakdown(gm.jogador);
        final growthAnnual = breakdown.total; // fração, ex.: 0.027 = 2.7% a.a.

        return Scaffold(
          appBar: AppBar(title: const Text('CivLite')),
          body: Column(
            children: [
              HudBar(
                simDays: gm.simDays,
                economia: e,
                paused: gm.paused,
                speed: gm.speed,
                zoom: _zoom,
                onTogglePause: gm.togglePause,
                onSpeedChanged: gm.setSpeed,
                onZoomChanged: (v) => setState(() => _zoom = v),
                onOpenPolicies: _abrirPoliticas,
                onOpenResearch: _abrirPesquisaStatus,
                onOpenEconomy: _abrirEconomia,
                populacao: gm.jogador.populacao,
                satisfacao: gm.jogador.satisfacao,
                growthAnnual: growthAnnual,
              ),
              Expanded(
                child: MapCanvas(
                  mapa: gm.mapa,
                  zoom: _zoom,
                  selecionado: _selecionado,
                  onTapHex: (hex) => setState(() => _selecionado = hex),
                ),
              ),
              if (_selecionado != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: HexCompositionCard(
                    composicao: _selecionado!.composicao,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

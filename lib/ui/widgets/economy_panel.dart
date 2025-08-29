import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import '../../persistencia/entidade/nacao.dart';
import '../../services/economia_service.dart';

class EconomyPanel extends StatelessWidget {
  const EconomyPanel({super.key, required this.nacao});
  final Nacao nacao;

  @override
  Widget build(BuildContext context) {
    final e = nacao.economia;
    final b = EconomiaService.breakdown(nacao);

    // Com base no breakdown já temos receita/orçamento/infraShare
    final receitaAno = b.receitaAno;
    final orcAno = b.orcamentoAno;

    final despPesquisaAno = orcAno * EconomiaService.normalizeShares(e.pesquisaPct, e.militarPct, e.infraPct).p;
    final despMilitarAno  = orcAno * EconomiaService.normalizeShares(e.pesquisaPct, e.militarPct, e.infraPct).m;
    final despInfraAno    = orcAno * EconomiaService.normalizeShares(e.pesquisaPct, e.militarPct, e.infraPct).i;

    final despAno = despPesquisaAno + despMilitarAno + despInfraAno;
    final saldoAno = receitaAno - despAno;
    final saldoDia = saldoAno / 365.0;

    // Crescimento populacional
    const basePop = EconomiaService.basePop;
    const kPopHappy = EconomiaService.kPopHappy;
    final gPop = basePop + kPopHappy * (nacao.satisfacao - 0.5);

    // Projeções (1 ano)
    final projPIB1y = e.pib * (1.0 + b.total);
    final projCaixa1y = e.caixa + saldoDia * 365.0;
    final projPop1y = (nacao.populacao * (1.0 + gPop)).round();

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 12),
            Text('Economia', style: Theme.of(context).textTheme.titleMedium),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  _Section(
                    title: 'Visão geral',
                    children: [
                      _kv('PIB atual', _fmt(e.pib)),
                      _kv('Crescimento do PIB (a.a.)', _pct(b.total, signed: true)),
                      _kv('População', _fmtPop(nacao.populacao)),
                      _kv('Crescimento da população (a.a.)', _pct(gPop, signed: true)),
                      _kv('Satisfação', _pct(nacao.satisfacao)),
                      const SizedBox(height: 6),
                      _kv('Receita/ano', _fmt(receitaAno)),
                      _kv('Orçamento (da receita)', '${(e.orcamentoPct * 100).toStringAsFixed(0)}%'),
                      _kv('Orçamento/ano', _fmt(orcAno)),
                      _kv('— P&D', _fmt(despPesquisaAno)),
                      _kv('— Militar', _fmt(despMilitarAno)),
                      _kv('— Infra', _fmt(despInfraAno)),
                      _kv('Saldo/dia', e.saldo.toStringAsFixed(2)),
                      _kv('Caixa', e.caixa.toStringAsFixed(1)),
                    ],
                  ),

                  const SizedBox(height: 12),
                  _Section(
                    title: 'O que puxa o crescimento do PIB',
                    children: [
                      _bar('Base',            b.base),
                      _bar('Infraestrutura',  b.infra),
                      _bar('Satisfação',      b.satisf),
                      _bar('Imposto acima do doce', -b.taxPenalty),
                      _bar('Infra per capita insuficiente', -b.infraGapPenalty),
                      if (b.researchBonus.abs() > 1e-9)
                        _bar('Bônus de pesquisa', b.researchBonus),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Valores em pontos percentuais/ano. Soma = ${_pct(b.total, signed: true)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  _Section(
                    title: 'Projeção (1 ano)',
                    children: [
                      _kv('PIB projetado', _fmt(projPIB1y)),
                      _kv('Caixa projetada', projCaixa1y.toStringAsFixed(1)),
                      _kv('População projetada', _fmtPop(projPop1y)),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // helpers
  static String _fmt(double v) => v.toStringAsFixed(1);
  static String _fmtPop(int pop) {
    if (pop >= 1000000000) return '${(pop / 1e9).toStringAsFixed(2)}B';
    if (pop >= 1000000) return '${(pop / 1e6).toStringAsFixed(2)}M';
    if (pop >= 1000) return '${(pop / 1e3).toStringAsFixed(1)}k';
    return pop.toString();
  }
  static String _pct(double v, {bool signed = false}) {
    final x = v * 100.0;
    final s = x.toStringAsFixed(1);
    if (signed && x >= 0) return '+$s%';
    return '$s%';
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(k)),
          Text(v, style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }

  Widget _bar(String label, double value) {
    final pct = (value * 100.0);
    final sign = pct >= 0 ? '+' : '';
    final show = '$sign${pct.toStringAsFixed(1)} pp';
    final frac = (pct.abs() / 5.0).clamp(0.0, 1.0);
    final Color bg = pct >= 0 ? Colors.green : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 180, child: Text(label)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: frac,
                minHeight: 10,
                color: bg,
                backgroundColor: bg.withValues(alpha: 0.15),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 70, child: Text(show, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            ...children,
          ],
        ),
      ),
    );
  }
}

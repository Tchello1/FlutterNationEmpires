import 'package:flutter/material.dart';
import '../../persistencia/entidade/nacao.dart';
import '../../persistencia/entidade/area.dart';

class ResearchStrip extends StatelessWidget {
  const ResearchStrip({
    super.key,
    required this.nacao,
    this.onOpenResearch,
  });

  final Nacao nacao;
  final VoidCallback? onOpenResearch;

  @override
  Widget build(BuildContext context) {
    final dist = nacao.pesquisas.alocPctPorArea;

    return Material(
      elevation: 3,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.science_outlined, size: 20),
            const SizedBox(width: 8),
            Text('Pesquisas', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(width: 12),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    for (final area in Area.values)
                      _AreaProgressPill(
                        label: area.label,
                        atual: nacao.pesquisas.trilhas[area]!.atual?.nome ?? '—',
                        pct: (() {
                          final tk = nacao.pesquisas.trilhas[area]!;
                          final custo = tk.atual?.custoPesquisa ?? 1.0;
                          if (tk.atual == null) return 0.0;
                          return (tk.progresso / (custo <= 0 ? 1.0 : custo))
                              .clamp(0.0, 1.0)
                              .toDouble();
                        })(),
                        alocPct: (dist[area] ?? 0.0),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (onOpenResearch != null)
              FilledButton.tonal(
                onPressed: onOpenResearch,
                child: const Text('Gerenciar'),
              ),
          ],
        ),
      ),
    );
  }
}

class _AreaProgressPill extends StatelessWidget {
  const _AreaProgressPill({
    required this.label,
    required this.atual,
    required this.pct,
    required this.alocPct,
  });

  final String label;
  final String atual;
  final double pct;     // 0..1
  final double alocPct; // 0..1

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceVariant,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label • ${(alocPct*100).toStringAsFixed(0)}%',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(atual, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: pct),
          ),
        ],
      ),
    );
  }
}

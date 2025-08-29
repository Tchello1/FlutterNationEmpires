import 'package:flutter/material.dart';
import '../../persistencia/entidade/nacao.dart';
import '../../persistencia/entidade/area.dart';
import '../../services/tech_tree.dart';

class ResearchSheet extends StatefulWidget {
  const ResearchSheet({
    super.key,
    required this.nacao,
    required this.onSetCurrent,   // (area, techId)
    required this.onEnqueue,      // (area, techId)
    required this.onRemoveFromQueue, // (area, techId)
  });

  final Nacao nacao;
  final void Function(Area area, String techId) onSetCurrent;
  final void Function(Area area, String techId) onEnqueue;
  final void Function(Area area, String techId) onRemoveFromQueue;

  @override
  State<ResearchSheet> createState() => _ResearchSheetState();
}

class _ResearchSheetState extends State<ResearchSheet> with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: Area.values.length, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dist = widget.nacao.pesquisas.alocPctPorArea;

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
            Text('Pesquisa por Áreas', style: Theme.of(context).textTheme.titleMedium),

            // chips com % por área
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  for (final a in Area.values)
                    Chip(
                      label: Text('${a.label}: ${( (dist[a] ?? 0)*100 ).toStringAsFixed(0)}%'),
                    ),
                ],
              ),
            ),

            TabBar(
              controller: _tab,
              isScrollable: true,
              tabs: [for (final a in Area.values) Tab(text: a.label)],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [for (final a in Area.values) _AreaPane(area: a, nacao: widget.nacao,
                  onSetCurrent: widget.onSetCurrent,
                  onEnqueue: widget.onEnqueue,
                  onRemoveFromQueue: widget.onRemoveFromQueue,
                )],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AreaPane extends StatelessWidget {
  const _AreaPane({
    required this.area,
    required this.nacao,
    required this.onSetCurrent,
    required this.onEnqueue,
    required this.onRemoveFromQueue,
  });

  final Area area;
  final Nacao nacao;
  final void Function(Area area, String techId) onSetCurrent;
  final void Function(Area area, String techId) onEnqueue;
  final void Function(Area area, String techId) onRemoveFromQueue;

  @override
  Widget build(BuildContext context) {
    final track = nacao.pesquisas.trilhas[area]!;
    ///final concluidas = nacao.pesquisas.concluidas;
    final disp = TechTree.disponiveisPara(nacao, area);

    final atual = track.atual;
    final custo = atual?.custoPesquisa ?? 1.0;
    final pct = atual == null ? 0.0 : (track.progresso / (custo <= 0 ? 1.0 : custo)).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView(
        children: [
          // atual
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.science),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(atual != null ? atual.nome : 'Sem tecnologia ativa',
                            style: Theme.of(context).textTheme.titleSmall),
                        if (atual != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              LinearProgressIndicator(value: pct.toDouble()),
                              const SizedBox(height: 6),
                              Text('Progresso: ${(pct*100).toStringAsFixed(0)}%  •  Custo: ${atual.custoPesquisa.toStringAsFixed(0)}'),
                            ],
                          )
                        else
                          const SizedBox(height: 4),
                        const SizedBox(height: 4),
                        Text(atual?.efeito ?? 'Selecione uma tecnologia abaixo.'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          Text('Disponíveis', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),

          // lista de tecnologias disponíveis
          ...disp.map((t) {
            ///final jaConcluida = concluidas.contains(t.id);
            return Card(
              child: ListTile(
                leading: const Icon(Icons.bolt),
                title: Text(t.nome),
                subtitle: Text('${t.era} • Custo: ${t.custoPesquisa.toStringAsFixed(0)}\n${t.efeito}'),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Selecionar agora',
                      onPressed: () => onSetCurrent(area, t.id),
                      icon: const Icon(Icons.playlist_add_check),
                    ),
                    IconButton(
                      tooltip: 'Adicionar à fila',
                      onPressed: () => onEnqueue(area, t.id),
                      icon: const Icon(Icons.queue),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 12),
          Text('Fila', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          if (track.fila.isEmpty)
            const Text('— sem itens na fila —')
          else
            ...track.fila.map((id) {
              final t = TechTree.byId[id]!;
              return Dismissible(
                key: ValueKey('fila_${area.name}_$id'),
                background: Container(color: Colors.red.withValues(alpha: 0.2)),
                onDismissed: (_) => onRemoveFromQueue(area, id),
                child: ListTile(
                  leading: const Icon(Icons.drag_handle),
                  title: Text(t.nome),
                  subtitle: Text('${t.era} • Custo: ${t.custoPesquisa.toStringAsFixed(0)}'),
                ),
              );
            }),

          const SizedBox(height: 12),
          Text('Concluídas', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              for (final id in nacao.pesquisas.concluidas.where((id) => TechTree.byId[id]!.area == area))
                Chip(
                  label: Text(TechTree.byId[id]!.nome),
                  avatar: const Icon(Icons.check, size: 16),
                )
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/game_manager.dart';
import '../../persistencia/entidade/area.dart';
import '../../services/tech_tree.dart';

class ResearchStatusSheet extends StatefulWidget {
  const ResearchStatusSheet({super.key, required this.gm});
  final GameManager gm;

  @override
  State<ResearchStatusSheet> createState() => _ResearchStatusSheetState();
}

class _ResearchStatusSheetState extends State<ResearchStatusSheet> {
  late Map<Area, double> _distLocal;
  late final Map<Area, TextEditingController> _controllers;
  bool _distOpen = false; // fechado por padrão

  @override
  void initState() {
    super.initState();
    _distLocal = {
      for (final a in Area.values)
        a: (widget.gm.jogador.pesquisas.alocPctPorArea[a] ?? 0.0),
    };
    _controllers = {
      for (final a in Area.values)
        a: TextEditingController(
            text: ((_distLocal[a]! * 100).round()).toString()),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double get _sumDist =>
      _distLocal.values.fold<double>(0, (acc, v) => acc + v);

  void _applyDist() {
    final sum = _sumDist;
    if (sum > 1.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A soma das áreas não pode ultrapassar 100%.'),
        ),
      );
      return;
    }
    widget.gm.ajustarDistPesquisa(widget.gm.jogador, _distLocal);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Distribuição de pesquisa aplicada')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gm = widget.gm;

    return SafeArea(
      child: AnimatedBuilder(
        animation: gm,
        builder: (_, __) {
          final n = gm.jogador;

          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.85,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Pesquisa por Áreas',
                    style: Theme.of(context).textTheme.titleMedium),

                // ------- Distribuição (painel dobrável) -------
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Card(
                    elevation: 1,
                    child: ExpansionTile(
                      initiallyExpanded: _distOpen,
                      onExpansionChanged: (v) =>
                          setState(() => _distOpen = v),
                      leading: const Icon(Icons.tune),
                      title: Row(
                        children: [
                          const Text('Distribuição de investimento'),
                          const Spacer(),
                          _SumBadge(percent: _sumDist * 100),
                        ],
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                      children: [
                        ...Area.values.map((a) => _distRow(a)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (_sumDist > 1.0)
                              Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      size: 18, color: Colors.red),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Soma > 100%',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: Colors.red),
                                  ),
                                ],
                              )
                            else
                              Text(
                                'Soma: ${(_sumDist * 100).toStringAsFixed(0)}%',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            const Spacer(),
                            FilledButton.tonal(
                              onPressed: _sumDist > 1.0 ? null : _applyDist,
                              child: const Text('Aplicar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ------- Legenda -------
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    children: const [
                      _LegendDot(color: Colors.blue, label: 'Atual'),
                      _LegendDot(color: Colors.amber, label: 'Disponível'),
                      _LegendDot(color: Colors.grey, label: 'Bloqueada'),
                      _LegendDot(color: Colors.green, label: 'Concluída'),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ------- Áreas com árvore horizontal -------
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    itemCount: Area.values.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final area = Area.values[i];
                      final track = n.pesquisas.trilhas[area]!;
                      final t = track.atual;
                      final custo = t?.custoPesquisa ?? 1.0;
                      final pct = t == null
                          ? 0.0
                          : (track.progresso /
                                  (custo <= 0 ? 1.0 : custo))
                              .clamp(0.0, 1.0)
                              .toDouble();
                      final distPct =
                          (widget.gm.jogador.pesquisas.alocPctPorArea[area] ??
                              0.0);

                      return Card(
                        elevation: 2,
                        child: Theme(
                          data: Theme.of(context).copyWith(
                              dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(
                                horizontal: 12),
                            childrenPadding: const EdgeInsets.only(
                                left: 8, right: 8, bottom: 12),
                            leading: _iconFor(area),
                            title: Text(
                              '${area.label} • ${(distPct * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t?.nome ?? 'Sem tecnologia ativa'),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child:
                                      LinearProgressIndicator(value: pct),
                                ),
                              ],
                            ),
                            children: [
                              const SizedBox(height: 8),
                              _AreaTreeHorizontal(area: area, gm: gm),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Fechar'),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ----- linha de distribuição com slider de 1% + campo editável -----
  Widget _distRow(Area a) {
    final percent = (_distLocal[a]! * 100).round();
    final controller = _controllers[a]!;

    void setPercent(int p) {
      if (p < 0) p = 0;
      if (p > 100) p = 100;
      final txt = p.toString();
      setState(() {
        _distLocal[a] = p / 100.0;
        // manter campo sincronizado quando veio do slider
        if (controller.text != txt) {
          controller.value = TextEditingValue(
            text: txt,
            selection: TextSelection.collapsed(offset: txt.length),
          );
        }
      });
    }

    return Row(
      children: [
        SizedBox(width: 120, child: Text(a.label)),
        Expanded(
          child: Slider(
            value: percent.toDouble(),
            min: 0,
            max: 100,
            divisions: 100, // passo de 1%
            label: '$percent%',
            onChanged: (v) => setPercent(v.round()),
          ),
        ),
        SizedBox(
          width: 64,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              isDense: true,
              suffixText: '%',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            onChanged: (txt) {
              // parse e clamp 0..100; mantemos caret no fim
              int p = int.tryParse(txt) ?? 0;
              if (p > 100) p = 100;
              setState(() {
                _distLocal[a] = p / 100.0;
                final norm = p.toString();
                if (norm != txt) {
                  controller.value = TextEditingValue(
                    text: norm,
                    selection: TextSelection.collapsed(offset: norm.length),
                  );
                }
              });
            },
            onSubmitted: (txt) {
              int p = int.tryParse(txt) ?? 0;
              if (p < 0) p = 0;
              if (p > 100) p = 100;
              setPercent(p);
            },
          ),
        ),
      ],
    );
  }
}

class _SumBadge extends StatelessWidget {
  const _SumBadge({required this.percent});
  final double percent;

  @override
  Widget build(BuildContext context) {
    final over = percent > 100.0;
    final bg = over
        ? Colors.red.withValues(alpha: 0.12)
        : Colors.blueGrey.withValues(alpha: 0.12);
    final fg = over ? Colors.red : Colors.blueGrey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        '${percent.toStringAsFixed(0)}%',
        style: TextStyle(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _AreaTreeHorizontal extends StatelessWidget {
  const _AreaTreeHorizontal({required this.area, required this.gm});
  final Area area;
  final GameManager gm;

  @override
  Widget build(BuildContext context) {
    final n = gm.jogador;
    final track = n.pesquisas.trilhas[area]!;
    final concluidas = n.pesquisas.concluidas;

    final ids = TechTree.byAreaIds[area]!;
    final levels = _computeLevels(ids, area);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int lvl = 0; lvl < levels.length; lvl++) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tier ${lvl + 1}',
                    style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 4),
                Wrap(
                  direction: Axis.vertical,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final id in levels[lvl])
                      _TechNode(
                        id: id,
                        area: area,
                        isCurrent: track.atual?.id == id,
                        isDone: concluidas.contains(id),
                        progress: _progressFor(id, track),
                        available: _availableFor(id, concluidas),
                        onPick: () =>
                            gm.definirPesquisaArea(gm.jogador, area, id),
                      ),
                  ],
                ),
              ],
            ),
            if (lvl != levels.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.chevron_right),
              ),
          ]
        ],
      ),
    );
  }

  List<List<String>> _computeLevels(List<String> ids, Area area) {
    final Map<String, int> memo = {};
    int levelOf(String id) {
      if (memo.containsKey(id)) return memo[id]!;
      final t = TechTree.byId[id]!;
      final prereqInArea =
          t.prerequisitos.where((p) => TechTree.byId[p]?.area == area).toList();
      if (prereqInArea.isEmpty) {
        memo[id] = 0;
      } else {
        int maxParent = -1;
        for (final p in prereqInArea) {
          final lp = levelOf(p);
          if (lp > maxParent) maxParent = lp;
        }
        memo[id] = maxParent + 1;
      }
      return memo[id]!;
    }

    int highest = 0;
    for (final id in ids) {
      final lvl = levelOf(id);
      if (lvl > highest) highest = lvl;
    }

    final List<List<String>> levels =
        List.generate(highest + 1, (_) => <String>[]);
    for (final id in ids) {
      levels[levelOf(id)].add(id);
    }
    for (final list in levels) {
      list.sort((a, b) =>
          TechTree.byId[a]!.nome.compareTo(TechTree.byId[b]!.nome));
    }
    return levels;
  }

  double _progressFor(String id, track) {
    if (track.atual?.id != id) return 0.0;
    final custo =
        track.atual!.custoPesquisa <= 0 ? 1.0 : track.atual!.custoPesquisa;
    return (track.progresso / custo).clamp(0.0, 1.0).toDouble();
  }

  bool _availableFor(String id, Set<String> concluidas) {
    final t = TechTree.byId[id]!;
    return t.prerequisitos.every(concluidas.contains);
  }
}

class _TechNode extends StatelessWidget {
  const _TechNode({
    required this.id,
    required this.area,
    required this.isCurrent,
    required this.isDone,
    required this.progress, // 0..1
    required this.available,
    required this.onPick,
  });

  final String id;
  final Area area;
  final bool isCurrent;
  final bool isDone;
  final double progress;
  final bool available;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final t = TechTree.byId[id]!;
    late Color bg;
    late final Widget avatar;
    Widget content;

    if (isCurrent) {
      bg = Colors.blue.withValues(alpha: 0.18);
      avatar = const Icon(Icons.science, size: 18);
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.nome,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('${t.era} • Custo: ${t.custoPesquisa.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          SizedBox(
            width: 180,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: progress),
            ),
          ),
        ],
      );
    } else if (isDone) {
      bg = Colors.green.withValues(alpha: 0.18);
      avatar = const Icon(Icons.check, size: 18);
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.nome,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('${t.era} • Concluída',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      );
    } else if (available) {
      bg = Colors.amber.withValues(alpha: 0.18);
      avatar = const Icon(Icons.play_arrow, size: 18);
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.nome,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('${t.era} • Custo: ${t.custoPesquisa.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          FilledButton.tonal(
            onPressed: onPick,
            child: const Text('Selecionar'),
          ),
        ],
      );
    } else {
      bg = Colors.grey.withValues(alpha: 0.18);
      avatar = const Icon(Icons.lock, size: 18);
      final reqNames =
          t.prerequisitos.map((p) => TechTree.byId[p]!.nome).join(', ');
      content = Tooltip(
        message:
            t.prerequisitos.isEmpty ? 'Pré-requisitos pendentes' : 'Requer: $reqNames',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('${t.era} • Bloqueada',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
    }

    return Container(
      width: 220,
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          avatar,
          const SizedBox(width: 8),
          Expanded(child: content),
        ],
      ),
    );
  }
}

Icon _iconFor(Area a) {
  switch (a) {
    case Area.militar:
      return const Icon(Icons.shield);
    case Area.economia:
      return const Icon(Icons.attach_money);
    case Area.infraestrutura:
      return const Icon(Icons.account_tree);
    case Area.sociedade:
      return const Icon(Icons.groups_2);
    case Area.ciencia:
      return const Icon(Icons.science);
  }
}

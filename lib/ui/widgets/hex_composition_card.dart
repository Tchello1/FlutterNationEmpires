import 'package:flutter/material.dart';

class HexCompositionCard extends StatelessWidget {
  const HexCompositionCard({super.key, required this.composicao});
  final Map<String, double> composicao;

  @override
  Widget build(BuildContext context) {
    final items = composicao.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Composição do Hex', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (final e in items)
              Text('${e.key} • ${(e.value * 100).toStringAsFixed(0)}%'),
          ],
        ),
      ),
    );
  }
}

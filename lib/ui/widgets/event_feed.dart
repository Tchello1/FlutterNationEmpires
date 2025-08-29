import 'package:flutter/material.dart';
import '../../services/game_manager.dart';

class EventFeed extends StatelessWidget {
  const EventFeed({super.key, required this.gm});
  final GameManager gm;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: gm,
      builder: (_, __) {
        final items = gm.events.reversed.take(5).toList(); // últimos 5
        if (items.isEmpty) return const SizedBox.shrink();

        return Card(
          elevation: 6,
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications_active, size: 18),
                      const SizedBox(width: 8),
                      const Text('Eventos'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  for (final e in items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(_iconFor(e.type), size: 16),
                          const SizedBox(width: 6),
                          Expanded(child: Text(e.message)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _iconFor(String t) {
    switch (t) {
      case 'research_done': return Icons.science;
      default: return Icons.circle;
    }
  }
}

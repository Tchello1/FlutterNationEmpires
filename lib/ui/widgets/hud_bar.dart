// lib/ui/widgets/hud_bar.dart
import 'package:flutter/material.dart';
import '../../persistencia/entidade/economia.dart';

class HudBar extends StatelessWidget {
  const HudBar({
    super.key,
    required this.simDays,
    required this.economia,
    required this.paused,
    required this.speed,
    required this.zoom,
    required this.onTogglePause,
    required this.onSpeedChanged,
    required this.onZoomChanged,
    required this.onOpenPolicies,
    required this.onOpenResearch,
    required this.onOpenEconomy,
    required this.onOpenArmy,        // <--- NOVO
    required this.populacao,
    required this.satisfacao,
    required this.growthAnnual,
  });

  final double simDays;
  final Economia economia;
  final bool paused;
  final double speed;
  final double zoom;

  final VoidCallback onTogglePause;
  final ValueChanged<double> onSpeedChanged;
  final ValueChanged<double> onZoomChanged;
  final VoidCallback onOpenPolicies;
  final VoidCallback onOpenResearch;
  final VoidCallback onOpenEconomy;
  final VoidCallback onOpenArmy;     // <--- NOVO

  final int populacao;
  final double satisfacao;
  final double growthAnnual;

  @override
  Widget build(BuildContext context) {
    final e = economia;

    // ajusta saldo “quase zero” para 0.0 (evita mostrar -0,00)
    final double saldoDisplay = (e.saldo.abs() < 1e-6) ? 0.0 : e.saldo;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      // Sem scroll horizontal: usamos Wrap para quebrar em múltiplas linhas
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          _pill('Dia: ${simDays.floor()}'),
          _pill('PIB: ${e.pib.toStringAsFixed(1)}'),
          _pill('Caixa: ${e.caixa.toStringAsFixed(1)}'),
          _pill('Saldo/Dia: ${saldoDisplay.toStringAsFixed(2)}'),
          _pill('Imp: ${(e.impostoPct * 100).toStringAsFixed(0)}%'),
          _pill('Pop: ${_fmtPop(populacao)}'),
          _pill('Satisf: ${(satisfacao * 100).toStringAsFixed(0)}%'),
          _pill('Cresc PIB: ${(growthAnnual * 100).toStringAsFixed(1)}% a.a.'),

          FilledButton(
            onPressed: onOpenPolicies,
            child: const Text('Políticas'),
          ),
          FilledButton.tonal(
            onPressed: onOpenResearch,
            child: const Text('Pesquisa'),
          ),
          FilledButton.tonal(
            onPressed: onOpenEconomy,
            child: const Text('Economia'),
          ),
          FilledButton.tonal(
            onPressed: onOpenArmy,            // <--- NOVO
            child: const Text('Exército'),
          ),

          FilledButton.tonal(
            onPressed: onTogglePause,
            child: Text(paused ? 'Retomar' : 'Pausar'),
          ),

          // bloco velocidade
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Vel:'),
              const SizedBox(width: 6),
              DropdownButton<double>(
                value: speed,
                items: const [
                  DropdownMenuItem(value: 0.5, child: Text('0.5×')),
                  DropdownMenuItem(value: 1.0, child: Text('1×')),
                  DropdownMenuItem(value: 2.0, child: Text('2×')),
                  DropdownMenuItem(value: 4.0, child: Text('4×')),
                ],
                onChanged: (v) => onSpeedChanged(v ?? 1.0),
              ),
            ],
          ),

          // bloco zoom
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Zoom:'),
              const SizedBox(width: 6),
              SizedBox(
                width: 120,
                child: Slider(
                  value: zoom,
                  min: 0.8,
                  max: 2.0,
                  divisions: 12,
                  label: '${zoom.toStringAsFixed(1)}×',
                  onChanged: onZoomChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.blueGrey.withValues(alpha: 0.15),
      ),
      child: Text(text),
    );
  }

  static String _fmtPop(int pop) {
    if (pop >= 1000000000) return '${(pop / 1e9).toStringAsFixed(2)}B';
    if (pop >= 1000000) return '${(pop / 1e6).toStringAsFixed(2)}M';
    if (pop >= 1000) return '${(pop / 1e3).toStringAsFixed(1)}k';
    return pop.toString();
  }
}

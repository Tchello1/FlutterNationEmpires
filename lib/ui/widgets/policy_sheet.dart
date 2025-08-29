import 'package:flutter/material.dart';
import '../../persistencia/entidade/area.dart';

class PolicySheet extends StatefulWidget {
  const PolicySheet({
    super.key,
    required this.pib,
    required this.impostoPct,
    required this.orcamentoPct,   // 0..2 (0..200%)
    required this.pesquisaShare,  // pesos/participações relativas (serão normalizadas)
    required this.militarShare,
    required this.infraShare,
    required this.pesquisaDist,   // devolvido inalterado
    required this.onApply,        // (imp, orc, pShare, mShare, iShare, distPesquisa)
  });

  final double pib;
  final double impostoPct;
  final double orcamentoPct;
  final double pesquisaShare;
  final double militarShare;
  final double infraShare;
  final Map<Area, double> pesquisaDist;

  final void Function(
    double impostoPct,
    double orcamentoPct,
    double pesquisaShare,
    double militarShare,
    double infraShare,
    Map<Area, double> distPesquisa,
  ) onApply;

  @override
  State<PolicySheet> createState() => _PolicySheetState();
}

class _PolicySheetState extends State<PolicySheet> {
  late double _imp;      // 0..1
  late double _orc;      // 0..2
  late double _pShare;   // pesos relativos (normalizados internamente)
  late double _mShare;
  late double _iShare;
  late Map<Area, double> _dist;

  @override
  void initState() {
    super.initState();
    _imp    = widget.impostoPct.clamp(0.0, 1.0);
    _orc    = widget.orcamentoPct.clamp(0.0, 2.0);
    _pShare = widget.pesquisaShare.clamp(0.0, 1.0);
    _mShare = widget.militarShare.clamp(0.0, 1.0);
    _iShare = widget.infraShare.clamp(0.0, 1.0);
    _dist   = Map.of(widget.pesquisaDist);
  }

  // ---- valores principais por dia ----
  double get _impostosDia  => (widget.pib * _imp) / 365.0;    // arrecadação bruta por dia
  double get _orcamentoDia => _impostosDia * _orc;            // gasto diário definido pelo jogador
  double get _saldoDia     => _impostosDia - _orcamentoDia;   // superávit/deficit por dia

  // ---- normalização das participações do orçamento (P&D / Militar / Infra) ----
  double get _sumShares => _pShare + _mShare + _iShare;
  double get _pNorm => _sumShares > 0 ? _pShare / _sumShares : 0.0;
  double get _mNorm => _sumShares > 0 ? _mShare / _sumShares : 0.0;
  double get _iNorm => _sumShares > 0 ? _iShare / _sumShares : 0.0;

  // montantes/dia por categoria após normalização
  double get _pdDia    => _orcamentoDia * _pNorm;
  double get _milDia   => _orcamentoDia * _mNorm;
  double get _infraDia => _orcamentoDia * _iNorm;

  void _onShareChanged(void Function() mutate) {
    setState(() {
      mutate();
      // Se não há nenhuma categoria com peso > 0, zera o orçamento.
      if ((_pShare + _mShare + _iShare) <= 1e-9) {
        _orc = 0.0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final corSaldo = _saldoDia >= 0
        ? Colors.green.withValues(alpha: 0.15)
        : Colors.red.withValues(alpha: 0.15);

    final bool noShares = _sumShares <= 1e-9;

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.80,
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
            Text('Políticas', style: Theme.of(context).textTheme.titleMedium),

            // ---- Resumo claro: impostos, orçamento e breakdown por dia ----
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PIB: ${widget.pib.toStringAsFixed(1)}'),
                            Text('Impostos: ${(_imp * 100).toStringAsFixed(0)}%'),
                            const SizedBox(height: 6),
                            Text('Arrecadação/dia: ${_impostosDia.toStringAsFixed(2)}'),
                            Text('Orçamento/dia: ${_orcamentoDia.toStringAsFixed(2)}  '
                                 '(${(_orc * 100).toStringAsFixed(0)}%)'),
                            const SizedBox(height: 6),
                            // Quebra do orçamento por categoria (normalizada)
                            Wrap(
                              spacing: 12,
                              runSpacing: 6,
                              children: [
                                _chipLinha(
                                  icon: Icons.science,
                                  label: 'P&D/dia',
                                  valor: _pdDia,
                                  pct: _pNorm,
                                ),
                                _chipLinha(
                                  icon: Icons.shield,
                                  label: 'Militar/dia',
                                  valor: _milDia,
                                  pct: _mNorm,
                                ),
                                _chipLinha(
                                  icon: Icons.engineering,
                                  label: 'Infra/dia',
                                  valor: _infraDia,
                                  pct: _iNorm,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: corSaldo,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${_saldoDia >= 0 ? 'Superávit' : 'Déficit'}: ${_saldoDia.toStringAsFixed(2)} / dia',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            if (noShares) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Nenhuma categoria com peso > 0. Orçamento zerado automaticamente.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ---- Sliders ----
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  _sliderTile(
                    icon: Icons.balance,
                    label: 'Impostos',
                    value: _imp,
                    min: 0, max: 1, divisions: 100,
                    suffix: '${(_imp * 100).toStringAsFixed(0)}%',
                    onChanged: (v) => setState(() => _imp = v),
                  ),
                  const SizedBox(height: 8),
                  _sliderTile(
                    icon: Icons.account_balance_wallet,
                    label: 'Orçamento (fração da arrecadação)',
                    value: _orc,
                    min: 0, max: 2, divisions: 200,
                    suffix: '${(_orc * 100).toStringAsFixed(0)}%',
                    // Desabilita quando não há categorias com peso > 0
                    onChanged: noShares ? null : (v) => setState(() => _orc = v),
                  ),
                  const SizedBox(height: 8),
                  _sliderTile(
                    icon: Icons.science,
                    label: 'Peso P&D (distribuição do orçamento)',
                    value: _pShare,
                    min: 0, max: 1, divisions: 100,
                    suffix: '${(_pNorm * 100).toStringAsFixed(0)}%', // mostra normalizado
                    onChanged: (v) => _onShareChanged(() => _pShare = v),
                  ),
                  const SizedBox(height: 8),
                  _sliderTile(
                    icon: Icons.shield,
                    label: 'Peso Militar (distribuição do orçamento)',
                    value: _mShare,
                    min: 0, max: 1, divisions: 100,
                    suffix: '${(_mNorm * 100).toStringAsFixed(0)}%',
                    onChanged: (v) => _onShareChanged(() => _mShare = v),
                  ),
                  const SizedBox(height: 8),
                  _sliderTile(
                    icon: Icons.engineering,
                    label: 'Peso Infra (distribuição do orçamento)',
                    value: _iShare,
                    min: 0, max: 1, divisions: 100,
                    suffix: '${(_iNorm * 100).toStringAsFixed(0)}%',
                    onChanged: (v) => _onShareChanged(() => _iShare = v),
                  ),
                ],
              ),
            ),

            // ---- Ações ----
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      widget.onApply(
                        _imp,
                        _orc,
                        _pShare,
                        _mShare,
                        _iShare,
                        _dist,
                      );
                      Navigator.pop(context);
                    },
                    child: const Text('Aplicar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sliderTile({
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String suffix,
    required ValueChanged<double>? onChanged,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(label)),
                Text(suffix),
              ],
            ),
            Slider(
              value: value,
              min: min, max: max, divisions: divisions,
              label: suffix,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipLinha({
    required IconData icon,
    required String label,
    required double valor,
    required double pct,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text('$label: ${valor.toStringAsFixed(2)}  (${(pct * 100).toStringAsFixed(0)}%)'),
        ],
      ),
    );
  }
}

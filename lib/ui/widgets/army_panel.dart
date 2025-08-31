import 'package:flutter/material.dart';
import '../../persistencia/entidade/nacao.dart';
import '../../persistencia/entidade/unidade_militar.dart';
import '../../services/militar_service.dart';
import '../../services/unit_types.dart';
import '../../services/economia_service.dart';

class ArmyPanel extends StatefulWidget {
  const ArmyPanel({
    super.key,
    required this.nacao,
    required this.onSetAllocAuto,
    required this.onSetTarget,
    required this.onTogglePriority,
  });

  final Nacao nacao;
  final void Function(double unidades, double recrut, double treino) onSetAllocAuto;
  final void Function(int alvo) onSetTarget;
  final void Function(String unitId) onTogglePriority;

  @override
  State<ArmyPanel> createState() => _ArmyPanelState();
}

class _ArmyPanelState extends State<ArmyPanel> {
  late double _fatU;
  late double _fatR;
  late double _fatT;
  late final TextEditingController _alvoCtrl;

  @override
  void initState() {
    super.initState();
    _fatU = widget.nacao.alocMilUnidadesPct;
    _fatR = widget.nacao.alocMilRecrutPct;
    _fatT = widget.nacao.alocMilTreinoPct;
    _alvoCtrl = TextEditingController(text: '${widget.nacao.milAlvoEfetivo}');
  }

  @override
  void dispose() {
    _alvoCtrl.dispose();
    super.dispose();
  }

  void _applyAlloc() {
    final s = _fatU + _fatR + _fatT;
    double fU = _fatU, fR = _fatR, fT = _fatT;
    if (s > 0) { fU /= s; fR /= s; fT /= s; }
    widget.onSetAllocAuto(fU, fR, fT);
    setState(() { _fatU = fU; _fatR = fR; _fatT = fT; });
  }

  void _applyTarget() {
    final alvo = int.tryParse(_alvoCtrl.text.trim()) ?? 0;
    widget.onSetTarget(alvo.clamp(0, 100000000));
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.nacao;
    final e = n.economia;

    // orçamento militar/dia (macro)
    final receitaAno = e.pib * e.impostoPct;
    final orcAno = receitaAno * e.orcamentoPct;
    final orcDia = orcAno / 365.0;

    final sh = EconomiaService.normalizeShares(e.pesquisaPct, e.militarPct, e.infraPct);
    final militarDia = orcDia * sh.m;

    // métricas
    final t = UnitTypes.infantry;
    final upkeepPerSoldierDia = t.upkeepPer1000Dia / 1000.0;
    final recruitCostPerSoldier = t.recruitCostPer1000 / 1000.0;

    final soma = (_fatU + _fatR + _fatT);
    final fU = soma > 0 ? _fatU / soma : 0.6;
    final fR = soma > 0 ? _fatR / soma : 0.3;
    final fT = soma > 0 ? _fatT / soma : 0.1;

    final efetivoAtual = n.exercito.fold<int>(0, (a, u) => a + u.efetivo);
    final manutAtualDia = efetivoAtual * upkeepPerSoldierDia;

    final capDouble = (fU * militarDia) / (upkeepPerSoldierDia > 0 ? upkeepPerSoldierDia : 1e9);
    final capEfetivo = capDouble.isFinite ? capDouble.round() : 0;

    final alvo = n.milAlvoEfetivo > 0 ? n.milAlvoEfetivo : capEfetivo;
    final falta = (alvo - efetivoAtual);
    final aindaRecruta = falta > 0;

    final recrutEstDia = recruitCostPerSoldier > 0 && aindaRecruta
        ? ((fR * militarDia) / recruitCostPerSoldier)
        : 0.0;

    // saldo militar estimado do passo = (orcamento) - (manutenção + recrut + treino)
    final gastoTreinoDia = fT * militarDia;
    final gastoRecrutDia = aindaRecruta ? fR * militarDia : 0.0;
    final gastoTotalDia = manutAtualDia + gastoRecrutDia + gastoTreinoDia;
    final saldoMilitarDia = militarDia - gastoTotalDia; // + superávit | - déficit

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
            Text('Exército (Automático)', style: Theme.of(context).textTheme.titleMedium),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  // Resumo
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _kv('Unidades', n.exercito.length.toString()),
                          _kv('Efetivo total', _fmtEfetivo(n.exercito)),
                          _kv('XP médio', n.exercito.isEmpty ? '-' :
                              (n.exercito.map((u)=>u.xp).reduce((a,b)=>a+b)/n.exercito.length).toStringAsFixed(1)),
                          const SizedBox(height: 6),
                          _kv('Orçamento militar / dia', militarDia.toStringAsFixed(2)),
                          _kv('Manutenção atual / dia', manutAtualDia.toStringAsFixed(2)),
                          _kv('Capacidade sustentável (efetivo)', capEfetivo.toString()),
                          _kv('Alvo de efetivo (0 => CAP)', alvo.toString()),
                          _kv('Recrutamento estimado / dia', recrutEstDia.toStringAsFixed(1)),
                          _kv('Saldo do orçamento militar / dia', saldoMilitarDia.toStringAsFixed(2)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  // Alvo de efetivo total
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Alvo de efetivo total', style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _alvoCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: '0 = seguir CAP',
                                    hintText: 'Ex.: 200000',
                                  ),
                                  onSubmitted: (_) => _applyTarget(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilledButton.tonal(
                                onPressed: _applyTarget,
                                child: const Text('Aplicar'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  // Fatias internas (Unidades / Recrut / Treino)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Alocação automática do orçamento militar', style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 8),
                          _sliderRow('Unidades (manutenção)', _fatU, (v)=> setState(()=> _fatU=v), showPct: true),
                          _sliderRow('Recrutamento', _fatR, (v)=> setState(()=> _fatR=v), showPct: true),
                          _sliderRow('Treinamento', _fatT, (v)=> setState(()=> _fatT=v), showPct: true),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              TextButton(onPressed: (){
                                setState((){ _fatU=0.6; _fatR=0.3; _fatT=0.1; });
                                _applyAlloc();
                              }, child: const Text('60/30/10')),
                              const Spacer(),
                              FilledButton(onPressed: _applyAlloc, child: const Text('Aplicar')),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  // Lista de unidades (prioridade de treino)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Unidades', style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 8),
                          if (n.exercito.isEmpty)
                            const Text('— sem unidades —')
                          else
                            ...n.exercito.map((u){
                              final ut = UnitTypes.get(u.typeId);
                              return ListTile(
                                leading: const Icon(Icons.shield),
                                title: Text('${ut.nome}  •  ${u.efetivo}'),
                                subtitle: Text('XP ${u.xp.toStringAsFixed(1)}  •  HP ${u.hp.toStringAsFixed(0)}'),
                                trailing: IconButton(
                                  tooltip: 'Priorizar treino',
                                  onPressed: ()=> widget.onTogglePriority(u.id),
                                  icon: Icon(u.priorTreino ? Icons.star : Icons.star_border),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Fechar')),
                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [Expanded(child: Text(k)), Text(v)]),
    );
  }

  Widget _sliderRow(String label, double value, ValueChanged<double> onChanged, {bool showPct=false}) {
    return Row(
      children: [
        SizedBox(width: 170, child: Text(label)),
        Expanded(
          child: Slider(
            value: value, min: 0, max: 1, divisions: 100,
            label: showPct ? '${(value*100).toStringAsFixed(0)}%' : value.toStringAsFixed(2),
            onChanged: onChanged,
          ),
        ),
        SizedBox(width: 60, child: Text(showPct ? '${(value*100).toStringAsFixed(0)}%' : value.toStringAsFixed(2), textAlign: TextAlign.right)),
      ],
    );
  }

  String _fmtEfetivo(List<UnidadeMilitar> xs) {
    final tot = xs.fold<int>(0, (a,b)=>a+b.efetivo);
    if (tot >= 1000000) return '${(tot/1e6).toStringAsFixed(2)}M';
    if (tot >= 1000)    return '${(tot/1e3).toStringAsFixed(1)}k';
    return tot.toString();
  }
}

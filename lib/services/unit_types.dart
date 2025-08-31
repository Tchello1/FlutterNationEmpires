class UnitType {
  final String id;
  final String nome;
  final String categoria;          // "Infantaria", "Blindados" ...
  final double powerPer1000;       // só p/ futuro (combate)
  final double upkeepPer1000Dia;   // custo de manutenção por 1000 / dia
  final double recruitCostPer1000; // custo p/ recrutar 1000 soldados
  final double trainCostPerXPper1000; // custo p/ +1 XP por 1000 soldados

  const UnitType({
    required this.id,
    required this.nome,
    required this.categoria,
    required this.powerPer1000,
    required this.upkeepPer1000Dia,
    required this.recruitCostPer1000,
    required this.trainCostPerXPper1000,
  });
}

class UnitTypes {
  static const UnitType infantry = UnitType(
    id: 'infantry',
    nome: 'Infantaria',
    categoria: 'Infantaria',
    powerPer1000: 10.0,
    upkeepPer1000Dia: 0.30,     // $$ / dia por 1000
    recruitCostPer1000: 15.0,   // $$ para “criar” 1000
    trainCostPerXPper1000: 0.10 // $$ por +1 XP p/ 1000
  );

  static const Map<String, UnitType> byId = {
    'infantry': infantry,
  };

  static UnitType get(String id) => byId[id]!;
}

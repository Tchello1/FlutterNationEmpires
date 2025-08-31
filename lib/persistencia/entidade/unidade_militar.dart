class UnidadeMilitar {
  final String id;        // ex.: "u_001"
  final int nacaoId;
  final String typeId;    // ex.: "infantry"

  int efetivo;            // nº de soldados
  double xp;              // 0..100
  double hp;              // 0..100
  bool priorTreino;       // dá mais peso no rateio de treino

  int q;                  // posição no mapa (futuro)
  int r;

  UnidadeMilitar({
    required this.id,
    required this.nacaoId,
    required this.typeId,
    required this.efetivo,
    this.xp = 10.0,
    this.hp = 100.0,
    this.priorTreino = false,
    this.q = 0,
    this.r = 0,
  });
}

class RecruitmentOrder {
  final String typeId;      // tipo (ex.: "infantry")
  final int alvoEfetivo;    // efetivo desejado (ex.: 1000)
  double progressoEfetivo;  // quanto já “fabricou” (soldados)

  RecruitmentOrder({
    required this.typeId,
    required this.alvoEfetivo,
    this.progressoEfetivo = 0.0,
  });
}

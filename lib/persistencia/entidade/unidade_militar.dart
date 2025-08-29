class UnidadeMilitar {
  String tipo;     // arqueiro, infantaria, tanque...
  double custo;    // custo para treinar
  double manutencao; // custo contínuo
  int forca;
  int alcance;
  int? q;          // posição no mapa (axial q)
  int? r;          // posição no mapa (axial r)

  UnidadeMilitar({
    required this.tipo,
    required this.custo,
    required this.manutencao,
    required this.forca,
    required this.alcance,
    this.q,
    this.r,
  });
}

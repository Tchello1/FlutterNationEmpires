class Recurso {
  String tipo;      // agrícola, mineral, energético, estratégico
  String nome;      // trigo, ferro, carvão, petróleo...
  int abundancia;   // nível/quantidade disponível

  Recurso({
    required this.tipo,
    required this.nome,
    required this.abundancia,
  });
}

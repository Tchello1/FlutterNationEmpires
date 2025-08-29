import 'economia.dart';
import 'mapa_hex.dart';
import 'unidade_militar.dart';
import 'pesquisas.dart';

class Nacao {
  int id;
  String nome;
  int populacao;
  double satisfacao; // 0..1 (ex.: 0.65 = 65%)
  Economia economia;

  // Pesquisa multi-área
  Pesquisas pesquisas;

  List<UnidadeMilitar> exercito;
  List<MapaHex> territorios;
  Map<String, String> diplomacia;

  Nacao({
    required this.id,
    required this.nome,
    required this.populacao,
    required this.satisfacao,
    required this.economia,
    required this.pesquisas,
    this.exercito = const [],
    this.territorios = const [],
    this.diplomacia = const {},
  });
}

import 'area.dart';

class Tecnologia {
  final String id;            // único
  final String nome;
  final String era;           // pré-história, medieval, industrial...
  final Area area;            // árvore a que pertence
  final double custoPesquisa; // custo em "pontos de ciência"
  final List<String> prerequisitos;
  final String efeito;

  const Tecnologia({
    required this.id,
    required this.nome,
    required this.era,
    required this.area,
    required this.custoPesquisa,
    this.prerequisitos = const [],
    required this.efeito,
  });
}

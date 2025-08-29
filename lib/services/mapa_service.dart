import 'dart:math';
import '../persistencia/entidade/mapa_hex.dart';

class MapaService {
  static const List<String> biomasBase = [
    'agua',
    'floresta',
    'planicie',
    'montanha',
  ];

  /// Gera um mapa 10x10 (padrão) com composição de biomas por hex.
  static List<MapaHex> gerarMapa({int largura = 10, int altura = 10}) {
    final random = Random();
    final List<MapaHex> mapa = [];

    for (int q = 0; q < largura; q++) {
      for (int r = 0; r < altura; r++) {
        // escolhe 2 ou 3 biomas diferentes para este hex
        final k = 2 + random.nextInt(2); // 2 ou 3
        final escolhidos = [...biomasBase]..shuffle(random);
        final selecionados = escolhidos.take(k).toList();

        // gera pesos aleatórios e normaliza para somar ~1
        final pesosBrutos = List<double>.generate(
          k,
          (_) => random.nextDouble() + 0.05, // evita 0 exato
        );
        final soma = pesosBrutos.fold<double>(0, (a, b) => a + b);
        final composicao = <String, double>{
          for (int i = 0; i < k; i++) selecionados[i]: pesosBrutos[i] / soma
        };

        mapa.add(MapaHex(q: q, r: r, composicao: composicao));
      }
    }
    return mapa;
  }
}

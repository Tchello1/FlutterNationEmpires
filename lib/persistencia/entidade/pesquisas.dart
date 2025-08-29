import 'tecnologia.dart';
import 'area.dart';

class ResearchTrackState {
  Tecnologia? atual;
  double progresso; // 0..custoPesquisa da atual
  List<String> fila; // ids de techs enfileiradas (opcional)

  ResearchTrackState({
    this.atual,
    this.progresso = 0.0,
    List<String>? fila,
  }) : fila = fila ?? [];
}

class Pesquisas {
  /// Frações 0..1 por área; soma recomendada = 1.0 (100%)
  Map<Area, double> alocPctPorArea;

  /// Estado por área
  Map<Area, ResearchTrackState> trilhas;

  /// Tecnologias concluídas (ids)
  Set<String> concluidas;

  Pesquisas({
    required this.alocPctPorArea,
    required this.trilhas,
    Set<String>? concluidas,
  }) : concluidas = concluidas ?? {};
}

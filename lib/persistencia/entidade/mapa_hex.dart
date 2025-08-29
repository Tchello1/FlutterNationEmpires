import 'recurso.dart';
import 'unidade_militar.dart';

/// Cada hex guarda uma composição percentual de biomas.
/// Ex.: {'agua': 0.2, 'floresta': 0.5, 'planicie': 0.3}
class MapaHex {
  int q; // axial q
  int r; // axial r
  Map<String, double> composicao; // soma ~ 1.0
  Recurso? recurso;               // opcional
  int? nacaoId;                   // dono (se houver)
  UnidadeMilitar? unidade;        // unidade presente (se houver)

  MapaHex({
    required this.q,
    required this.r,
    required this.composicao,
    this.recurso,
    this.nacaoId,
    this.unidade,
  });
}

import 'economia.dart';
import 'mapa_hex.dart';
import 'unidade_militar.dart';
import 'pesquisas.dart';

class Nacao {
  // ---- básicos ----
  int id;
  String nome;
  int populacao;
  double satisfacao;

  // ---- economia/pesquisa ----
  Economia economia;
  Pesquisas pesquisas;

  // ---- militar (automático) ----
  /// Unidades ativas
  List<UnidadeMilitar> exercito;

  /// Modo automático por orçamento
  bool milAuto;

  /// Alvo explícito de efetivo total.
  /// 0 = seguir o CAP sustentável calculado pelo orçamento.
  int milAlvoEfetivo;

  /// Fatias internas do orçamento militar (somam 1 após normalização)
  double alocMilUnidadesPct; // manutenção -> define CAP
  double alocMilRecrutPct;   // velocidade de recrutamento
  double alocMilTreinoPct;   // XP

  // ---- mapa/diplomacia ----
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
    this.milAuto = true,
    this.milAlvoEfetivo = 0,         // 0 => usar CAP sustentável
    this.alocMilUnidadesPct = 0.6,
    this.alocMilRecrutPct = 0.3,
    this.alocMilTreinoPct = 0.1,
    this.territorios = const [],
    this.diplomacia = const {},
  });
}

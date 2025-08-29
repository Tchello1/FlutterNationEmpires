class Economia {
  double pib;          // tamanho da economia
  double crescimento;  // taxa anual corrente (info)
  double inflacao;     // reservado p/ futuro

  // Receita
  double impostoPct;   // fração do PIB que vira receita (0..1)

  // Orçamento de investimentos (N O V O)
  // Fração da RECEITA que será gasta como "orçamento".
  // Pode ser >1.0 (gastar mais que arrecada -> déficit).
  double orcamentoPct; // ex.: 1.00 = 100% da receita, 1.50 = 150% da receita

  // Distribuição do orçamento (somar ~100%)
  double pesquisaPct;  // share do orçamento destinado a P&D
  double militarPct;   // share do orçamento destinado a militar
  double infraPct;     // share do orçamento destinado a infra

  // Caixa e fluxo
  double caixa;
  double saldo;        // por dia

  Economia({
    required this.pib,
    required this.crescimento,
    required this.inflacao,
    required this.impostoPct,
    required this.orcamentoPct,
    required this.pesquisaPct,
    required this.militarPct,
    required this.infraPct,
    required this.caixa,
    this.saldo = 0.0,
  });
}

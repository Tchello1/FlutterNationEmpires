import '../persistencia/entidade/tecnologia.dart';
import '../persistencia/entidade/area.dart';
import '../persistencia/entidade/nacao.dart';

class TechTree {
  static final List<Tecnologia> _all = [
    // ECONOMIA
    const Tecnologia(
      id: 'agricultura',
      nome: 'Agricultura',
      era: 'Pré-história',
      area: Area.economia,
      custoPesquisa: 120,
      efeito: 'Aumenta produção básica de alimentos.',
    ),
    const Tecnologia(
      id: 'moeda',
      nome: 'Moeda',
      era: 'Antiga',
      area: Area.economia,
      custoPesquisa: 180,
      prerequisitos: ['agricultura'],
      efeito: 'Desbloqueia comércio formal, +eficiência de arrecadação.',
    ),
    const Tecnologia(
      id: 'banco',
      nome: 'Banco',
      era: 'Medieval',
      area: Area.economia,
      custoPesquisa: 260,
      prerequisitos: ['moeda'],
      efeito: 'Eficiência financeira, base para crédito.',
    ),

    // MILITAR
    const Tecnologia(
      id: 'lanca',
      nome: 'Lança',
      era: 'Pré-história',
      area: Area.militar,
      custoPesquisa: 90,
      efeito: 'Desbloqueia infantaria leve.',
    ),
    const Tecnologia(
      id: 'bronze',
      nome: 'Bronze',
      era: 'Antiga',
      area: Area.militar,
      custoPesquisa: 160,
      prerequisitos: ['lanca'],
      efeito: 'Armas e armaduras melhores.',
    ),
    const Tecnologia(
      id: 'taticas',
      nome: 'Táticas',
      era: 'Clássica',
      area: Area.militar,
      custoPesquisa: 220,
      prerequisitos: ['bronze'],
      efeito: 'Bônus de combate.',
    ),

    // INFRA
    const Tecnologia(
      id: 'pedra',
      nome: 'Pedra Talhada',
      era: 'Pré-história',
      area: Area.infraestrutura,
      custoPesquisa: 80,
      efeito: 'Construções rudimentares.',
    ),
    const Tecnologia(
      id: 'estradas',
      nome: 'Estradas',
      era: 'Antiga',
      area: Area.infraestrutura,
      custoPesquisa: 140,
      prerequisitos: ['pedra'],
      efeito: 'Logística básica.',
    ),
    const Tecnologia(
      id: 'engenharia',
      nome: 'Engenharia',
      era: 'Medieval',
      area: Area.infraestrutura,
      custoPesquisa: 240,
      prerequisitos: ['estradas'],
      efeito: 'Melhora obras e logística.',
    ),

    // SOCIEDADE
    const Tecnologia(
      id: 'escrita',
      nome: 'Escrita',
      era: 'Antiga',
      area: Area.sociedade,
      custoPesquisa: 150,
      efeito: 'Educação básica, registros.',
    ),
    const Tecnologia(
      id: 'educacao',
      nome: 'Educação',
      era: 'Medieval',
      area: Area.sociedade,
      custoPesquisa: 230,
      prerequisitos: ['escrita'],
      efeito: 'Qualidade da mão de obra.',
    ),

    // CIÊNCIA
    const Tecnologia(
      id: 'matematica',
      nome: 'Matemática',
      era: 'Antiga',
      area: Area.ciencia,
      custoPesquisa: 170,
      efeito: 'Fundação científica.',
    ),
    const Tecnologia(
      id: 'algebra',
      nome: 'Álgebra',
      era: 'Medieval',
      area: Area.ciencia,
      custoPesquisa: 250,
      prerequisitos: ['matematica'],
      efeito: 'Aprimora pesquisas de todas as áreas (futuro).',
    ),
  ];

  static final Map<String, Tecnologia> byId = {
    for (final t in _all) t.id: t,
  };

  static final Map<Area, List<String>> byAreaIds = {
    for (final a in Area.values)
      a: _all.where((t) => t.area == a).map((t) => t.id).toList(),
  };

  static List<Tecnologia> disponiveisPara(Nacao n, Area area) {
    final concl = n.pesquisas.concluidas;
    final ids = byAreaIds[area]!;
    return ids
        .map((id) => byId[id]!)
        .where((t) =>
          !concl.contains(t.id) &&
          t.prerequisitos.every((p) => concl.contains(p))
        )
        .toList();
  }
}

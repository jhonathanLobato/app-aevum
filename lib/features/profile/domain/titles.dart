import 'level_curve.dart';

/// Título do jogador, escolhido numa lista de desbloqueados.
class TitleDef {
  const TitleDef(this.nome, this.condicao,
      {this.conquistaChave, this.rankMinimo});

  final String nome;

  /// Texto da condição para liberar (mostrado nos bloqueados).
  final String condicao;

  /// Desbloqueia com esta conquista (chave do catálogo)...
  final String? conquistaChave;

  /// ...ou ao alcançar este rank. Sem nenhum dos dois: sempre liberado.
  final String? rankMinimo;

  bool desbloqueado({required Set<String> conquistas, required String rank}) {
    if (conquistaChave != null) return conquistas.contains(conquistaChave);
    if (rankMinimo != null) return rankAtende(rank, rankMinimo!);
    return true;
  }
}

const tituloPadrao = 'Despertado';

const kTitleCatalog = <TitleDef>[
  TitleDef(tituloPadrao, 'Todos têm desde o início'),
  TitleDef('Iniciante', 'Conquista Primeiros Passos',
      conquistaChave: 'primeiros_passos'),
  TitleDef('Em Evolução', 'Conquista Evolução', conquistaChave: 'evolucao'),
  TitleDef('Disciplinado', 'Conquista Disciplina',
      conquistaChave: 'disciplina'),
  TitleDef('Constante', 'Conquista Constância', conquistaChave: 'constancia'),
  TitleDef('Veterano', 'Conquista Veterano', conquistaChave: 'veterano'),
  TitleDef('Inquebrável', 'Conquista Superação', conquistaChave: 'superacao'),
  TitleDef('Quebrador de Recordes', 'Conquista Quebra de Recorde',
      conquistaChave: 'quebra_de_recorde'),
  TitleDef('Levantador', 'Conquista Primeiro Milhar',
      conquistaChave: 'primeiro_milhar'),
  TitleDef('Caçador Rank E', 'Alcance o rank E', rankMinimo: 'E'),
  TitleDef('Caçador Rank D', 'Alcance o rank D', rankMinimo: 'D'),
  TitleDef('Caçador Rank C', 'Alcance o rank C', rankMinimo: 'C'),
  TitleDef('Caçador Rank B', 'Alcance o rank B', rankMinimo: 'B'),
  TitleDef('Caçador Rank A', 'Alcance o rank A', rankMinimo: 'A'),
  TitleDef('Caçador Rank S', 'Alcance o rank S', rankMinimo: 'S'),
];

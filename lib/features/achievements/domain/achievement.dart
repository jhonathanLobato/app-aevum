enum AchievementStatus { bloqueada, desbloqueada }

class Achievement {
  const Achievement({
    required this.id,
    required this.chave,
    required this.nome,
    required this.descricao,
    required this.icone,
    required this.requisito,
    required this.status,
    this.dataDesbloqueio,
  });

  final int id;

  /// Identifica a definição fixa do catálogo (ver [kAchievementCatalog]).
  final String chave;

  final String nome;
  final String descricao;
  final String icone;
  final String requisito;
  final AchievementStatus status;
  final DateTime? dataDesbloqueio;
}

class AchievementDefinition {
  const AchievementDefinition({
    required this.chave,
    required this.nome,
    required this.descricao,
    required this.icone,
    required this.requisito,
  });

  final String chave;
  final String nome;
  final String descricao;

  /// Nome de um ícone do Material Design (ver mapeamento na apresentação).
  final String icone;
  final String requisito;
}

/// Catálogo fixo de conquistas (seção 13). Para adicionar uma nova conquista
/// basta acrescentar uma definição aqui e o critério correspondente no
/// repositório.
const kAchievementCatalog = [
  AchievementDefinition(
    chave: 'primeiros_passos',
    nome: 'Primeiros Passos',
    descricao: 'Complete seu primeiro treino.',
    icone: 'flag',
    requisito: '1 treino concluído',
  ),
  AchievementDefinition(
    chave: 'evolucao',
    nome: 'Evolução',
    descricao: 'Bata seu primeiro recorde pessoal.',
    icone: 'trending_up',
    requisito: '1 recorde pessoal registrado',
  ),
  AchievementDefinition(
    chave: 'disciplina',
    nome: 'Disciplina',
    descricao: 'Complete 10 treinos.',
    icone: 'military_tech',
    requisito: '10 treinos concluídos',
  ),
  AchievementDefinition(
    chave: 'constancia',
    nome: 'Constância',
    descricao: 'Complete 25 treinos.',
    icone: 'military_tech',
    requisito: '25 treinos concluídos',
  ),
  AchievementDefinition(
    chave: 'veterano',
    nome: 'Veterano',
    descricao: 'Complete 100 treinos.',
    icone: 'military_tech',
    requisito: '100 treinos concluídos',
  ),
  AchievementDefinition(
    chave: 'superacao',
    nome: 'Superação',
    descricao: 'Bata um recorde pessoal após 7 ou mais dias sem treinar.',
    icone: 'bolt',
    requisito: 'PR após 7+ dias sem treinar',
  ),
  // Contagem de PRs, marco de volume e rank (categorias além de treinos
  // concluídos e do primeiro PR).
  AchievementDefinition(
    chave: 'quebra_de_recorde',
    nome: 'Quebra de Recorde',
    descricao: 'Bata 5 recordes pessoais.',
    icone: 'emoji_events',
    requisito: '5 recordes pessoais registrados',
  ),
  AchievementDefinition(
    chave: 'primeiro_milhar',
    nome: 'Primeiro Milhar',
    descricao: 'Acumule 1.000 kg de volume total.',
    icone: 'fitness_center',
    requisito: '1.000 kg de volume acumulado',
  ),
  AchievementDefinition(
    chave: 'rank_e',
    nome: 'Rank E',
    descricao: 'Passe no exame de rank e alcance o Rank E.',
    icone: 'military_tech',
    requisito: 'Exame de rank aprovado: Rank E ou superior',
  ),
];

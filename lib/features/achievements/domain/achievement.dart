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
    this.xp = 0,
    this.categoria = '',
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

  /// XP concedido ao desbloquear (0 = não concede).
  final int xp;

  /// Grupo da tela de Conquistas (ver [kAchievementCategories]).
  final String categoria;
}

class AchievementDefinition {
  const AchievementDefinition({
    required this.chave,
    required this.nome,
    required this.descricao,
    required this.icone,
    required this.requisito,
    required this.categoria,
    this.xp = 0,
  });

  final String chave;
  final String nome;
  final String descricao;

  /// Grupo da tela de Conquistas (ver [kAchievementCategories]).
  final String categoria;

  /// XP concedido ao desbloquear (uma única vez).
  final int xp;

  /// Nome de um ícone do Material Design (ver mapeamento na apresentação).
  final String icone;
  final String requisito;
}

/// Catálogo fixo de conquistas (seção 13). Para adicionar uma nova conquista
/// basta acrescentar uma definição aqui e o critério correspondente em
/// `DriftAchievementRepository._criterios`. O XP de cada uma (campo `xp`) é
/// concedido uma única vez, ao desbloquear.
const kAchievementCatalog = [
  AchievementDefinition(
    chave: 'primeiros_passos',
    nome: 'Primeiros Passos',
    descricao: 'Complete seu primeiro treino.',
    icone: 'flag',
    requisito: '1 treino concluído',
    categoria: 'Treino',
  ),
  AchievementDefinition(
    chave: 'evolucao',
    nome: 'Evolução',
    descricao: 'Bata seu primeiro recorde pessoal.',
    icone: 'trending_up',
    requisito: '1 recorde pessoal registrado',
    categoria: 'Força',
  ),
  AchievementDefinition(
    chave: 'disciplina',
    nome: 'Disciplina',
    descricao: 'Complete 10 treinos.',
    icone: 'military_tech',
    requisito: '10 treinos concluídos',
    categoria: 'Treino',
  ),
  AchievementDefinition(
    chave: 'constancia',
    nome: 'Constância',
    descricao: 'Complete 25 treinos.',
    icone: 'military_tech',
    requisito: '25 treinos concluídos',
    categoria: 'Treino',
  ),
  AchievementDefinition(
    chave: 'veterano',
    nome: 'Veterano',
    descricao: 'Complete 100 treinos.',
    icone: 'military_tech',
    requisito: '100 treinos concluídos',
    categoria: 'Treino',
  ),
  AchievementDefinition(
    chave: 'superacao',
    nome: 'Superação',
    descricao: 'Bata um recorde pessoal após 7 ou mais dias sem treinar.',
    icone: 'bolt',
    requisito: 'PR após 7+ dias sem treinar',
    categoria: 'Força',
  ),
  // Contagem de PRs, marco de volume e rank (categorias além de treinos
  // concluídos e do primeiro PR).
  AchievementDefinition(
    chave: 'quebra_de_recorde',
    nome: 'Quebra de Recorde',
    descricao: 'Bata 5 recordes pessoais.',
    icone: 'emoji_events',
    requisito: '5 recordes pessoais registrados',
    categoria: 'Força',
  ),
  AchievementDefinition(
    chave: 'primeiro_milhar',
    nome: 'Primeiro Milhar',
    descricao: 'Acumule 1.000 kg de volume total.',
    icone: 'fitness_center',
    requisito: '1.000 kg de volume acumulado',
    categoria: 'Força',
  ),
  AchievementDefinition(
    chave: 'rank_e',
    nome: 'Rank E',
    descricao: 'Passe no exame de rank e alcance o Rank E.',
    icone: 'military_tech',
    requisito: 'Exame de rank aprovado: Rank E ou superior',
    categoria: 'Rank',
  ),
  AchievementDefinition(
    chave: 'dedicado',
    nome: 'Dedicado',
    descricao: 'Complete 50 treinos.',
    icone: 'military_tech',
    requisito: '50 treinos concluídos',
    categoria: 'Treino',
    xp: 100,
  ),
  AchievementDefinition(
    chave: 'lenda_da_academia',
    nome: 'Lenda da Academia',
    descricao: 'Complete 250 treinos.',
    icone: 'military_tech',
    requisito: '250 treinos concluídos',
    categoria: 'Treino',
    xp: 200,
  ),
  AchievementDefinition(
    chave: 'imortal',
    nome: 'Imortal',
    descricao: 'Complete 500 treinos.',
    icone: 'military_tech',
    requisito: '500 treinos concluídos',
    categoria: 'Treino',
    xp: 300,
  ),
  AchievementDefinition(
    chave: 'madrugador',
    nome: 'Madrugador',
    descricao: 'Inicie 10 treinos antes das 7h.',
    icone: 'wb_twilight',
    requisito: '10 treinos iniciados antes das 7h',
    categoria: 'Treino',
    xp: 100,
  ),
  AchievementDefinition(
    chave: 'coruja',
    nome: 'Coruja',
    descricao: 'Inicie 10 treinos depois das 21h.',
    icone: 'bedtime',
    requisito: '10 treinos iniciados depois das 21h',
    categoria: 'Treino',
    xp: 100,
  ),
  AchievementDefinition(
    chave: 'maratona',
    nome: 'Maratona',
    descricao: 'Faça um treino de 2 horas ou mais.',
    icone: 'timer',
    requisito: 'Um treino de 2h ou mais',
    categoria: 'Treino',
    xp: 50,
  ),
  AchievementDefinition(
    chave: 'dez_toneladas',
    nome: 'Dez Toneladas',
    descricao: 'Acumule 10.000 kg de volume total.',
    icone: 'fitness_center',
    requisito: '10.000 kg de volume acumulado',
    categoria: 'Força',
    xp: 100,
  ),
  AchievementDefinition(
    chave: 'tita',
    nome: 'Titã',
    descricao: 'Acumule 100.000 kg de volume total.',
    icone: 'fitness_center',
    requisito: '100.000 kg de volume acumulado',
    categoria: 'Força',
    xp: 200,
  ),
  AchievementDefinition(
    chave: 'atlas',
    nome: 'Atlas',
    descricao: 'Acumule 1.000.000 kg de volume total.',
    icone: 'fitness_center',
    requisito: '1.000.000 kg de volume acumulado',
    categoria: 'Força',
    xp: 300,
  ),
  AchievementDefinition(
    chave: 'recordista',
    nome: 'Recordista',
    descricao: 'Bata 25 recordes pessoais.',
    icone: 'emoji_events',
    requisito: '25 recordes pessoais registrados',
    categoria: 'Força',
    xp: 100,
  ),
  AchievementDefinition(
    chave: 'lenda_dos_recordes',
    nome: 'Lenda dos Recordes',
    descricao: 'Bata 100 recordes pessoais.',
    icone: 'emoji_events',
    requisito: '100 recordes pessoais registrados',
    categoria: 'Força',
    xp: 200,
  ),
  AchievementDefinition(
    chave: 'uma_semana',
    nome: 'Uma Semana',
    descricao: 'Cumpra a missão diária 7 dias seguidos.',
    icone: 'local_fire_department',
    requisito: '7 dias seguidos',
    categoria: 'Missão diária',
    xp: 50,
  ),
  AchievementDefinition(
    chave: 'um_mes',
    nome: 'Um Mês',
    descricao: 'Cumpra a missão diária 30 dias seguidos.',
    icone: 'local_fire_department',
    requisito: '30 dias seguidos',
    categoria: 'Missão diária',
    xp: 100,
  ),
  AchievementDefinition(
    chave: 'cem_dias',
    nome: 'Cem Dias',
    descricao: 'Cumpra a missão diária 100 dias seguidos.',
    icone: 'local_fire_department',
    requisito: '100 dias seguidos',
    categoria: 'Missão diária',
    xp: 200,
  ),
  AchievementDefinition(
    chave: 'sistema_absoluto',
    nome: 'Sistema Absoluto',
    descricao: 'Cumpra a missão diária 365 dias seguidos.',
    icone: 'local_fire_department',
    requisito: '365 dias seguidos',
    categoria: 'Missão diária',
    xp: 300,
  ),
  AchievementDefinition(
    chave: 'mil_flexoes',
    nome: 'Mil Flexões',
    descricao: 'Acumule 1.000 flexões na missão diária.',
    icone: 'bolt',
    requisito: '1.000 flexões acumuladas',
    categoria: 'Missão diária',
    xp: 50,
  ),
  AchievementDefinition(
    chave: 'dez_mil_flexoes',
    nome: 'Dez Mil Flexões',
    descricao: 'Acumule 10.000 flexões na missão diária.',
    icone: 'bolt',
    requisito: '10.000 flexões acumuladas',
    categoria: 'Missão diária',
    xp: 200,
  ),
  AchievementDefinition(
    chave: 'mil_abdominais',
    nome: 'Mil Abdominais',
    descricao: 'Acumule 1.000 abdominais na missão diária.',
    icone: 'bolt',
    requisito: '1.000 abdominais acumulados',
    categoria: 'Missão diária',
    xp: 50,
  ),
  AchievementDefinition(
    chave: 'dez_mil_abdominais',
    nome: 'Dez Mil Abdominais',
    descricao: 'Acumule 10.000 abdominais na missão diária.',
    icone: 'bolt',
    requisito: '10.000 abdominais acumulados',
    categoria: 'Missão diária',
    xp: 200,
  ),
  AchievementDefinition(
    chave: 'andarilho',
    nome: 'Andarilho',
    descricao: 'Acumule 500 km na missão diária.',
    icone: 'directions_run',
    requisito: '500 km acumulados na missão diária',
    categoria: 'Missão diária',
    xp: 200,
  ),
  AchievementDefinition(
    chave: 'versatil',
    nome: 'Versátil',
    descricao: 'Registre as 7 modalidades de atividade.',
    icone: 'explore',
    requisito: 'As 7 modalidades registradas',
    categoria: 'Atividades',
    xp: 100,
  ),
  AchievementDefinition(
    chave: 'fundista',
    nome: 'Fundista',
    descricao: 'Acumule 100 km em Corrida/Caminhada.',
    icone: 'directions_run',
    requisito: '100 km em Corrida/Caminhada',
    categoria: 'Atividades',
    xp: 100,
  ),
  AchievementDefinition(
    chave: 'lutador',
    nome: 'Lutador',
    descricao: 'Registre 50 sessões de luta.',
    icone: 'sports_mma',
    requisito: '50 sessões de Muay Thai/Boxe e Jiu Jitsu',
    categoria: 'Atividades',
    xp: 200,
  ),
  AchievementDefinition(
    chave: 'rank_d',
    nome: 'Rank D',
    descricao: 'Passe no exame de rank e alcance o Rank D.',
    icone: 'military_tech',
    requisito: 'Exame de rank aprovado: Rank D ou superior',
    categoria: 'Rank',
    xp: 100,
  ),
  AchievementDefinition(
    chave: 'rank_c',
    nome: 'Rank C',
    descricao: 'Passe no exame de rank e alcance o Rank C.',
    icone: 'military_tech',
    requisito: 'Exame de rank aprovado: Rank C ou superior',
    categoria: 'Rank',
    xp: 150,
  ),
  AchievementDefinition(
    chave: 'rank_b',
    nome: 'Rank B',
    descricao: 'Passe no exame de rank e alcance o Rank B.',
    icone: 'military_tech',
    requisito: 'Exame de rank aprovado: Rank B ou superior',
    categoria: 'Rank',
    xp: 200,
  ),
  AchievementDefinition(
    chave: 'rank_a',
    nome: 'Rank A',
    descricao: 'Passe no exame de rank e alcance o Rank A.',
    icone: 'military_tech',
    requisito: 'Exame de rank aprovado: Rank A ou superior',
    categoria: 'Rank',
    xp: 250,
  ),
  AchievementDefinition(
    chave: 'monarca',
    nome: 'Monarca',
    descricao: 'Passe no exame de rank e alcance o Rank S.',
    icone: 'military_tech',
    requisito: 'Exame de rank aprovado: Rank S',
    categoria: 'Rank',
    xp: 300,
  ),
  AchievementDefinition(
    chave: 'mes_limpo',
    nome: 'Mês Limpo',
    descricao: 'Passe um mês inteiro sem falhar na missão diária.',
    icone: 'event_available',
    requisito: 'Um mês completo sem penalidade',
    categoria: 'Disciplina',
    xp: 100,
  ),
  AchievementDefinition(
    chave: 'primeira_avaliacao',
    nome: 'Primeira Avaliação',
    descricao: 'Faça seu primeiro registro corporal.',
    icone: 'monitor_weight',
    requisito: '1 registro corporal',
    categoria: 'Corpo',
    xp: 50,
  ),
  AchievementDefinition(
    chave: 'acompanhamento',
    nome: 'Acompanhamento',
    descricao: 'Registre o corpo em 6 meses seguidos.',
    icone: 'monitor_weight',
    requisito: 'Pelo menos 1 registro por mês, 6 meses seguidos',
    categoria: 'Corpo',
    xp: 100,
  ),
];

/// Ordem dos grupos na tela de Conquistas.
const kAchievementCategories = [
  'Treino',
  'Força',
  'Missão diária',
  'Atividades',
  'Rank',
  'Disciplina',
  'Corpo',
];

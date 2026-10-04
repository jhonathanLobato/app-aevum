enum MissionType { diaria, semanal, desafio }

enum MissionStatus { ativa, concluida, expirada }

class Mission {
  const Mission({
    required this.id,
    required this.tipo,
    required this.nome,
    required this.descricao,
    required this.recompensaXp,
    required this.progresso,
    required this.objetivo,
    required this.status,
    required this.criadoEm,
    this.exerciseId,
    this.minimumRank,
  });

  final int id;
  final MissionType tipo;
  final String nome;
  final String descricao;
  final int recompensaXp;
  final int progresso;
  final int objetivo;
  final MissionStatus status;
  final DateTime criadoEm;

  /// Exercício alvo, só preenchido para missões do tipo [MissionType.desafio].
  final int? exerciseId;

  /// Rank mínimo pra desbloquear a missão (ex.: `'D'`) — seção 8 da Fase 7.
  ///
  /// A tabela `Missions` do Drift ainda não tem essa coluna (adicioná-la
  /// exigiria uma migration, não autorizada nesta fase), então nenhuma
  /// missão real tem isso preenchido hoje: [DriftMissionRepository] sempre
  /// mapeia este campo como `null`. Ele existe aqui pra permitir que a
  /// interface e a lógica de bloqueio já estejam prontas — bastará
  /// adicionar a coluna e passar a repassá-la em `_toDomain` quando a
  /// migration for decidida. Ver relatório da Fase 7, seção 11.
  final String? minimumRank;

  double get progressoFracao {
    if (objetivo == 0) return 0;
    final fracao = progresso / objetivo;
    return fracao.clamp(0, 1).toDouble();
  }
}

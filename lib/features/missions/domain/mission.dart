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

  double get progressoFracao {
    if (objetivo == 0) return 0;
    final fracao = progresso / objetivo;
    return fracao.clamp(0, 1).toDouble();
  }
}

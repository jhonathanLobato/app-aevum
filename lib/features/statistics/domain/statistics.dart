class GlobalStatistics {
  const GlobalStatistics({
    required this.treinosRealizados,
    required this.tempoTotalTreinando,
    required this.exerciciosRealizados,
    required this.totalPRs,
    required this.volumeTotal,
    required this.totalRepeticoes,
    required this.xpAcumulado,
    required this.nivelAtual,
    required this.maiorSequenciaDias,
  });

  final int treinosRealizados;
  final Duration tempoTotalTreinando;
  final int exerciciosRealizados;
  final int totalPRs;
  final double volumeTotal;

  /// Soma de todas as repetições já registradas (usado por
  /// [PlayerAttributesCalculator] pra Resistência). Mesma agregação SQL que
  /// já calculava [volumeTotal], só mais uma coluna somada — sem query nova.
  final int totalRepeticoes;

  final int xpAcumulado;
  final int nivelAtual;

  /// Maior nº de dias seguidos com pelo menos um treino concluído. Ainda não
  /// diferencia descanso programado de treino não realizado (seção 12) — por
  /// enquanto é uma contagem simples de dias consecutivos com treino.
  final int maiorSequenciaDias;
}

class ExerciseStatistics {
  const ExerciseStatistics({
    required this.exerciseId,
    required this.exerciseNome,
    required this.maiorCarga,
    required this.maiorRepeticao,
    required this.maiorVolume,
    required this.treinosRealizados,
    required this.primeiroRegistro,
    required this.ultimoRegistro,
  });

  final int exerciseId;
  final String exerciseNome;
  final double maiorCarga;
  final int maiorRepeticao;
  final double maiorVolume;
  final int treinosRealizados;
  final DateTime primeiroRegistro;
  final DateTime ultimoRegistro;
}

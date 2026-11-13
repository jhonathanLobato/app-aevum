import '../../achievements/domain/achievement.dart';
import '../../missions/domain/mission.dart';
import '../../profile/domain/user_profile.dart';
import '../../progression/domain/personal_record.dart';

enum WorkoutSessionStatus { emAndamento, concluido, cancelado }

class SetEntryRecord {
  const SetEntryRecord({
    required this.id,
    required this.exerciseId,
    required this.exerciseNome,
    required this.serie,
    required this.repeticoes,
    required this.carga,
    required this.volume,
    required this.data,
  });

  final int id;
  final int exerciseId;
  final String exerciseNome;
  final int serie;
  final int repeticoes;
  final double carga;
  final double volume;
  final DateTime data;
}

/// Resumo leve da sessão em andamento (cartão "Treino em andamento").
class ActiveWorkoutInfo {
  const ActiveWorkoutInfo({
    required this.id,
    required this.templateId,
    required this.nome,
    required this.data,
    required this.totalSeries,
  });

  final int id;
  final int? templateId;
  final String nome;
  final DateTime data;
  final int totalSeries;
}

class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.templateId,
    required this.nome,
    required this.data,
    required this.duracaoSegundos,
    required this.status,
    required this.series,
  });

  final int id;
  final int? templateId;
  final String nome;
  final DateTime data;
  final int? duracaoSegundos;
  final WorkoutSessionStatus status;
  final List<SetEntryRecord> series;

  List<SetEntryRecord> seriesDoExercicio(int exerciseId) {
    return series.where((s) => s.exerciseId == exerciseId).toList();
  }
}

class WorkoutSessionSummary {
  const WorkoutSessionSummary({
    required this.id,
    required this.nome,
    required this.data,
    required this.duracaoSegundos,
    required this.totalSeries,
    required this.volumeTotal,
  });

  final int id;
  final String nome;
  final DateTime data;
  final int? duracaoSegundos;
  final int totalSeries;
  final double volumeTotal;
}

class SetLogResult {
  const SetLogResult({
    required this.setEntryId,
    required this.prsBatidos,
    this.xpGanho,
    this.desafioConcluido,
    this.conquistasDesbloqueadas = const [],
  });

  final int setEntryId;
  final List<PersonalRecordBreak> prsBatidos;

  /// `null` quando nenhum PR foi batido nesta série (nenhum XP é concedido
  /// pela série em si, só por recordes, desafios e pela conclusão do treino).
  final XpGainResult? xpGanho;

  /// Desafio de carga concluído por esta série, se algum.
  final Mission? desafioConcluido;

  final List<Achievement> conquistasDesbloqueadas;
}

class FinishResult {
  const FinishResult({
    required this.xpGanho,
    required this.missoesConcluidas,
    this.conquistasDesbloqueadas = const [],
  });

  final XpGainResult xpGanho;
  final List<Mission> missoesConcluidas;
  final List<Achievement> conquistasDesbloqueadas;
}

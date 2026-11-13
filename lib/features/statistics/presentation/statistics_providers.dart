import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/database_provider.dart';
import '../data/statistics_repository_impl.dart';
import '../domain/player_attributes_calculator.dart';
import '../domain/statistics.dart';
import '../domain/statistics_repository.dart';
import '../domain/weekly_report.dart';

final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  return DriftStatisticsRepository(ref.watch(appDatabaseProvider));
});

final globalStatisticsProvider = StreamProvider<GlobalStatistics>((ref) {
  return ref.watch(statisticsRepositoryProvider).watchGlobal();
});

final exerciseStatisticsProvider =
    StreamProvider<List<ExerciseStatistics>>((ref) {
  return ref.watch(statisticsRepositoryProvider).watchPerExercise();
});

/// Atributos derivados — recalculados sempre que as estatísticas
/// globais mudam, reaproveitando o mesmo stream (`.select`/cache natural
/// do Riverpod evita recomputar a agregação em si, só a fórmula pura).
final weeklyReportsProvider = StreamProvider<List<WeeklyReport>>((ref) {
  return ref.watch(statisticsRepositoryProvider).watchWeeklyReports();
});

final playerAttributesProvider = Provider<AsyncValue<PlayerAttributes>>((ref) {
  return ref
      .watch(globalStatisticsProvider)
      .whenData((stats) => const PlayerAttributesCalculator().calcular(stats));
});

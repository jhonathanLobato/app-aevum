import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/database_provider.dart';
import '../data/statistics_repository_impl.dart';
import '../domain/statistics.dart';
import '../domain/statistics_repository.dart';

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

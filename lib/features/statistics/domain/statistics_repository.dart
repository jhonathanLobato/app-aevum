import 'statistics.dart';

abstract class StatisticsRepository {
  Stream<GlobalStatistics> watchGlobal();

  Stream<List<ExerciseStatistics>> watchPerExercise();
}

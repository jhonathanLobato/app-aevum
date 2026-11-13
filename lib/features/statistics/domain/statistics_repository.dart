import 'statistics.dart';
import 'weekly_report.dart';

abstract class StatisticsRepository {
  Stream<GlobalStatistics> watchGlobal();

  Stream<List<ExerciseStatistics>> watchPerExercise();

  /// Relatórios semanais, do mais recente (a semana atual, sempre presente)
  /// ao mais antigo; semanas sem nenhum registro ficam de fora.
  Stream<List<WeeklyReport>> watchWeeklyReports();
}

import 'workout_template.dart';

abstract class WorkoutTemplateRepository {
  Stream<List<WorkoutTemplate>> watchAll();

  Future<int> create(String nome);

  Future<void> rename(int id, String nome);

  Future<void> delete(int id);

  Future<void> addExercise(
    int templateId,
    int exerciseId, {
    int? seriesAlvo,
    int? repeticoesAlvo,
  });

  Future<void> removeExercise(int templateExerciseId);

  /// Recebe os ids de [WorkoutTemplateExerciseItem.templateExerciseId] na nova ordem desejada.
  Future<void> reorderExercises(
      int templateId, List<int> orderedTemplateExerciseIds);
}

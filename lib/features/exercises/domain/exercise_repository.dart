import 'exercise.dart';

abstract class ExerciseRepository {
  Stream<List<Exercise>> watchAll();

  Future<int> create({required String nome, required String grupoMuscular});

  Future<void> update(int id,
      {required String nome, required String grupoMuscular});

  Future<void> delete(int id);
}

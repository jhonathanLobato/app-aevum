import 'exercise.dart';

abstract class ExerciseRepository {
  Stream<List<Exercise>> watchAll();

  Future<int> create({required String nome, required String grupoMuscular});

  Future<void> update(int id,
      {required String nome, required String grupoMuscular});

  /// `true` se o exercício é referenciado por treinos, séries registradas,
  /// recordes (PRs), desafios ou rascunhos — nesse caso não pode ser excluído.
  Future<bool> isInUse(int id);

  /// Exclui o exercício. Lança [ExerciseInUseException] se ele estiver em uso.
  Future<void> delete(int id);
}

class ExerciseInUseException implements Exception {
  const ExerciseInUseException();

  @override
  String toString() => 'ExerciseInUseException';
}

import 'package:drift/drift.dart';

import '../../../database/app_database.dart' hide Exercise;
import '../domain/exercise.dart';
import '../domain/exercise_repository.dart';

class DriftExerciseRepository implements ExerciseRepository {
  DriftExerciseRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Exercise>> watchAll() {
    return (_db.select(_db.exercises)
          ..orderBy([(e) => OrderingTerm(expression: e.nome)]))
        .watch()
        .map((rows) => rows
            .map((row) => Exercise(
                  id: row.id,
                  nome: row.nome,
                  grupoMuscular: row.grupoMuscular,
                ))
            .toList());
  }

  @override
  Future<int> create({required String nome, required String grupoMuscular}) {
    return _db.into(_db.exercises).insert(
          ExercisesCompanion.insert(nome: nome, grupoMuscular: grupoMuscular),
        );
  }

  @override
  Future<void> update(int id,
      {required String nome, required String grupoMuscular}) {
    return (_db.update(_db.exercises)..where((e) => e.id.equals(id))).write(
      ExercisesCompanion(
        nome: Value(nome),
        grupoMuscular: Value(grupoMuscular),
      ),
    );
  }

  @override
  Future<void> delete(int id) {
    return (_db.delete(_db.exercises)..where((e) => e.id.equals(id))).go();
  }
}

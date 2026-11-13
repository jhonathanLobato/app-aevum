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
  Future<bool> isInUse(int id) async {
    Future<bool> existe<T extends HasResultSet, D>(
      ResultSetImplementation<T, D> tabela,
      Expression<int> coluna,
    ) async {
      final contagem = coluna.count();
      final linha = await (_db.selectOnly(tabela)
            ..addColumns([contagem])
            ..where(coluna.equals(id)))
          .getSingle();
      return (linha.read(contagem) ?? 0) > 0;
    }

    return await existe(_db.workoutTemplateExercises,
            _db.workoutTemplateExercises.exerciseId) ||
        await existe(_db.setEntries, _db.setEntries.exerciseId) ||
        await existe(_db.personalRecords, _db.personalRecords.exerciseId) ||
        await existe(_db.missions, _db.missions.exerciseId) ||
        await existe(_db.finishedExercises, _db.finishedExercises.exerciseId) ||
        await existe(_db.setDrafts, _db.setDrafts.exerciseId);
  }

  @override
  Future<void> delete(int id) {
    return _db.transaction(() async {
      if (await isInUse(id)) throw const ExerciseInUseException();
      await (_db.delete(_db.exercises)..where((e) => e.id.equals(id))).go();
    });
  }
}

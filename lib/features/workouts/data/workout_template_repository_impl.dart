import 'package:drift/drift.dart';

import '../../../database/app_database.dart' hide WorkoutTemplate;
import '../domain/workout_template.dart';
import '../domain/workout_template_repository.dart';

class DriftWorkoutTemplateRepository implements WorkoutTemplateRepository {
  DriftWorkoutTemplateRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<WorkoutTemplate>> watchAll() {
    final query = _db.select(_db.workoutTemplates).join([
      leftOuterJoin(
        _db.workoutTemplateExercises,
        _db.workoutTemplateExercises.templateId
            .equalsExp(_db.workoutTemplates.id),
      ),
      leftOuterJoin(
        _db.exercises,
        _db.exercises.id.equalsExp(_db.workoutTemplateExercises.exerciseId),
      ),
    ])
      ..orderBy([
        OrderingTerm(
          expression: _db.workoutTemplates.criadoEm,
          mode: OrderingMode.desc,
        ),
        OrderingTerm(expression: _db.workoutTemplateExercises.ordem),
      ]);

    return query.watch().map(_groupRows);
  }

  List<WorkoutTemplate> _groupRows(List<TypedResult> rows) {
    final byId = <int, WorkoutTemplate>{};
    final order = <int>[];

    for (final row in rows) {
      final template = row.readTable(_db.workoutTemplates);
      final templateExercise =
          row.readTableOrNull(_db.workoutTemplateExercises);
      final exercise = row.readTableOrNull(_db.exercises);

      var current = byId[template.id];
      if (current == null) {
        current = WorkoutTemplate(
          id: template.id,
          nome: template.nome,
          criadoEm: template.criadoEm,
          exercicios: [],
        );
        byId[template.id] = current;
        order.add(template.id);
      }

      if (templateExercise != null && exercise != null) {
        current.exercicios.add(
          WorkoutTemplateExerciseItem(
            templateExerciseId: templateExercise.id,
            exerciseId: exercise.id,
            exerciseNome: exercise.nome,
            grupoMuscular: exercise.grupoMuscular,
            ordem: templateExercise.ordem,
            seriesAlvo: templateExercise.seriesAlvo,
            repeticoesAlvo: templateExercise.repeticoesAlvo,
          ),
        );
      }
    }

    return order.map((id) => byId[id]!).toList();
  }

  @override
  Future<int> create(String nome) {
    return _db.into(_db.workoutTemplates).insert(
          WorkoutTemplatesCompanion.insert(nome: nome),
        );
  }

  @override
  Future<void> rename(int id, String nome) {
    return (_db.update(_db.workoutTemplates)..where((t) => t.id.equals(id)))
        .write(WorkoutTemplatesCompanion(nome: Value(nome)));
  }

  @override
  Future<void> delete(int id) {
    return (_db.delete(_db.workoutTemplates)..where((t) => t.id.equals(id)))
        .go();
  }

  @override
  Future<void> addExercise(
    int templateId,
    int exerciseId, {
    int? seriesAlvo,
    int? repeticoesAlvo,
  }) {
    return _db.transaction(() async {
      final maiorOrdem = await (_db.selectOnly(_db.workoutTemplateExercises)
            ..addColumns([_db.workoutTemplateExercises.ordem.max()])
            ..where(_db.workoutTemplateExercises.templateId.equals(templateId)))
          .map((row) => row.read(_db.workoutTemplateExercises.ordem.max()))
          .getSingleOrNull();

      await _db.into(_db.workoutTemplateExercises).insert(
            WorkoutTemplateExercisesCompanion.insert(
              templateId: templateId,
              exerciseId: exerciseId,
              ordem: (maiorOrdem ?? -1) + 1,
              seriesAlvo: Value(seriesAlvo),
              repeticoesAlvo: Value(repeticoesAlvo),
            ),
          );
    });
  }

  @override
  Future<void> removeExercise(int templateExerciseId) {
    return (_db.delete(_db.workoutTemplateExercises)
          ..where((e) => e.id.equals(templateExerciseId)))
        .go();
  }

  @override
  Future<void> reorderExercises(
    int templateId,
    List<int> orderedTemplateExerciseIds,
  ) {
    return _db.transaction(() async {
      for (var i = 0; i < orderedTemplateExerciseIds.length; i++) {
        await (_db.update(_db.workoutTemplateExercises)
              ..where((e) => e.id.equals(orderedTemplateExerciseIds[i])))
            .write(WorkoutTemplateExercisesCompanion(ordem: Value(i)));
      }
    });
  }
}

import 'package:drift/drift.dart';

import '../../../exercises/data/tables/exercise_table.dart';
import 'workout_session_table.dart';

/// Exercícios que o usuário marcou como finalizados dentro de uma sessão.
/// A existência da linha = exercício finalizado; "retornar ao exercício"
/// apaga a linha. Persistido para sobreviver ao fechamento do app.
@DataClassName('FinishedExerciseRow')
class FinishedExercises extends Table {
  IntColumn get sessionId =>
      integer().references(WorkoutSessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();

  @override
  Set<Column> get primaryKey => {sessionId, exerciseId};
}

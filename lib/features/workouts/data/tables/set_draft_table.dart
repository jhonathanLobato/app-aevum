import 'package:drift/drift.dart';

import '../../../exercises/data/tables/exercise_table.dart';
import 'workout_session_table.dart';

/// Carga/repetições digitadas e ainda não registradas, por sessão e
/// exercício. Guardados como texto (exatamente o que está nos campos) para
/// restaurar a digitação ao reabrir o treino depois de fechar o app.
@DataClassName('SetDraftRow')
class SetDrafts extends Table {
  IntColumn get sessionId =>
      integer().references(WorkoutSessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  TextColumn get carga => text().withDefault(const Constant(''))();
  TextColumn get reps => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {sessionId, exerciseId};
}

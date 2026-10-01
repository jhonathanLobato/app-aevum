import 'package:drift/drift.dart';

import '../../../exercises/data/tables/exercise_table.dart';
import 'workout_session_table.dart';

/// Registro de uma série realizada dentro de uma sessão de treino.
class SetEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId =>
      integer().references(WorkoutSessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get serie => integer()();
  IntColumn get repeticoes => integer()();
  RealColumn get carga => real()();
  RealColumn get volume => real()();
  DateTimeColumn get data => dateTime().withDefault(currentDateAndTime)();
  TextColumn get observacoes => text().nullable()();
}

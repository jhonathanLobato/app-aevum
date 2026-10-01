import 'package:drift/drift.dart';

/// Um treino cadastrado pelo usuário (ex: "TREINO A"), reutilizado em várias sessões.
class WorkoutTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nome => text()();
  DateTimeColumn get criadoEm => dateTime().withDefault(currentDateAndTime)();
}

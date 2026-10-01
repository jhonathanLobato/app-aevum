import 'package:drift/drift.dart';

import '../../domain/workout_session.dart';
import 'workout_template_table.dart';

/// Uma execução real de um treino em uma data específica.
class WorkoutSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get templateId =>
      integer().nullable().references(WorkoutTemplates, #id)();
  TextColumn get nome => text()();
  DateTimeColumn get data => dateTime().withDefault(currentDateAndTime)();
  IntColumn get duracaoSegundos => integer().nullable()();
  TextColumn get status => textEnum<WorkoutSessionStatus>()();
}

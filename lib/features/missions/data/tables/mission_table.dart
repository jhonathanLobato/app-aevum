import 'package:drift/drift.dart';

import '../../../exercises/data/tables/exercise_table.dart';
import '../../domain/mission.dart';

class Missions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get tipo => textEnum<MissionType>()();
  TextColumn get nome => text()();
  TextColumn get descricao => text()();
  IntColumn get recompensaXp => integer()();
  IntColumn get progresso => integer().withDefault(const Constant(0))();
  IntColumn get objetivo => integer()();
  TextColumn get status => textEnum<MissionStatus>()
      .withDefault(Constant(MissionStatus.ativa.name))();
  DateTimeColumn get criadoEm => dateTime().withDefault(currentDateAndTime)();
  IntColumn get exerciseId => integer().nullable().references(Exercises, #id)();
}

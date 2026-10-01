import 'package:drift/drift.dart';

import '../../../exercises/data/tables/exercise_table.dart';
import '../../domain/personal_record.dart';

/// Recorde pessoal detectado para um exercício (carga, repetições ou volume).
class PersonalRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  TextColumn get tipo => textEnum<PersonalRecordType>()();
  RealColumn get valor => real()();
  DateTimeColumn get data => dateTime().withDefault(currentDateAndTime)();
}

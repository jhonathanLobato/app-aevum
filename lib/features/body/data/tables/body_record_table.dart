import 'package:drift/drift.dart';

/// Registro corporal com data. Tudo opcional (a regra "ao menos um valor" é
/// do repositório). Peso em kg, medidas em cm, gordura em %.
@DataClassName('BodyRecordRow')
class BodyRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get data => dateTime()();
  RealColumn get pesoKg => real().nullable()();
  RealColumn get gorduraPct => real().nullable()();
  RealColumn get bracoCm => real().nullable()();
  RealColumn get peitoCm => real().nullable()();
  RealColumn get cinturaCm => real().nullable()();
  RealColumn get quadrilCm => real().nullable()();
  RealColumn get coxaCm => real().nullable()();
  RealColumn get panturrilhaCm => real().nullable()();
}

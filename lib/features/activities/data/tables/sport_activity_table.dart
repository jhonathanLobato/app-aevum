import 'package:drift/drift.dart';

import '../../domain/sport_activity.dart';

/// Registros esportivos manuais (Atividades). Tabela independente de
/// musculação: sem relação com sessões/exercícios/XP.
@DataClassName('SportActivityRow')
class SportActivities extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get tipo => textEnum<SportType>()();
  DateTimeColumn get data => dateTime()();
  IntColumn get duracaoMinutos => integer()();
  RealColumn get distanciaKm => real().nullable()();
  IntColumn get rounds => integer().nullable()();
  TextColumn get observacoes => text().nullable()();

  /// XP concedido por este registro (0 ou 30), ver `ActivityXp`.
  IntColumn get xpConcedido => integer().withDefault(const Constant(0))();
  DateTimeColumn get criadoEm => dateTime().withDefault(currentDateAndTime)();
}

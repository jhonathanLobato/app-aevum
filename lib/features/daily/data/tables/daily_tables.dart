import 'package:drift/drift.dart';

import '../../domain/daily_values.dart';

/// Dias da semana (1=segunda … 7=domingo) marcados como dia de treino.
/// A presença da linha significa "treino"; ausência, "descanso".
class ScheduleDays extends Table {
  IntColumn get weekday => integer()();

  @override
  Set<Column> get primaryKey => {weekday};
}

/// Registros da missão diária (flexões, abdominais, km), somados por dia.
/// Totalmente separados dos treinos de academia e das atividades.
class DailyEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get dia => text()();
  TextColumn get parte => textEnum<DailyPart>()();
  RealColumn get valor => real()();
  DateTimeColumn get criadoEm => dateTime().withDefault(currentDateAndTime)();
}

/// Estado de cada dia: folga, missão concluída, penalidade aplicada.
class DailyDays extends Table {
  TextColumn get dia => text()();
  BoolColumn get folga => boolean().withDefault(const Constant(false))();
  BoolColumn get concluida => boolean().withDefault(const Constant(false))();

  /// Dia já avaliado pela virada (penalidade decidida).
  BoolColumn get processado => boolean().withDefault(const Constant(false))();
  IntColumn get penalidadeXp => integer().withDefault(const Constant(0))();

  /// `false` enquanto a penalidade ainda não foi mostrada ao usuário.
  BoolColumn get avisado => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {dia};
}

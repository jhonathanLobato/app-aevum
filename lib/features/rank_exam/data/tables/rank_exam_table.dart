import 'package:drift/drift.dart';

enum RankExamStatus { ativo, aprovado }

/// Exame para subir de rank. Há no máximo um ativo por vez.
class RankExams extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get rankAlvo => text()();
  DateTimeColumn get inicio => dateTime()();
  IntColumn get prazoDias => integer()();

  /// Modalidades escolhidas (nomes de `SportType`, separados por vírgula).
  TextColumn get modalidades => text().withDefault(const Constant(''))();
  TextColumn get status => textEnum<RankExamStatus>()
      .withDefault(Constant(RankExamStatus.ativo.name))();
  IntColumn get reinicios => integer().withDefault(const Constant(0))();
}

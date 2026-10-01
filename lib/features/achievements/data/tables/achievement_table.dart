import 'package:drift/drift.dart';

import '../../domain/achievement.dart';

class Achievements extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get chave => text().unique()();
  TextColumn get nome => text()();
  TextColumn get descricao => text()();
  TextColumn get icone => text().nullable()();
  TextColumn get requisito => text()();
  TextColumn get status => textEnum<AchievementStatus>()
      .withDefault(Constant(AchievementStatus.bloqueada.name))();
  DateTimeColumn get dataDesbloqueio => dateTime().nullable()();
}

import 'package:drift/drift.dart';

import '../../domain/app_theme.dart';
import '../../domain/player_class.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nome => text()();
  TextColumn get avatar => text().nullable()();
  TextColumn get classe => textEnum<PlayerClass>()();
  TextColumn get titulo => text().nullable()();
  TextColumn get tema =>
      textEnum<AppTheme>().withDefault(Constant(AppTheme.escuro.name))();
  IntColumn get xp => integer().withDefault(const Constant(0))();
  IntColumn get nivel => integer().withDefault(const Constant(1))();
  TextColumn get rank => text().withDefault(const Constant('F'))();
}

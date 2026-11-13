import 'package:drift/drift.dart';

import '../../domain/app_theme.dart';
import '../../domain/player_class.dart';
import '../../domain/units.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nome => text()();
  TextColumn get avatar => text().nullable()();
  TextColumn get classe => textEnum<PlayerClass>()();

  /// Nome do título escolhido (ver `kTitleCatalog`); padrão "Despertado".
  TextColumn get titulo => text().nullable()();
  TextColumn get tema =>
      textEnum<AppTheme>().withDefault(Constant(AppTheme.escuro.name))();
  IntColumn get xp => integer().withDefault(const Constant(0))();
  IntColumn get nivel => integer().withDefault(const Constant(1))();
  TextColumn get rank => text().withDefault(const Constant('F'))();

  /// Quando o jogador entrou no rank atual (a experiência de caçador conta
  /// a partir daqui e zera ao subir de rank).
  DateTimeColumn get rankDesde => dateTime().nullable()();

  /// Corpo (opcionais). Altura sempre em cm.
  RealColumn get alturaCm => real().nullable()();
  DateTimeColumn get nascimento => dateTime().nullable()();
  TextColumn get sexo => textEnum<Sexo>().nullable()();

  /// Unidades de exibição; o banco guarda kg e cm.
  TextColumn get unidadePeso =>
      textEnum<WeightUnit>().withDefault(Constant(WeightUnit.kg.name))();
  TextColumn get unidadeComprimento =>
      textEnum<LengthUnit>().withDefault(Constant(LengthUnit.cm.name))();

  /// Criação do usuário (base da Data do Despertar).
  DateTimeColumn get criadoEm => dateTime().nullable()();
}

import 'package:drift/drift.dart';

/// `disponivel`: exame liberado, mas ainda não iniciado (o usuário tem 7 dias
/// para iniciar; depois ele começa sozinho). `ativo`: prazo correndo.
enum RankExamStatus { disponivel, ativo, aprovado }

/// Exame para subir de rank. Há no máximo um ativo por vez.
class RankExams extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get rankAlvo => text()();

  /// Enquanto `disponivel`, é a data de liberação (início da janela de 7
  /// dias); ao iniciar, vira o início do prazo do exame.
  DateTimeColumn get inicio => dateTime()();
  IntColumn get prazoDias => integer()();

  /// Modalidades escolhidas (nomes de `SportType`, separados por vírgula).
  TextColumn get modalidades => text().withDefault(const Constant(''))();
  TextColumn get status => textEnum<RankExamStatus>()
      .withDefault(Constant(RankExamStatus.ativo.name))();
  IntColumn get reinicios => integer().withDefault(const Constant(0))();

  /// `false` enquanto o overlay de RANK UP de um exame aprovado ainda não foi
  /// exibido (app fechado na hora): aparece na próxima abertura.
  BoolColumn get visto => boolean().withDefault(const Constant(true))();
}

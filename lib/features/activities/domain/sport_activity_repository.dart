import 'sport_activity.dart';

abstract class SportActivityRepository {
  /// Todos os registros esportivos, do mais recente pro mais antigo. Pensado
  /// pra Fase 2 (histórico geral unificado por data).
  Stream<List<SportActivity>> watchAll();

  /// Registros de UMA modalidade, do mais recente pro mais antigo. [limite]
  /// restringe a quantidade (a tela da modalidade mostra só os 3 últimos).
  Stream<List<SportActivity>> watchByType(SportType tipo, {int? limite});

  Stream<SportActivity?> watchById(int id);

  /// Lança [SportActivityValidationException] se os dados forem inválidos.
  Future<int> create(SportActivityInput input);

  Future<void> update(int id, SportActivityInput input);

  Future<void> delete(int id);
}

import 'mission.dart';

abstract class MissionRepository {
  Stream<List<Mission>> watchActive();

  /// Garante que existe uma missão diária e uma semanal ativas para o
  /// período atual (hoje / esta semana), criando-as se necessário e
  /// expirando as de períodos anteriores que não foram concluídas.
  Future<void> ensureRecurringMissions();

  /// Chamado quando um treino é finalizado: avança a missão diária e a
  /// semanal. Retorna as que foram concluídas nesta chamada.
  Future<List<Mission>> registrarTreinoConcluido();

  /// Chamado quando um novo recorde de carga é batido: conclui o desafio
  /// ativo daquele exercício (se o valor atingiu a meta) e garante que
  /// existe um próximo desafio. Retorna o desafio concluído, se houver.
  Future<Mission?> registrarNovoRecordeDeCarga({
    required int exerciseId,
    required String exerciseNome,
    required double novoRecorde,
  });
}

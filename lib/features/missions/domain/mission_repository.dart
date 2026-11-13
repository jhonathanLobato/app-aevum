import 'mission.dart';

abstract class MissionRepository {
  Stream<List<Mission>> watchActive();

  /// Missões concluídas nesta semana (inclui a diária/semanal mais
  /// recentes se já tiverem sido concluídas) — pra tela de Missões poder
  /// mostrar brevemente o estado "concluída" antes de saírem de
  /// [watchActive], que só retorna o que ainda está ativo.
  Stream<List<Mission>> watchRecentHistory();

  /// Garante a missão semanal desta semana, alinhada à programação semanal
  /// (objetivo = nº de dias de treino programados; sem programação não há
  /// missão semanal). Expira a de semanas anteriores não concluída.
  Future<void> ensureRecurringMissions();

  /// Chamado quando um treino de academia é finalizado: avança a missão
  /// semanal (tudo ou nada). Retorna as concluídas nesta chamada.
  Future<List<Mission>> registrarTreinoConcluido();

  /// Chamado quando um novo recorde de carga é batido: conclui o desafio
  /// ativo daquele exercício (se o valor atingiu a meta) e garante que
  /// existe um próximo desafio. Retorna o desafio concluído, se houver.
  Future<Mission?> registrarNovoRecordeDeCarga({
    required int exerciseId,
    required String exerciseNome,
    required double novoRecorde,
    bool criarProximo = true,
  });
}

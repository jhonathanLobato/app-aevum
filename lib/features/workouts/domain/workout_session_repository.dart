import 'workout_session.dart';

abstract class WorkoutSessionRepository {
  Future<int> start({int? templateId, required String nome});

  Stream<WorkoutSession?> watchSession(int sessionId);

  /// Registra a série e detecta automaticamente novos recordes pessoais
  /// para o exercício (ver [SetLogResult.prsBatidos]).
  Future<SetLogResult> logSet({
    required int sessionId,
    required int exerciseId,
    required int repeticoes,
    required double carga,
    String? observacoes,
  });

  Future<void> removeSet(int setEntryId);

  /// Finaliza a sessão, concede o XP de conclusão de treino e avança as
  /// missões diária/semanal. Retorna `null` se a sessão já não estava mais
  /// em andamento (chamada repetida não deve conceder XP de novo).
  ///
  /// Se a sessão foi reaberta por [reopen] (já tinha sido finalizada antes),
  /// finalizar de novo só atualiza status/duração — não concede XP nem
  /// avança missões/conquistas de novo — e também retorna `null`.
  Future<FinishResult?> finish(int sessionId, {required Duration duracao});

  /// Volta uma sessão finalizada para "em andamento" (botão "Retornar
  /// treino"), pra permitir registrar mais séries. A duração já gravada é
  /// mantida — é ela que marca que o XP desta sessão já foi concedido.
  Future<void> reopen(int sessionId);

  Future<void> cancel(int sessionId);

  /// Treinos já finalizados, do mais recente para o mais antigo.
  Stream<List<WorkoutSessionSummary>> watchHistory();

  /// Todas as séries já registradas para um exercício, em ordem cronológica.
  Stream<List<SetEntryRecord>> watchExerciseHistory(int exerciseId);
}

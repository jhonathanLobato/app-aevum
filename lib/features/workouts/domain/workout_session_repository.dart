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
  Future<FinishResult?> finish(int sessionId, {required Duration duracao});

  /// Marca o exercício como finalizado nesta sessão (persistido). Idempotente.
  Future<void> finishExercise(int sessionId, int exerciseId);

  /// Desfaz [finishExercise]: o exercício volta a aceitar novas séries.
  Future<void> resumeExercise(int sessionId, int exerciseId);

  Future<void> cancel(int sessionId);

  /// Sessão em andamento mais recente (a que o cartão "Treino em andamento"
  /// mostra), ou `null` se não houver nenhuma.
  Stream<ActiveWorkoutInfo?> watchActive();

  Future<ActiveWorkoutInfo?> findActive();

  /// Descarta uma sessão em andamento: apaga as séries dela e marca como
  /// cancelada (some de histórico e estatísticas por exercício). O XP e os
  /// recordes já concedidos durante o treino NÃO são desfeitos.
  Future<void> discard(int sessionId);

  /// Treinos já finalizados, do mais recente para o mais antigo.
  Stream<List<WorkoutSessionSummary>> watchHistory();

  /// Todas as séries já registradas para um exercício, em ordem cronológica.
  Stream<List<SetEntryRecord>> watchExerciseHistory(int exerciseId);
}

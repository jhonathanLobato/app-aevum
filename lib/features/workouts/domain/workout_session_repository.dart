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

  Future<void> cancel(int sessionId);

  /// Treinos já finalizados, do mais recente para o mais antigo.
  Stream<List<WorkoutSessionSummary>> watchHistory();

  /// Todas as séries já registradas para um exercício, em ordem cronológica.
  Stream<List<SetEntryRecord>> watchExerciseHistory(int exerciseId);
}

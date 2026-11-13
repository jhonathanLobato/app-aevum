import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/database_provider.dart';
import '../../achievements/presentation/achievement_providers.dart';
import '../../missions/presentation/mission_providers.dart';
import '../../profile/presentation/profile_providers.dart';
import '../../progression/presentation/personal_record_providers.dart';
import '../data/workout_session_repository_impl.dart';
import '../domain/workout_session.dart';
import '../domain/workout_session_repository.dart';

final workoutSessionRepositoryProvider =
    Provider<WorkoutSessionRepository>((ref) {
  return DriftWorkoutSessionRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(personalRecordRepositoryProvider),
    ref.watch(profileRepositoryProvider),
    ref.watch(missionRepositoryProvider),
    ref.watch(achievementRepositoryProvider),
  );
});

final workoutSessionProvider =
    StreamProvider.family<WorkoutSession?, int>((ref, sessionId) {
  return ref.watch(workoutSessionRepositoryProvider).watchSession(sessionId);
});

final workoutHistoryProvider =
    StreamProvider<List<WorkoutSessionSummary>>((ref) {
  return ref.watch(workoutSessionRepositoryProvider).watchHistory();
});

/// Treino em andamento (se houver) — alimenta o cartão "Treino em andamento".
final activeWorkoutProvider = StreamProvider<ActiveWorkoutInfo?>((ref) {
  return ref.watch(workoutSessionRepositoryProvider).watchActive();
});

/// Cargas/repetições digitadas e ainda não registradas, por sessão/exercício.
/// Vive enquanto o app está aberto: sair da tela do treino não apaga o que
/// estava digitado (não é persistido em disco).
final workoutDraftsProvider = Provider<WorkoutDrafts>((ref) => WorkoutDrafts());

class WorkoutDrafts {
  final _valores = <String, ({String carga, String reps})>{};

  String _chave(int sessionId, int exerciseId) => '$sessionId:$exerciseId';

  ({String carga, String reps})? ler(int sessionId, int exerciseId) =>
      _valores[_chave(sessionId, exerciseId)];

  void salvar(int sessionId, int exerciseId, String carga, String reps) {
    final chave = _chave(sessionId, exerciseId);
    if (carga.isEmpty && reps.isEmpty) {
      _valores.remove(chave);
    } else {
      _valores[chave] = (carga: carga, reps: reps);
    }
  }

  void limparSessao(int sessionId) {
    _valores.removeWhere((chave, _) => chave.startsWith('$sessionId:'));
  }
}

final exerciseHistoryProvider =
    StreamProvider.family<List<SetEntryRecord>, int>((ref, exerciseId) {
  return ref
      .watch(workoutSessionRepositoryProvider)
      .watchExerciseHistory(exerciseId);
});

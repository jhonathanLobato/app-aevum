import 'dart:async';

import 'package:drift/drift.dart' show BooleanExpressionOperators, Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/app_database.dart'
    show AppDatabase, SetDraftsCompanion;
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
/// Persistidas no banco (tabela `set_drafts`): sobrevivem a fechar o app.
/// A leitura é síncrona a partir de um cache em memória; [carregar] precisa
/// ter sido concluído para a sessão antes de ler (ver [workoutDraftsReadyProvider]).
final workoutDraftsProvider = Provider<WorkoutDrafts>(
    (ref) => WorkoutDrafts(ref.watch(appDatabaseProvider)));

/// Carrega do banco os rascunhos da sessão para o cache.
final workoutDraftsReadyProvider =
    FutureProvider.family<void, int>((ref, sessionId) {
  return ref.read(workoutDraftsProvider).carregar(sessionId);
});

class WorkoutDrafts {
  WorkoutDrafts(this._db);

  final AppDatabase _db;
  final _valores = <String, ({String carga, String reps})>{};
  final _carregadas = <int>{};

  String _chave(int sessionId, int exerciseId) => '$sessionId:$exerciseId';

  Future<void> carregar(int sessionId) async {
    if (_carregadas.contains(sessionId)) return;
    final linhas = await (_db.select(_db.setDrafts)
          ..where((d) => d.sessionId.equals(sessionId)))
        .get();
    for (final linha in linhas) {
      _valores.putIfAbsent(_chave(sessionId, linha.exerciseId),
          () => (carga: linha.carga, reps: linha.reps));
    }
    _carregadas.add(sessionId);
  }

  ({String carga, String reps})? ler(int sessionId, int exerciseId) =>
      _valores[_chave(sessionId, exerciseId)];

  /// Atualiza o cache na hora; o futuro retornado completa quando a gravação
  /// no banco termina (quem não precisa esperar pode ignorá-lo).
  Future<void> salvar(
      int sessionId, int exerciseId, String carga, String reps) {
    final chave = _chave(sessionId, exerciseId);
    if (carga.isEmpty && reps.isEmpty) {
      _valores.remove(chave);
    } else {
      _valores[chave] = (carga: carga, reps: reps);
    }
    return _persistir(sessionId, exerciseId, carga, reps);
  }

  Future<void> _persistir(
      int sessionId, int exerciseId, String carga, String reps) async {
    try {
      if (carga.isEmpty && reps.isEmpty) {
        await (_db.delete(_db.setDrafts)
              ..where((d) =>
                  d.sessionId.equals(sessionId) &
                  d.exerciseId.equals(exerciseId)))
            .go();
      } else {
        await _db.into(_db.setDrafts).insertOnConflictUpdate(
              SetDraftsCompanion.insert(
                sessionId: sessionId,
                exerciseId: exerciseId,
                carga: Value(carga),
                reps: Value(reps),
              ),
            );
      }
    } catch (_) {
      // Rascunho é conveniência: falha de gravação nunca deve quebrar o
      // treino (ex.: sessão apagada ou banco já fechado).
    }
  }

  void limparSessao(int sessionId) {
    _valores.removeWhere((chave, _) => chave.startsWith('$sessionId:'));
    unawaited((_db.delete(_db.setDrafts)
          ..where((d) => d.sessionId.equals(sessionId)))
        .go()
        .then<void>((_) {}, onError: (_) {}));
  }
}

final exerciseHistoryProvider =
    StreamProvider.family<List<SetEntryRecord>, int>((ref, exerciseId) {
  return ref
      .watch(workoutSessionRepositoryProvider)
      .watchExerciseHistory(exerciseId);
});

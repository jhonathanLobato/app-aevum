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

final exerciseHistoryProvider =
    StreamProvider.family<List<SetEntryRecord>, int>((ref, exerciseId) {
  return ref
      .watch(workoutSessionRepositoryProvider)
      .watchExerciseHistory(exerciseId);
});

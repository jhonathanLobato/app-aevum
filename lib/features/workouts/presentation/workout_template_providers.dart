import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/database_provider.dart';
import '../data/workout_template_repository_impl.dart';
import '../domain/workout_template.dart';
import '../domain/workout_template_repository.dart';

final workoutTemplateRepositoryProvider =
    Provider<WorkoutTemplateRepository>((ref) {
  return DriftWorkoutTemplateRepository(ref.watch(appDatabaseProvider));
});

final workoutTemplatesProvider = StreamProvider<List<WorkoutTemplate>>((ref) {
  return ref.watch(workoutTemplateRepositoryProvider).watchAll();
});

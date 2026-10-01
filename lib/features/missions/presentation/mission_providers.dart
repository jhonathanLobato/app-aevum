import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/database_provider.dart';
import '../data/mission_repository_impl.dart';
import '../domain/mission.dart';
import '../domain/mission_repository.dart';

final missionRepositoryProvider = Provider<MissionRepository>((ref) {
  return DriftMissionRepository(ref.watch(appDatabaseProvider));
});

final activeMissionsProvider = StreamProvider<List<Mission>>((ref) {
  final repo = ref.watch(missionRepositoryProvider);
  // Garante que as missões recorrentes existam antes de exibi-las.
  repo.ensureRecurringMissions();
  return repo.watchActive();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/database_provider.dart';
import '../data/achievement_repository_impl.dart';
import '../domain/achievement.dart';
import '../domain/achievement_repository.dart';

final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  return DriftAchievementRepository(ref.watch(appDatabaseProvider));
});

final achievementsProvider = StreamProvider<List<Achievement>>((ref) {
  final repo = ref.watch(achievementRepositoryProvider);
  // Garante que o catálogo fixo exista antes de exibi-lo.
  repo.ensureCatalog();
  return repo.watchAll();
});

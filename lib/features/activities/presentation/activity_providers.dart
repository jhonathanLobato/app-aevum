import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/database_provider.dart';
import '../data/sport_activity_repository_impl.dart';
import '../domain/sport_activity.dart';
import '../domain/sport_activity_repository.dart';

/// Quantos registros recentes a página da modalidade mostra.
const kAtividadesRecentes = 3;

final sportActivityRepositoryProvider =
    Provider<SportActivityRepository>((ref) {
  return DriftSportActivityRepository(ref.watch(appDatabaseProvider));
});

/// Todos os registros esportivos por data (base do histórico geral da Fase 2).
final allSportActivitiesProvider = StreamProvider<List<SportActivity>>((ref) {
  return ref.watch(sportActivityRepositoryProvider).watchAll();
});

final recentSportActivitiesProvider =
    StreamProvider.family<List<SportActivity>, SportType>((ref, tipo) {
  return ref
      .watch(sportActivityRepositoryProvider)
      .watchByType(tipo, limite: kAtividadesRecentes);
});

final sportActivityHistoryProvider =
    StreamProvider.family<List<SportActivity>, SportType>((ref, tipo) {
  return ref.watch(sportActivityRepositoryProvider).watchByType(tipo);
});

final sportActivityProvider =
    StreamProvider.family<SportActivity?, int>((ref, id) {
  return ref.watch(sportActivityRepositoryProvider).watchById(id);
});

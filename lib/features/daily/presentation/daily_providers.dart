import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/database_provider.dart';
import '../../profile/presentation/profile_providers.dart';
import '../data/daily_repository_impl.dart';
import '../domain/daily_models.dart';
import '../domain/daily_repository.dart';

final dailyRepositoryProvider = Provider<DailyRepository>((ref) {
  return DriftDailyRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(profileRepositoryProvider),
  );
});

final dailyTodayProvider = StreamProvider<DailyProgress>((ref) {
  return ref.watch(dailyRepositoryProvider).watchHoje();
});

final weekStripProvider = StreamProvider<List<WeekDayInfo>>((ref) {
  return ref.watch(dailyRepositoryProvider).watchSemana();
});

final folgasProvider = StreamProvider<FolgasInfo>((ref) {
  return ref.watch(dailyRepositoryProvider).watchFolgas();
});

final pendingPenaltyProvider = StreamProvider<int>((ref) {
  return ref.watch(dailyRepositoryProvider).watchPenalidadePendente();
});

final scheduleProvider = StreamProvider<Set<int>>((ref) {
  return ref.watch(dailyRepositoryProvider).watchProgramacao();
});

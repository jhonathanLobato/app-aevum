import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/database_provider.dart';
import '../data/profile_repository_impl.dart';
import '../domain/profile_repository.dart';
import '../domain/units.dart';
import '../domain/user_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return DriftProfileRepository(ref.watch(appDatabaseProvider));
});

final currentUserProvider = StreamProvider<UserProfile?>((ref) {
  return ref.watch(profileRepositoryProvider).watchCurrentUser();
});

/// Unidades de exibição do usuário (kg/lb e cm/pol); o banco guarda kg/cm.
final unitsProvider = Provider<Units>((ref) {
  return ref.watch(currentUserProvider).valueOrNull?.unidades ?? const Units();
});

/// Data do Despertar (criação do usuário ou primeiro registro).
final despertarProvider = StreamProvider<DateTime?>((ref) {
  return ref.watch(profileRepositoryProvider).watchDespertar();
});

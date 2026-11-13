import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/database_provider.dart';
import '../data/body_repository_impl.dart';
import '../domain/body.dart';

final bodyRepositoryProvider = Provider<DriftBodyRepository>((ref) {
  return DriftBodyRepository(ref.watch(appDatabaseProvider));
});

/// Registros corporais em ordem cronológica.
final bodyRecordsProvider = StreamProvider<List<BodyRecord>>((ref) {
  return ref.watch(bodyRepositoryProvider).watchAll();
});

final bodyRecordProvider = FutureProvider.family<BodyRecord?, int>((ref, id) {
  return ref.watch(bodyRepositoryProvider).get(id);
});

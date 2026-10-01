import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/database_provider.dart';
import '../data/personal_record_repository_impl.dart';
import '../domain/personal_record.dart';
import '../domain/personal_record_repository.dart';

final personalRecordRepositoryProvider =
    Provider<PersonalRecordRepository>((ref) {
  return DriftPersonalRecordRepository(ref.watch(appDatabaseProvider));
});

final exercisePersonalRecordsProvider =
    StreamProvider.family<List<PersonalRecord>, int>((ref, exerciseId) {
  return ref
      .watch(personalRecordRepositoryProvider)
      .watchForExercise(exerciseId);
});

import 'package:drift/drift.dart';

import '../../../database/app_database.dart' hide PersonalRecord;
import '../domain/personal_record.dart';
import '../domain/personal_record_repository.dart';

class DriftPersonalRecordRepository implements PersonalRecordRepository {
  DriftPersonalRecordRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<PersonalRecord>> watchForExercise(int exerciseId) {
    final query = _db.select(_db.personalRecords)
      ..where((p) => p.exerciseId.equals(exerciseId))
      ..orderBy(
          [(p) => OrderingTerm(expression: p.data, mode: OrderingMode.desc)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return PersonalRecord(
          id: row.id,
          exerciseId: row.exerciseId,
          tipo: row.tipo,
          valor: row.valor,
          data: row.data,
        );
      }).toList();
    });
  }

  @override
  Future<List<PersonalRecordBreak>> checkAndRecord({
    required int exerciseId,
    required int repeticoes,
    required double carga,
    required double volume,
  }) {
    return _db.transaction(() async {
      final breaks = <PersonalRecordBreak>[];
      final candidatos = <PersonalRecordType, double>{
        PersonalRecordType.carga: carga,
        PersonalRecordType.repeticoes: repeticoes.toDouble(),
        PersonalRecordType.volume: volume,
      };

      for (final candidato in candidatos.entries) {
        final atual = await (_db.selectOnly(_db.personalRecords)
              ..addColumns([_db.personalRecords.valor.max()])
              ..where(_db.personalRecords.exerciseId.equals(exerciseId) &
                  _db.personalRecords.tipo.equalsValue(candidato.key)))
            .map((row) => row.read(_db.personalRecords.valor.max()))
            .getSingleOrNull();

        if (atual == null || candidato.value > atual) {
          await _db.into(_db.personalRecords).insert(
                PersonalRecordsCompanion.insert(
                  exerciseId: exerciseId,
                  tipo: candidato.key,
                  valor: candidato.value,
                ),
              );
          breaks.add(PersonalRecordBreak(
            tipo: candidato.key,
            valorNovo: candidato.value,
            valorAnterior: atual,
          ));
        }
      }

      return breaks;
    });
  }
}

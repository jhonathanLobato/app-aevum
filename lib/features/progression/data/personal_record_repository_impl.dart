import 'package:drift/drift.dart';

import '../../../database/app_database.dart' hide PersonalRecord;
import '../../workouts/domain/workout_session.dart';
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
  Future<PrCheckResult> checkAndRecord({
    required int sessionId,
    required int serieId,
    required int exerciseId,
    required int repeticoes,
    required double carga,
    required double volume,
  }) {
    return _db.transaction(() async {
      final anterior = await _melhores(
        exerciseId,
        _db.workoutSessions.id.equals(sessionId).not() &
            _db.workoutSessions.status
                .equalsValue(WorkoutSessionStatus.concluido),
      );
      // Primeira vez do exercício: só estabelece a referência.
      if (anterior == null) return const PrCheckResult();

      // Melhores valores deste treino ANTES desta série.
      final noTreino = await _melhores(
        exerciseId,
        _db.workoutSessions.id.equals(sessionId) &
            _db.setEntries.id.equals(serieId).not(),
      );

      final candidatos = <PersonalRecordType, double>{
        PersonalRecordType.carga: carga,
        PersonalRecordType.repeticoes: repeticoes.toDouble(),
        PersonalRecordType.volume: volume,
      };

      final breaks = <PersonalRecordBreak>[];
      for (final candidato in candidatos.entries) {
        final tipo = candidato.key;
        final referencia = anterior[tipo]!;
        if (candidato.value <= referencia) continue;

        final jaBatidoNoTreino =
            noTreino != null && noTreino[tipo]! > referencia;
        if (!jaBatidoNoTreino) {
          await _db.into(_db.personalRecords).insert(
                PersonalRecordsCompanion.insert(
                  exerciseId: exerciseId,
                  tipo: tipo,
                  valor: candidato.value,
                ),
              );
          breaks.add(PersonalRecordBreak(
            tipo: tipo,
            valorNovo: candidato.value,
            valorAnterior: referencia,
          ));
        } else if (candidato.value > noTreino[tipo]!) {
          // Melhora dentro do mesmo treino: atualiza o PR deste treino (o de
          // maior valor do exercício) sem contar um PR novo.
          final atual = await (_db.select(_db.personalRecords)
                ..where((p) =>
                    p.exerciseId.equals(exerciseId) & p.tipo.equalsValue(tipo))
                ..orderBy([
                  (p) =>
                      OrderingTerm(expression: p.valor, mode: OrderingMode.desc)
                ])
                ..limit(1))
              .getSingleOrNull();
          if (atual != null) {
            await (_db.update(_db.personalRecords)
                  ..where((p) => p.id.equals(atual.id)))
                .write(PersonalRecordsCompanion(valor: Value(candidato.value)));
          }
        }
      }

      return PrCheckResult(
        breaks: breaks,
        superouCargaDeReferencia: carga > anterior[PersonalRecordType.carga]!,
      );
    });
  }

  /// Maiores carga, repetições e volume do exercício entre as séries cujas
  /// sessões satisfazem [filtro]; `null` se não houver nenhuma série.
  Future<Map<PersonalRecordType, double>?> _melhores(
    int exerciseId,
    Expression<bool> filtro,
  ) async {
    final maxCarga = _db.setEntries.carga.max();
    final maxReps = _db.setEntries.repeticoes.max();
    final maxVolume = _db.setEntries.volume.max();
    final linha = await (_db.selectOnly(_db.setEntries).join([
      innerJoin(
        _db.workoutSessions,
        _db.workoutSessions.id.equalsExp(_db.setEntries.sessionId),
      ),
    ])
          ..addColumns([maxCarga, maxReps, maxVolume])
          ..where(_db.setEntries.exerciseId.equals(exerciseId) & filtro))
        .getSingle();
    final carga = linha.read(maxCarga);
    if (carga == null) return null;
    return {
      PersonalRecordType.carga: carga,
      PersonalRecordType.repeticoes: linha.read(maxReps)!.toDouble(),
      PersonalRecordType.volume: linha.read(maxVolume)!,
    };
  }
}

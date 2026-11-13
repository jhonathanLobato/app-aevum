import 'package:drift/drift.dart';

import '../../../database/app_database.dart';
import '../../../database/watch_tables.dart';
import '../../workouts/domain/workout_session.dart';
import '../../daily/domain/daily_values.dart';
import '../domain/statistics.dart';
import '../domain/weekly_report.dart';
import '../domain/streak.dart';
import '../domain/statistics_repository.dart';

class DriftStatisticsRepository implements StatisticsRepository {
  DriftStatisticsRepository(this._db,
      {DeslocamentoLocal deslocamento = deslocamentoDoAparelho})
      : _deslocamento = deslocamento;

  final AppDatabase _db;
  final DeslocamentoLocal _deslocamento;

  @override
  Stream<GlobalStatistics> watchGlobal() {
    return _db.observar([
      _db.workoutSessions,
      _db.setEntries,
      _db.personalRecords,
      _db.users,
    ], _calcularGlobal);
  }

  Future<GlobalStatistics> _calcularGlobal() async {
    final treinosRealizados = _db.workoutSessions.id.count();
    final tempoTotal = _db.workoutSessions.duracaoSegundos.sum();

    final agregados = await (_db.selectOnly(_db.workoutSessions)
          ..addColumns([treinosRealizados, tempoTotal])
          ..where(_db.workoutSessions.status
              .equalsValue(WorkoutSessionStatus.concluido)))
        .getSingle();

    final volumeESeries = await (_db.selectOnly(_db.setEntries).join([
      innerJoin(
        _db.workoutSessions,
        _db.workoutSessions.id.equalsExp(_db.setEntries.sessionId),
      ),
    ])
          ..addColumns([
            _db.setEntries.volume.sum(),
            _db.setEntries.exerciseId.count(distinct: true),
            _db.setEntries.repeticoes.sum(),
          ])
          ..where(_db.workoutSessions.status
              .equalsValue(WorkoutSessionStatus.concluido)))
        .getSingle();

    final totalPRs = await (_db.selectOnly(_db.personalRecords)
          ..addColumns([_db.personalRecords.id.count()]))
        .map((row) => row.read(_db.personalRecords.id.count())!)
        .getSingle();

    final usuario = await (_db.select(_db.users)..limit(1)).getSingleOrNull();

    return GlobalStatistics(
      treinosRealizados: agregados.read(treinosRealizados) ?? 0,
      tempoTotalTreinando: Duration(seconds: agregados.read(tempoTotal) ?? 0),
      exerciciosRealizados:
          volumeESeries.read(_db.setEntries.exerciseId.count(distinct: true)) ??
              0,
      totalPRs: totalPRs,
      volumeTotal: volumeESeries.read(_db.setEntries.volume.sum()) ?? 0,
      totalRepeticoes: volumeESeries.read(_db.setEntries.repeticoes.sum()) ?? 0,
      xpAcumulado: usuario?.xp ?? 0,
      nivelAtual: usuario?.nivel ?? 1,
      maiorSequenciaDias: await _calcularMaiorSequencia(),
    );
  }

  /// Dias consecutivos com treino concluído, contados no fuso local.
  Future<int> _calcularMaiorSequencia() async {
    final datas = await (_db.selectOnly(_db.workoutSessions)
          ..addColumns([_db.workoutSessions.data])
          ..where(_db.workoutSessions.status
              .equalsValue(WorkoutSessionStatus.concluido)))
        .map((row) => row.read(_db.workoutSessions.data)!)
        .get();
    return maiorSequenciaDeDias(datas, deslocamento: _deslocamento);
  }

  @override
  Stream<List<WeeklyReport>> watchWeeklyReports() async* {
    Future<List<WeeklyReport>> carregar() async {
      final treinos = await (_db.select(_db.workoutSessions)
            ..where(
                (s) => s.status.equalsValue(WorkoutSessionStatus.concluido)))
          .get();
      final atividades = await _db.select(_db.sportActivities).get();
      final recordes = await _db.select(_db.personalRecords).get();

      final porSemana = <DateTime, List<int>>{};
      void contar(DateTime data, int indice) {
        final semana = inicioDaSemana(data);
        (porSemana[semana] ??= [0, 0, 0])[indice]++;
      }

      for (final t in treinos) {
        contar(t.data, 0);
      }
      for (final a in atividades) {
        contar(a.data, 1);
      }
      for (final r in recordes) {
        contar(r.data, 2);
      }
      porSemana.putIfAbsent(inicioDaSemana(DateTime.now()), () => [0, 0, 0]);

      final semanas = porSemana.keys.toList()..sort((a, b) => b.compareTo(a));
      return [
        for (final s in semanas)
          WeeklyReport(
            inicio: s,
            treinos: porSemana[s]![0],
            atividades: porSemana[s]![1],
            recordes: porSemana[s]![2],
          ),
      ];
    }

    yield* _db.observar([
      _db.workoutSessions,
      _db.sportActivities,
      _db.personalRecords,
    ], carregar);
  }

  @override
  Stream<List<ExerciseStatistics>> watchPerExercise() {
    final maiorCarga = _db.setEntries.carga.max();
    final maiorRepeticao = _db.setEntries.repeticoes.max();
    final maiorVolume = _db.setEntries.volume.max();
    final primeiroRegistro = _db.setEntries.data.min();
    final ultimoRegistro = _db.setEntries.data.max();
    final treinosComEsseExercicio =
        _db.setEntries.sessionId.count(distinct: true);

    final query = _db.selectOnly(_db.exercises).join([
      innerJoin(
        _db.setEntries,
        _db.setEntries.exerciseId.equalsExp(_db.exercises.id),
      ),
    ])
      ..addColumns([
        _db.exercises.id,
        _db.exercises.nome,
        maiorCarga,
        maiorRepeticao,
        maiorVolume,
        treinosComEsseExercicio,
        primeiroRegistro,
        ultimoRegistro,
      ])
      ..groupBy([_db.exercises.id])
      ..orderBy([OrderingTerm(expression: _db.exercises.nome)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return ExerciseStatistics(
          exerciseId: row.read(_db.exercises.id)!,
          exerciseNome: row.read(_db.exercises.nome)!,
          maiorCarga: row.read(maiorCarga) ?? 0,
          maiorRepeticao: row.read(maiorRepeticao) ?? 0,
          maiorVolume: row.read(maiorVolume) ?? 0,
          treinosRealizados: row.read(treinosComEsseExercicio) ?? 0,
          primeiroRegistro: row.read(primeiroRegistro)!,
          ultimoRegistro: row.read(ultimoRegistro)!,
        );
      }).toList();
    });
  }
}

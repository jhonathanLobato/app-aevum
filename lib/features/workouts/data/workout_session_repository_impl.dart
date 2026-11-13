import 'package:drift/drift.dart';

import '../../../database/app_database.dart'
    hide WorkoutSession, Mission, Achievement;
import '../../../database/watch_tables.dart';
import '../../achievements/domain/achievement.dart';
import '../../achievements/domain/achievement_repository.dart';
import '../../missions/domain/mission.dart';
import '../../missions/domain/mission_repository.dart';
import '../../profile/domain/profile_repository.dart';
import '../../profile/domain/xp_values.dart';
import '../../progression/domain/personal_record.dart';
import '../../progression/domain/personal_record_repository.dart';
import '../domain/workout_session.dart';
import '../domain/workout_session_repository.dart';

class DriftWorkoutSessionRepository implements WorkoutSessionRepository {
  DriftWorkoutSessionRepository(
    this._db,
    this._personalRecordRepository,
    this._profileRepository,
    this._missionRepository,
    this._achievementRepository,
  );

  final AppDatabase _db;
  final PersonalRecordRepository _personalRecordRepository;
  final ProfileRepository _profileRepository;
  final MissionRepository _missionRepository;
  final AchievementRepository _achievementRepository;

  @override
  Future<int> start({int? templateId, required String nome}) {
    return _db.into(_db.workoutSessions).insert(
          WorkoutSessionsCompanion.insert(
            templateId: Value(templateId),
            nome: nome,
            status: WorkoutSessionStatus.emAndamento,
          ),
        );
  }

  @override
  Stream<WorkoutSession?> watchSession(int sessionId) {
    return _db.observar([
      _db.workoutSessions,
      _db.setEntries,
      _db.exercises,
      _db.finishedExercises,
    ], () => _carregarSessao(sessionId));
  }

  Future<WorkoutSession?> _carregarSessao(int sessionId) async {
    final query = _db.select(_db.workoutSessions).join([
      leftOuterJoin(
        _db.setEntries,
        _db.setEntries.sessionId.equalsExp(_db.workoutSessions.id),
      ),
      leftOuterJoin(
        _db.exercises,
        _db.exercises.id.equalsExp(_db.setEntries.exerciseId),
      ),
    ])
      ..where(_db.workoutSessions.id.equals(sessionId))
      ..orderBy([OrderingTerm(expression: _db.setEntries.id)]);

    final rows = await query.get();
    if (rows.isEmpty) return null;

    final finalizados = await (_db.select(_db.finishedExercises)
          ..where((f) => f.sessionId.equals(sessionId)))
        .get();
    final sessionRow = rows.first.readTable(_db.workoutSessions);
    final series = <SetEntryRecord>[];
    for (final row in rows) {
      final setEntry = row.readTableOrNull(_db.setEntries);
      final exercise = row.readTableOrNull(_db.exercises);
      if (setEntry != null && exercise != null) {
        series.add(SetEntryRecord(
          id: setEntry.id,
          exerciseId: exercise.id,
          exerciseNome: exercise.nome,
          serie: setEntry.serie,
          repeticoes: setEntry.repeticoes,
          carga: setEntry.carga,
          volume: setEntry.volume,
          data: setEntry.data,
        ));
      }
    }

    return WorkoutSession(
      id: sessionRow.id,
      templateId: sessionRow.templateId,
      nome: sessionRow.nome,
      data: sessionRow.data,
      duracaoSegundos: sessionRow.duracaoSegundos,
      status: sessionRow.status,
      series: series,
      exerciciosFinalizados: {
        for (final f in finalizados) f.exerciseId,
      },
    );
  }

  @override
  Future<SetLogResult> logSet({
    required int sessionId,
    required int exerciseId,
    required int repeticoes,
    required double carga,
    String? observacoes,
  }) {
    return _db.transaction(() async {
      final seriesExistentes = await (_db.selectOnly(_db.setEntries)
            ..addColumns([_db.setEntries.serie.count()])
            ..where(_db.setEntries.sessionId.equals(sessionId) &
                _db.setEntries.exerciseId.equals(exerciseId)))
          .map((row) => row.read(_db.setEntries.serie.count())!)
          .getSingle();

      final volume = carga * repeticoes;

      final setEntryId = await _db.into(_db.setEntries).insert(
            SetEntriesCompanion.insert(
              sessionId: sessionId,
              exerciseId: exerciseId,
              serie: seriesExistentes + 1,
              repeticoes: repeticoes,
              carga: carga,
              volume: volume,
              observacoes: Value(observacoes),
            ),
          );

      final verificacao = await _personalRecordRepository.checkAndRecord(
        sessionId: sessionId,
        serieId: setEntryId,
        exerciseId: exerciseId,
        repeticoes: repeticoes,
        carga: carga,
        volume: volume,
      );

      final prsBatidos = verificacao.breaks;

      Mission? desafioConcluido;
      final bateuRecordeDeCarga =
          prsBatidos.any((pr) => pr.tipo == PersonalRecordType.carga);
      // Carga acima da referência, mas com o PR de carga deste treino já
      // contado numa série anterior: só pode concluir o desafio existente
      // (não gera PR/XP novo nem cria o desafio seguinte).
      if (bateuRecordeDeCarga || verificacao.superouCargaDeReferencia) {
        final exercicio = await (_db.select(_db.exercises)
              ..where((e) => e.id.equals(exerciseId)))
            .getSingle();
        desafioConcluido = await _missionRepository.registrarNovoRecordeDeCarga(
          exerciseId: exerciseId,
          exerciseNome: exercicio.nome,
          novoRecorde: carga,
          criarProximo: bateuRecordeDeCarga,
        );
      }

      final xpTotal = (prsBatidos.isEmpty
              ? 0
              : XpValues.novoRecordePessoal * prsBatidos.length) +
          (desafioConcluido?.recompensaXp ?? 0);
      final xpGanho =
          xpTotal == 0 ? null : await _profileRepository.addXp(xpTotal);

      // Depois do XP do PR: o XP das conquistas não mexe no LEVEL UP dele.
      final conquistasDesbloqueadas = prsBatidos.isEmpty
          ? <Achievement>[]
          : await _achievementRepository.verificarPorNovoRecorde();

      return SetLogResult(
        setEntryId: setEntryId,
        prsBatidos: prsBatidos,
        xpGanho: xpGanho,
        desafioConcluido: desafioConcluido,
        conquistasDesbloqueadas: conquistasDesbloqueadas,
      );
    });
  }

  @override
  Future<void> removeSet(int setEntryId) {
    return (_db.delete(_db.setEntries)..where((e) => e.id.equals(setEntryId)))
        .go();
  }

  @override
  Future<FinishResult?> finish(int sessionId, {required Duration duracao}) {
    return _db.transaction(() async {
      // Só atualiza (e só concede XP) se a sessão ainda estava em andamento,
      // para uma chamada repetida não conceder XP de novo.
      final linhasAfetadas = await (_db.update(_db.workoutSessions)
            ..where((s) =>
                s.id.equals(sessionId) &
                s.status.equalsValue(WorkoutSessionStatus.emAndamento)))
          .write(
        WorkoutSessionsCompanion(
          status: const Value(WorkoutSessionStatus.concluido),
          duracaoSegundos: Value(duracao.inSeconds),
        ),
      );

      if (linhasAfetadas == 0) return null;

      await (_db.delete(_db.setDrafts)
            ..where((d) => d.sessionId.equals(sessionId)))
          .go();

      final missoesConcluidas =
          await _missionRepository.registrarTreinoConcluido();
      final xpMissoes =
          missoesConcluidas.fold<int>(0, (soma, m) => soma + m.recompensaXp);

      final xpGanho =
          await _profileRepository.addXp(XpValues.finalizarTreino + xpMissoes);

      // Depois do XP do treino: o XP das conquistas não mexe no LEVEL UP dele.
      final conquistasDesbloqueadas =
          await _achievementRepository.verificarPorTreinoConcluido();

      return FinishResult(
        xpGanho: xpGanho,
        missoesConcluidas: missoesConcluidas,
        conquistasDesbloqueadas: conquistasDesbloqueadas,
      );
    });
  }

  @override
  Future<void> finishExercise(int sessionId, int exerciseId) {
    return _db.into(_db.finishedExercises).insert(
          FinishedExercisesCompanion.insert(
              sessionId: sessionId, exerciseId: exerciseId),
          mode: InsertMode.insertOrIgnore,
        );
  }

  @override
  Future<void> resumeExercise(int sessionId, int exerciseId) {
    return (_db.delete(_db.finishedExercises)
          ..where((f) =>
              f.sessionId.equals(sessionId) & f.exerciseId.equals(exerciseId)))
        .go();
  }

  JoinedSelectStatement<HasResultSet, dynamic> _consultaAtiva(
      Expression<int> totalSeries) {
    return _db.selectOnly(_db.workoutSessions).join([
      leftOuterJoin(
        _db.setEntries,
        _db.setEntries.sessionId.equalsExp(_db.workoutSessions.id),
        useColumns: false,
      ),
    ])
      ..addColumns([
        _db.workoutSessions.id,
        _db.workoutSessions.templateId,
        _db.workoutSessions.nome,
        _db.workoutSessions.data,
        totalSeries,
      ])
      ..where(_db.workoutSessions.status
          .equalsValue(WorkoutSessionStatus.emAndamento))
      ..groupBy([_db.workoutSessions.id])
      ..orderBy([
        OrderingTerm(
            expression: _db.workoutSessions.data, mode: OrderingMode.desc),
        OrderingTerm(
            expression: _db.workoutSessions.id, mode: OrderingMode.desc),
      ])
      ..limit(1);
  }

  ActiveWorkoutInfo? _toActive(List<TypedResult> rows, Expression<int> total) {
    if (rows.isEmpty) return null;
    final row = rows.first;
    return ActiveWorkoutInfo(
      id: row.read(_db.workoutSessions.id)!,
      templateId: row.read(_db.workoutSessions.templateId),
      nome: row.read(_db.workoutSessions.nome)!,
      data: row.read(_db.workoutSessions.data)!,
      totalSeries: row.read(total) ?? 0,
    );
  }

  @override
  Stream<ActiveWorkoutInfo?> watchActive() {
    final total = _db.setEntries.id.count();
    return _consultaAtiva(total).watch().map((rows) => _toActive(rows, total));
  }

  @override
  Future<ActiveWorkoutInfo?> findActive() async {
    final total = _db.setEntries.id.count();
    return _toActive(await _consultaAtiva(total).get(), total);
  }

  @override
  Future<void> discard(int sessionId) {
    return _db.transaction(() async {
      // Só sessões ainda em andamento podem ser descartadas — treino
      // concluído (ou já cancelado) nunca perde as séries por aqui.
      final emAndamento = await (_db.select(_db.workoutSessions)
            ..where((s) =>
                s.id.equals(sessionId) &
                s.status.equalsValue(WorkoutSessionStatus.emAndamento)))
          .getSingleOrNull();
      if (emAndamento == null) return;

      await (_db.delete(_db.setEntries)
            ..where((e) => e.sessionId.equals(sessionId)))
          .go();
      await (_db.delete(_db.setDrafts)
            ..where((d) => d.sessionId.equals(sessionId)))
          .go();
      await (_db.update(_db.workoutSessions)
            ..where((s) => s.id.equals(sessionId)))
          .write(
        const WorkoutSessionsCompanion(
            status: Value(WorkoutSessionStatus.cancelado)),
      );
    });
  }

  @override
  Future<void> cancel(int sessionId) {
    return (_db.update(_db.workoutSessions)
          ..where((s) => s.id.equals(sessionId)))
        .write(
      const WorkoutSessionsCompanion(
          status: Value(WorkoutSessionStatus.cancelado)),
    );
  }

  @override
  Stream<List<WorkoutSessionSummary>> watchHistory() {
    final totalSeries = _db.setEntries.id.count();
    final volumeTotal = _db.setEntries.volume.sum();
    final totalExercicios = _db.setEntries.exerciseId.count(distinct: true);

    final query = _db.selectOnly(_db.workoutSessions).join([
      leftOuterJoin(
        _db.setEntries,
        _db.setEntries.sessionId.equalsExp(_db.workoutSessions.id),
        useColumns: false,
      ),
    ])
      ..addColumns([
        _db.workoutSessions.id,
        _db.workoutSessions.nome,
        _db.workoutSessions.data,
        _db.workoutSessions.duracaoSegundos,
        totalSeries,
        volumeTotal,
        totalExercicios,
      ])
      ..where(_db.workoutSessions.status
          .equalsValue(WorkoutSessionStatus.concluido))
      ..groupBy([_db.workoutSessions.id])
      ..orderBy([
        OrderingTerm(
            expression: _db.workoutSessions.data, mode: OrderingMode.desc),
      ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return WorkoutSessionSummary(
          id: row.read(_db.workoutSessions.id)!,
          nome: row.read(_db.workoutSessions.nome)!,
          data: row.read(_db.workoutSessions.data)!,
          duracaoSegundos: row.read(_db.workoutSessions.duracaoSegundos),
          totalSeries: row.read(totalSeries) ?? 0,
          volumeTotal: row.read(volumeTotal) ?? 0,
          totalExercicios: row.read(totalExercicios) ?? 0,
        );
      }).toList();
    });
  }

  @override
  Stream<List<SetEntryRecord>> watchExerciseHistory(int exerciseId) {
    final query = _db.select(_db.setEntries).join([
      innerJoin(
        _db.exercises,
        _db.exercises.id.equalsExp(_db.setEntries.exerciseId),
      ),
    ])
      ..where(_db.setEntries.exerciseId.equals(exerciseId))
      ..orderBy([OrderingTerm(expression: _db.setEntries.data)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final setEntry = row.readTable(_db.setEntries);
        final exercise = row.readTable(_db.exercises);
        return SetEntryRecord(
          id: setEntry.id,
          exerciseId: exercise.id,
          exerciseNome: exercise.nome,
          serie: setEntry.serie,
          repeticoes: setEntry.repeticoes,
          carga: setEntry.carga,
          volume: setEntry.volume,
          data: setEntry.data,
        );
      }).toList();
    });
  }
}

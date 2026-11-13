import 'package:drift/drift.dart' show BooleanExpressionOperators;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/database/app_database.dart';
import 'package:gym_system/features/achievements/data/achievement_repository_impl.dart';
import 'package:gym_system/features/missions/data/mission_repository_impl.dart';
import 'package:gym_system/features/missions/domain/mission.dart';
import 'package:gym_system/features/profile/data/profile_repository_impl.dart';
import 'package:gym_system/features/progression/data/personal_record_repository_impl.dart';
import 'package:gym_system/features/progression/domain/personal_record.dart';
import 'package:gym_system/features/workouts/data/workout_session_repository_impl.dart';
import 'package:gym_system/features/workouts/domain/workout_session.dart';

void main() {
  late AppDatabase db;
  late DriftWorkoutSessionRepository repo;
  late int exercicioId;
  late int treinoId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftWorkoutSessionRepository(
      db,
      DriftPersonalRecordRepository(db),
      DriftProfileRepository(db),
      DriftMissionRepository(db),
      DriftAchievementRepository(db),
    );

    exercicioId = await db.into(db.exercises).insert(
          ExercisesCompanion.insert(
              nome: 'Supino reto', grupoMuscular: 'Peito'),
        );
    treinoId = await db
        .into(db.workoutTemplates)
        .insert(WorkoutTemplatesCompanion.insert(nome: 'Treino A'));
  });

  tearDown(() async {
    await db.close();
  });

  test('inicia uma sessão em andamento', () async {
    final sessionId = await repo.start(templateId: treinoId, nome: 'Treino A');
    final session = await repo.watchSession(sessionId).first;

    expect(session!.status, WorkoutSessionStatus.emAndamento);
    expect(session.templateId, treinoId);
    expect(session.series, isEmpty);
  });

  test('registra séries com numeração e volume calculados automaticamente',
      () async {
    final sessionId = await repo.start(templateId: treinoId, nome: 'Treino A');

    await repo.logSet(
        sessionId: sessionId,
        exerciseId: exercicioId,
        repeticoes: 10,
        carga: 30);
    await repo.logSet(
        sessionId: sessionId,
        exerciseId: exercicioId,
        repeticoes: 8,
        carga: 32);

    final session = await repo.watchSession(sessionId).first;
    final series = session!.seriesDoExercicio(exercicioId);

    expect(series, hasLength(2));
    expect(series[0].serie, 1);
    expect(series[0].volume, 300);
    expect(series[1].serie, 2);
    expect(series[1].volume, 256);
  });

  test('remove uma série registrada', () async {
    final sessionId = await repo.start(templateId: treinoId, nome: 'Treino A');
    await repo.logSet(
        sessionId: sessionId,
        exerciseId: exercicioId,
        repeticoes: 10,
        carga: 30);

    final antes = await repo.watchSession(sessionId).first;
    await repo.removeSet(antes!.series.single.id);

    final depois = await repo.watchSession(sessionId).first;
    expect(depois!.series, isEmpty);
  });

  test('finaliza a sessão com a duração informada', () async {
    final sessionId = await repo.start(templateId: treinoId, nome: 'Treino A');
    await repo.finish(sessionId, duracao: const Duration(minutes: 42));

    final session = await repo.watchSession(sessionId).first;
    expect(session!.status, WorkoutSessionStatus.concluido);
    expect(session.duracaoSegundos, 42 * 60);
  });

  test('cancela a sessão', () async {
    final sessionId = await repo.start(templateId: treinoId, nome: 'Treino A');
    await repo.cancel(sessionId);

    final session = await repo.watchSession(sessionId).first;
    expect(session!.status, WorkoutSessionStatus.cancelado);
  });

  test('histórico só lista treinos finalizados, com séries e volume somados',
      () async {
    final emAndamentoId =
        await repo.start(templateId: treinoId, nome: 'Treino A');
    await repo.logSet(
        sessionId: emAndamentoId,
        exerciseId: exercicioId,
        repeticoes: 10,
        carga: 30);

    final finalizadoId =
        await repo.start(templateId: treinoId, nome: 'Treino A');
    await repo.logSet(
        sessionId: finalizadoId,
        exerciseId: exercicioId,
        repeticoes: 10,
        carga: 30);
    await repo.logSet(
        sessionId: finalizadoId,
        exerciseId: exercicioId,
        repeticoes: 8,
        carga: 32);
    await repo.finish(finalizadoId, duracao: const Duration(minutes: 10));

    final historico = await repo.watchHistory().first;

    expect(historico, hasLength(1));
    expect(historico.single.id, finalizadoId);
    expect(historico.single.totalSeries, 2);
    expect(historico.single.volumeTotal, 300 + 256);
  });

  test(
      'histórico do exercício reúne séries de sessões diferentes em ordem cronológica',
      () async {
    final sessao1 = await repo.start(templateId: treinoId, nome: 'Treino A');
    await repo.logSet(
        sessionId: sessao1, exerciseId: exercicioId, repeticoes: 10, carga: 30);
    await repo.finish(sessao1, duracao: const Duration(minutes: 10));

    final sessao2 = await repo.start(templateId: treinoId, nome: 'Treino A');
    await repo.logSet(
        sessionId: sessao2, exerciseId: exercicioId, repeticoes: 10, carga: 32);
    await repo.finish(sessao2, duracao: const Duration(minutes: 10));

    final historicoExercicio =
        await repo.watchExerciseHistory(exercicioId).first;

    expect(historicoExercicio, hasLength(2));
    expect(historicoExercicio[0].carga, 30);
    expect(historicoExercicio[1].carga, 32);
  });

  /// Registra e conclui um treino anterior com uma série, para servir de
  /// referência ("melhor resultado anterior") nos testes de PR.
  Future<void> treinoAnterior({double carga = 30, int repeticoes = 10}) async {
    final id = await repo.start(templateId: treinoId, nome: 'Treino anterior');
    await repo.logSet(
        sessionId: id,
        exerciseId: exercicioId,
        repeticoes: repeticoes,
        carga: carga);
    await repo.finish(id, duracao: const Duration(minutes: 10));
  }

  test('a primeira vez de um exercício só estabelece a referência', () async {
    final sessionId = await repo.start(templateId: treinoId, nome: 'Treino A');
    final primeira = await repo.logSet(
        sessionId: sessionId,
        exerciseId: exercicioId,
        repeticoes: 10,
        carga: 30);
    // Mesmo superando a série anterior do próprio treino, ainda é a
    // referência: sem PR, sem XP, sem desafio.
    final segunda = await repo.logSet(
        sessionId: sessionId,
        exerciseId: exercicioId,
        repeticoes: 12,
        carga: 40);

    for (final r in [primeira, segunda]) {
      expect(r.prsBatidos, isEmpty);
      expect(r.xpGanho, isNull);
      expect(r.desafioConcluido, isNull);
      expect(r.conquistasDesbloqueadas, isEmpty);
    }
    expect(await db.select(db.personalRecords).get(), isEmpty);
    expect((await db.select(db.users).get()), isEmpty);
    final desafios = await (db.select(db.missions)
          ..where((m) => m.tipo.equalsValue(MissionType.desafio)))
        .get();
    expect(desafios, isEmpty);
  });

  test('só reporta PR quando supera o melhor de treinos anteriores', () async {
    await treinoAnterior(carga: 30, repeticoes: 10);
    final sessionId = await repo.start(templateId: treinoId, nome: 'Treino B');

    // Mesma carga e menos repetições: nenhum recorde.
    final semNovoRecorde = await repo.logSet(
        sessionId: sessionId,
        exerciseId: exercicioId,
        repeticoes: 8,
        carga: 30);
    expect(semNovoRecorde.prsBatidos, isEmpty);

    // Carga maior: recorde de carga e de volume, mas não de repetições.
    final comNovoRecorde = await repo.logSet(
        sessionId: sessionId,
        exerciseId: exercicioId,
        repeticoes: 10,
        carga: 32);
    final tipos = comNovoRecorde.prsBatidos.map((pr) => pr.tipo).toSet();
    expect(tipos, {PersonalRecordType.carga, PersonalRecordType.volume});

    final prCarga = comNovoRecorde.prsBatidos
        .firstWhere((pr) => pr.tipo == PersonalRecordType.carga);
    expect(prCarga.valorAnterior, 30);
    expect(prCarga.valorNovo, 32);
  });

  test('cada tipo de PR conta no máximo uma vez por exercício por treino',
      () async {
    await treinoAnterior(carga: 30, repeticoes: 10);
    final sessionId = await repo.start(templateId: treinoId, nome: 'Treino B');

    final primeira = await repo.logSet(
        sessionId: sessionId,
        exerciseId: exercicioId,
        repeticoes: 10,
        carga: 32);
    expect(primeira.prsBatidos, hasLength(2)); // carga + volume
    expect(primeira.xpGanho!.xpGanho, 50 * 2);

    // Supera de novo carga e volume no mesmo treino: não conta PR novo.
    final segunda = await repo.logSet(
        sessionId: sessionId,
        exerciseId: exercicioId,
        repeticoes: 10,
        carga: 33);
    expect(segunda.prsBatidos, isEmpty);
    expect(segunda.xpGanho, isNull);

    // Repetições ainda não tinham sido batidas neste treino: conta uma vez.
    final reps = await repo.logSet(
        sessionId: sessionId,
        exerciseId: exercicioId,
        repeticoes: 12,
        carga: 20);
    expect(
        reps.prsBatidos.map((pr) => pr.tipo), [PersonalRecordType.repeticoes]);
    final repsDeNovo = await repo.logSet(
        sessionId: sessionId,
        exerciseId: exercicioId,
        repeticoes: 14,
        carga: 20);
    expect(repsDeNovo.prsBatidos, isEmpty);

    // 3 tipos, uma linha por tipo; o valor guardado é o melhor do treino.
    final linhas = await db.select(db.personalRecords).get();
    expect(linhas, hasLength(3));
    final carga = linhas.singleWhere((p) => p.tipo == PersonalRecordType.carga);
    expect(carga.valor, 33);
    final repsLinha =
        linhas.singleWhere((p) => p.tipo == PersonalRecordType.repeticoes);
    expect(repsLinha.valor, 14);
  });

  test('o PR de um treino novo compara com o melhor de todos os anteriores',
      () async {
    await treinoAnterior(carga: 30, repeticoes: 10);
    await treinoAnterior(carga: 40, repeticoes: 5);

    final sessionId = await repo.start(templateId: treinoId, nome: 'Treino C');
    final abaixo = await repo.logSet(
        sessionId: sessionId,
        exerciseId: exercicioId,
        repeticoes: 10,
        carga: 35);
    // 35 < 40 de carga, 10 repetições = recorde anterior de repetições
    // (empate não conta); volume 350 > 300 (30x10) e > 200 (40x5).
    expect(abaixo.prsBatidos.map((pr) => pr.tipo), [PersonalRecordType.volume]);
  });

  test('só cria desafio de carga quando há um PR de carga de verdade',
      () async {
    final sessionId = await repo.start(templateId: treinoId, nome: 'Treino A');
    await repo.logSet(
        sessionId: sessionId,
        exerciseId: exercicioId,
        repeticoes: 10,
        carga: 30);
    await repo.finish(sessionId, duracao: const Duration(minutes: 10));
    expect(
        await (db.select(db.missions)
              ..where((m) => m.tipo.equalsValue(MissionType.desafio)))
            .get(),
        isEmpty);

    final segunda = await repo.start(templateId: treinoId, nome: 'Treino B');
    await repo.logSet(
        sessionId: segunda, exerciseId: exercicioId, repeticoes: 10, carga: 32);
    final desafio = await (db.select(db.missions)
          ..where((m) => m.tipo.equalsValue(MissionType.desafio)))
        .getSingle();
    expect(desafio.objetivo, 34);
  });

  test(
      'desafio ativo é concluído por carga maior no mesmo treino, sem PR extra',
      () async {
    await treinoAnterior(carga: 30);
    final sessionId = await repo.start(templateId: treinoId, nome: 'Treino B');
    await repo.logSet(
        sessionId: sessionId,
        exerciseId: exercicioId,
        repeticoes: 10,
        carga: 31); // PR de carga: cria desafio com meta 33
    final atingiu = await repo.logSet(
        sessionId: sessionId,
        exerciseId: exercicioId,
        repeticoes: 10,
        carga: 33);
    expect(atingiu.prsBatidos, isEmpty);
    expect(atingiu.desafioConcluido, isNotNull);
    expect(atingiu.xpGanho!.xpGanho, atingiu.desafioConcluido!.recompensaXp);
    // Não encadeia um novo desafio dentro do mesmo treino.
    final ativos = await (db.select(db.missions)
          ..where((m) =>
              m.tipo.equalsValue(MissionType.desafio) &
              m.status.equalsValue(MissionStatus.ativa)))
        .get();
    expect(ativos, isEmpty);
  });

  test('finalizar o treino concede XP uma única vez', () async {
    final sessionId = await repo.start(templateId: treinoId, nome: 'Treino A');

    final primeiraVez =
        await repo.finish(sessionId, duracao: const Duration(minutes: 10));
    expect(primeiraVez, isNotNull);
    // 100 de finalizar o treino + 50 da missão diária (objetivo 1, já batido).
    expect(primeiraVez!.xpGanho.xpGanho, 150);
    expect(primeiraVez.missoesConcluidas, hasLength(1));
    expect(primeiraVez.missoesConcluidas.single.tipo, MissionType.diaria);

    final segundaVez =
        await repo.finish(sessionId, duracao: const Duration(minutes: 20));
    expect(segundaVez, isNull);
  });
}

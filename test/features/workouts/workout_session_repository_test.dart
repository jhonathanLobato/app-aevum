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

  test('a primeira série de um exercício já é um recorde pessoal', () async {
    final sessionId = await repo.start(templateId: treinoId, nome: 'Treino A');
    final resultado = await repo.logSet(
        sessionId: sessionId,
        exerciseId: exercicioId,
        repeticoes: 10,
        carga: 30);

    final tipos = resultado.prsBatidos.map((pr) => pr.tipo).toSet();
    expect(tipos, {
      PersonalRecordType.carga,
      PersonalRecordType.repeticoes,
      PersonalRecordType.volume,
    });
    expect(
        resultado.prsBatidos.every((pr) => pr.valorAnterior == null), isTrue);
  });

  test('só reporta PR quando o novo valor supera o recorde anterior', () async {
    final sessionId = await repo.start(templateId: treinoId, nome: 'Treino A');
    await repo.logSet(
        sessionId: sessionId,
        exerciseId: exercicioId,
        repeticoes: 10,
        carga: 30);

    // Mesma carga e menos repetições: não deve bater nenhum recorde novo.
    final semNovoRecorde = await repo.logSet(
        sessionId: sessionId,
        exerciseId: exercicioId,
        repeticoes: 8,
        carga: 30);
    expect(semNovoRecorde.prsBatidos, isEmpty);

    // Carga maior: novo recorde de carga e de volume, mas não de repetições.
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

  test('concede XP só quando algum PR é batido na série', () async {
    final sessionId = await repo.start(templateId: treinoId, nome: 'Treino A');

    final primeira = await repo.logSet(
        sessionId: sessionId,
        exerciseId: exercicioId,
        repeticoes: 10,
        carga: 30);
    expect(primeira.xpGanho, isNotNull);
    expect(primeira.xpGanho!.xpGanho, 50 * 3); // carga + repetições + volume

    final semPr = await repo.logSet(
        sessionId: sessionId,
        exerciseId: exercicioId,
        repeticoes: 8,
        carga: 30);
    expect(semPr.xpGanho, isNull);
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

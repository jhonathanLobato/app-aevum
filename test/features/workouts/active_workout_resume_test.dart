import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_system/database/app_database.dart';
import 'package:gym_system/database/database_provider.dart';
import 'package:gym_system/features/achievements/data/achievement_repository_impl.dart';
import 'package:gym_system/features/missions/data/mission_repository_impl.dart';
import 'package:gym_system/features/profile/data/profile_repository_impl.dart';
import 'package:gym_system/features/progression/data/personal_record_repository_impl.dart';
import 'package:gym_system/features/workouts/data/workout_session_repository_impl.dart';
import 'package:gym_system/features/workouts/data/workout_template_repository_impl.dart';
import 'package:gym_system/features/workouts/domain/workout_session.dart';
import 'package:gym_system/features/workouts/presentation/active_workout_screen.dart';
import 'package:gym_system/features/workouts/presentation/workout_template_detail_screen.dart';

AppDatabase _memoryDb() => AppDatabase.forTesting(NativeDatabase.memory());

DriftWorkoutSessionRepository _repo(AppDatabase db) =>
    DriftWorkoutSessionRepository(
      db,
      DriftPersonalRecordRepository(db),
      DriftProfileRepository(db),
      DriftMissionRepository(db),
      DriftAchievementRepository(db),
    );

Future<int> _exercicio(AppDatabase db, String nome) => db
    .into(db.exercises)
    .insert(ExercisesCompanion.insert(nome: nome, grupoMuscular: 'Peito'));

Future<int> _treino(AppDatabase db, String nome, List<int> exercicios) async {
  final repo = DriftWorkoutTemplateRepository(db);
  final id = await repo.create(nome);
  for (final e in exercicios) {
    await repo.addExercise(id, e);
  }
  return id;
}

Future<void> _aguardar(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}

Future<void> _pump(WidgetTester tester, AppDatabase db, int treinoId) async {
  final router = GoRouter(
    initialLocation: '/workouts/$treinoId',
    routes: [
      GoRoute(
          path: '/workouts/:id',
          builder: (c, s) => WorkoutTemplateDetailScreen(
              templateId: int.parse(s.pathParameters['id']!))),
      GoRoute(
          path: '/sessions/:id',
          builder: (c, s) => ActiveWorkoutScreen(
              sessionId: int.parse(s.pathParameters['id']!))),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await _aguardar(tester);
}

Future<void> _finish(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 50));
  await db.close();
}

Finder _campo(String chave) => find.descendant(
    of: find.byKey(Key(chave)), matching: find.byType(TextField));

void main() {
  group('repositório', () {
    test('findActive/watchActive acompanham a sessão em andamento', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      final repo = _repo(db);
      final ex = await _exercicio(db, 'Supino');

      expect(await repo.findActive(), isNull);

      final id = await repo.start(nome: 'Treino A');
      var ativo = (await repo.findActive())!;
      expect(ativo.id, id);
      expect(ativo.totalSeries, 0);

      await repo.logSet(
          sessionId: id, exerciseId: ex, repeticoes: 10, carga: 30);
      ativo = (await repo.findActive())!;
      expect(ativo.totalSeries, 1);

      await repo.finish(id, duracao: const Duration(minutes: 5));
      expect(await repo.findActive(), isNull);
    });

    test('descartar apaga as séries e cancela, mas não desfaz o XP', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      final repo = _repo(db);
      final ex = await _exercicio(db, 'Supino');
      // Treino anterior concluído: a referência para o PR do treino atual.
      final anterior = await repo.start(nome: 'Treino anterior');
      await repo.logSet(
          sessionId: anterior, exerciseId: ex, repeticoes: 10, carga: 30);
      await repo.finish(anterior, duracao: const Duration(minutes: 5));
      final id = await repo.start(nome: 'Treino A');
      await repo.logSet(
          sessionId: id, exerciseId: ex, repeticoes: 10, carga: 32);
      final xpAntes = (await db.select(db.users).getSingle()).xp;
      expect(xpAntes, greaterThan(150)); // inclui o XP do PR de 32 kg

      await repo.discard(id);

      expect(await repo.findActive(), isNull);
      final restantes = await db.select(db.setEntries).get();
      expect(restantes.where((e) => e.sessionId == id), isEmpty);
      final sessao = await (db.select(db.workoutSessions)
            ..where((w) => w.id.equals(id)))
          .getSingle();
      expect(sessao.status, WorkoutSessionStatus.cancelado);
      expect((await db.select(db.users).getSingle()).xp, xpAntes);
    });

    test('descartar não mexe em treino já concluído', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      final repo = _repo(db);
      final ex = await _exercicio(db, 'Supino');
      final id = await repo.start(nome: 'Treino A');
      await repo.logSet(
          sessionId: id, exerciseId: ex, repeticoes: 10, carga: 30);
      await repo.finish(id, duracao: const Duration(minutes: 5));

      await repo.discard(id);

      final sessao = await db.select(db.workoutSessions).getSingle();
      expect(sessao.status, WorkoutSessionStatus.concluido);
      expect(await db.select(db.setEntries).get(), hasLength(1));
    });
  });

  testWidgets(
      'sair do treino mantém tudo; iniciar de novo CONTINUA a mesma sessão',
      (tester) async {
    final db = _memoryDb();
    final ex1 = await _exercicio(db, 'Supino reto');
    final ex2 = await _exercicio(db, 'Crucifixo');
    final treinoId = await _treino(db, 'Treino A', [ex1, ex2]);

    await _pump(tester, db, treinoId);
    await tester.tap(find.text('INICIAR TREINO'));
    await _aguardar(tester);

    await tester.enterText(_campo('workout_carga_field'), '30');
    await tester.enterText(_campo('workout_reps_field'), '10');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('REGISTRAR SÉRIE'));
    await tester.tap(find.text('REGISTRAR SÉRIE'));
    await _aguardar(tester);
    while (find.text('OK').evaluate().isNotEmpty) {
      await tester.tap(find.text('OK').first);
      await _aguardar(tester);
    }

    // Sai sem finalizar nem descartar (apertou voltar sem querer).
    await tester.tap(find.byTooltip('Voltar'));
    await _aguardar(tester);

    final sessoes = await db.select(db.workoutSessions).get();
    expect(sessoes.single.status, WorkoutSessionStatus.emAndamento);
    expect(await db.select(db.setEntries).get(), hasLength(1));

    // Iniciar de novo continua a mesma sessão, com a série já registrada.
    await tester.tap(find.text('INICIAR TREINO'));
    await _aguardar(tester);

    expect(await db.select(db.workoutSessions).get(), hasLength(1));
    // Reabre no primeiro exercício ainda sem série (o 2º)...
    expect(find.textContaining('02 / 02'), findsOneWidget);
    // ...e a série do 1º continua lá.
    await tester.ensureVisible(find.byIcon(Icons.chevron_left));
    await tester.tap(find.byIcon(Icons.chevron_left));
    await _aguardar(tester);
    expect(find.text('30.0 KG × 10'), findsOneWidget);

    await _finish(tester, db);
  });

  testWidgets('reabre no primeiro exercício ainda sem série', (tester) async {
    final db = _memoryDb();
    final ex1 = await _exercicio(db, 'Supino reto');
    final ex2 = await _exercicio(db, 'Crucifixo');
    final ex3 = await _exercicio(db, 'Tríceps corda');
    final treinoId = await _treino(db, 'Treino A', [ex1, ex2, ex3]);
    final repo = _repo(db);
    final id = await repo.start(templateId: treinoId, nome: 'Treino A');
    await repo.logSet(
        sessionId: id, exerciseId: ex1, repeticoes: 10, carga: 30);
    await repo.logSet(
        sessionId: id, exerciseId: ex2, repeticoes: 10, carga: 20);

    await _pump(tester, db, treinoId);
    await tester.tap(find.text('INICIAR TREINO'));
    await _aguardar(tester);

    expect(find.textContaining('03 / 03'), findsOneWidget);
    expect(find.text('TRÍCEPS CORDA'), findsOneWidget);

    await _finish(tester, db);
  });

  testWidgets('carga e repetições digitadas sobrevivem a sair da tela',
      (tester) async {
    final db = _memoryDb();
    final ex = await _exercicio(db, 'Supino reto');
    final treinoId = await _treino(db, 'Treino A', [ex]);

    await _pump(tester, db, treinoId);
    await tester.tap(find.text('INICIAR TREINO'));
    await _aguardar(tester);

    await tester.enterText(_campo('workout_carga_field'), '42,5');
    await tester.enterText(_campo('workout_reps_field'), '8');
    await tester.pump();

    await tester.tap(find.byTooltip('Voltar'));
    await _aguardar(tester);
    await tester.tap(find.text('INICIAR TREINO'));
    await _aguardar(tester);

    expect(
        tester
            .widget<TextField>(_campo('workout_carga_field'))
            .controller!
            .text,
        '42,5');
    expect(
        tester.widget<TextField>(_campo('workout_reps_field')).controller!.text,
        '8');

    await _finish(tester, db);
  });

  group('já existe outro treino em andamento', () {
    Future<(int, int)> prepara(AppDatabase db) async {
      final ex = await _exercicio(db, 'Supino reto');
      final treinoA = await _treino(db, 'Treino A', [ex]);
      final treinoB = await _treino(db, 'Treino B', [ex]);
      final sessaoA =
          await _repo(db).start(templateId: treinoA, nome: 'Treino A');
      return (treinoB, sessaoA);
    }

    testWidgets('mostra o aviso e "Continuar o atual" abre o treino atual',
        (tester) async {
      final db = _memoryDb();
      final (treinoB, sessaoA) = await prepara(db);

      await _pump(tester, db, treinoB);
      await tester.tap(find.text('INICIAR TREINO'));
      await _aguardar(tester);
      expect(find.text('TREINO EM ANDAMENTO'), findsOneWidget);

      await tester.tap(find.text('CONTINUAR O ATUAL'));
      await _aguardar(tester);

      expect(find.text('Treino A'), findsOneWidget); // sessão A aberta
      expect(await db.select(db.workoutSessions).get(), hasLength(1));
      expect((await db.select(db.workoutSessions).getSingle()).id, sessaoA);

      await _finish(tester, db);
    });

    testWidgets('"Descartar e iniciar este" cancela o atual e abre o novo',
        (tester) async {
      final db = _memoryDb();
      final (treinoB, sessaoA) = await prepara(db);

      await _pump(tester, db, treinoB);
      await tester.tap(find.text('INICIAR TREINO'));
      await _aguardar(tester);
      await tester.tap(find.text('DESCARTAR E INICIAR ESTE'));
      await _aguardar(tester);

      expect(find.text('Treino B'), findsOneWidget);
      final sessoes = await db.select(db.workoutSessions).get();
      expect(sessoes, hasLength(2));
      expect(sessoes.firstWhere((s) => s.id == sessaoA).status,
          WorkoutSessionStatus.cancelado);
      expect(sessoes.where((s) => s.status == WorkoutSessionStatus.emAndamento),
          hasLength(1));

      await _finish(tester, db);
    });

    testWidgets('"Voltar" não cria nem descarta nada', (tester) async {
      final db = _memoryDb();
      final (treinoB, sessaoA) = await prepara(db);

      await _pump(tester, db, treinoB);
      await tester.tap(find.text('INICIAR TREINO'));
      await _aguardar(tester);
      await tester.tap(find.text('VOLTAR').last);
      await _aguardar(tester);

      final sessoes = await db.select(db.workoutSessions).get();
      expect(sessoes, hasLength(1));
      expect(sessoes.single.id, sessaoA);
      expect(sessoes.single.status, WorkoutSessionStatus.emAndamento);

      await _finish(tester, db);
    });
  });

  testWidgets(
      'treino esquecido há dias estima a duração pela última série (não pelos dias parados)',
      (tester) async {
    final db = _memoryDb();
    final ex = await _exercicio(db, 'Supino reto');
    final treinoId = await _treino(db, 'Treino A', [ex]);
    final inicio = DateTime.now().subtract(const Duration(days: 2));
    final sessaoId = await db.into(db.workoutSessions).insert(
          WorkoutSessionsCompanion.insert(
            templateId: Value(treinoId),
            nome: 'Treino A',
            status: WorkoutSessionStatus.emAndamento,
            data: Value(inicio),
          ),
        );
    await db.into(db.setEntries).insert(SetEntriesCompanion.insert(
          sessionId: sessaoId,
          exerciseId: ex,
          serie: 1,
          repeticoes: 10,
          carga: 30,
          volume: 300,
          data: Value(inicio.add(const Duration(hours: 1))),
        ));

    await _pump(tester, db, treinoId);
    await tester.tap(find.text('INICIAR TREINO'));
    await _aguardar(tester);

    // 1h até a última série, não ~48h.
    expect(find.textContaining('DURAÇÃO: 1:00:'), findsOneWidget);

    await _finish(tester, db);
  });
}

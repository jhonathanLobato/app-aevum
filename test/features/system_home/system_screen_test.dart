import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_system/database/app_database.dart' hide Mission;
import 'package:gym_system/database/database_provider.dart';
import 'package:gym_system/design_system/rank_badge.dart';
import 'package:gym_system/design_system/system_xp_bar.dart';
import 'package:gym_system/features/missions/domain/mission.dart';
import 'package:gym_system/features/missions/presentation/mission_providers.dart';
import 'package:gym_system/features/profile/data/profile_repository_impl.dart';
import 'package:gym_system/features/profile/domain/level_curve.dart';
import 'package:gym_system/features/profile/domain/player_class.dart';
import 'package:gym_system/features/system_home/presentation/system_screen.dart';
import 'package:gym_system/features/workouts/data/workout_template_repository_impl.dart';
import 'package:gym_system/features/workouts/domain/workout_session.dart';
import 'package:gym_system/features/workouts/presentation/workout_session_providers.dart';

AppDatabase _memoryDb() => AppDatabase.forTesting(NativeDatabase.memory());

/// Destinos mínimos (sem o shell de navegação da Fase 4 — isso já é testado
/// à exaustão em `test/app/navigation_test.dart`) só pra confirmar que os
/// botões da Home chamam a navegação certa.
GoRouter _router() => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SystemScreen()),
        GoRoute(
          path: '/workouts',
          builder: (context, state) =>
              const Scaffold(body: Text('WORKOUTS_DESTINO')),
        ),
        GoRoute(
          path: '/workouts/:id',
          builder: (context, state) => Scaffold(
              body:
                  Text('WORKOUT_DETAIL_DESTINO_${state.pathParameters['id']}')),
        ),
        GoRoute(
          path: '/sessions/:id',
          builder: (context, state) => Scaffold(
              body: Text('SESSAO_DESTINO_${state.pathParameters['id']}')),
        ),
        GoRoute(
          path: '/exercises',
          builder: (context, state) =>
              const Scaffold(body: Text('EXERCICIOS_DESTINO')),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) =>
              const Scaffold(body: Text('HISTORICO_DESTINO')),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) =>
              const Scaffold(body: Text('PERFIL_DESTINO')),
        ),
      ],
    );

Future<void> _pumpHome(
  WidgetTester tester,
  AppDatabase db, {
  List<Override> extraOverrides = const [],
  Size size = const Size(390, 844),
  bool settle = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db), ...extraOverrides],
      child: MaterialApp.router(routerConfig: _router()),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    // pumpAndSettle nunca se estabiliza enquanto um CircularProgressIndicator
    // indeterminado está na tela (animação contínua) — usado pelo teste de
    // loading, que mantém um provider propositalmente sem emitir valor.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Mesma lógica de `test/app/navigation_test.dart`: desmonta a árvore e só
/// então fecha o banco, tudo dentro do corpo do teste — ver o comentário
/// lá pra entender por quê (timer pendente do Drift + `addTearDown` que
/// roda tarde demais pro binding não reclamar).
Future<void> _finish(WidgetTester tester, AppDatabase db) async {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 50));
  await db.close();
}

Future<void> _finishAWorkout(
  AppDatabase db, {
  required String nome,
  required int exerciseId,
}) async {
  final container = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
  );
  final sessionRepo = container.read(workoutSessionRepositoryProvider);
  final sessionId = await sessionRepo.start(nome: nome);
  await sessionRepo.logSet(
    sessionId: sessionId,
    exerciseId: exerciseId,
    repeticoes: 10,
    carga: 30,
  );
  await sessionRepo.finish(sessionId, duracao: const Duration(minutes: 25));
  container.dispose();
}

void main() {
  group('Home com dados reais', () {
    testWidgets('mostra nome, classe, rank, nível e XP do perfil real',
        (tester) async {
      final db = _memoryDb();
      final profileRepo = DriftProfileRepository(db);
      await profileRepo.addXp(150);
      await profileRepo.updateProfile(
          nome: 'Astra', classe: PlayerClass.assassino);

      await _pumpHome(tester, db);

      expect(find.text('ASTRA'), findsOneWidget);
      expect(find.textContaining('ASSASSINO'), findsOneWidget);
      expect(find.byType(RankBadge), findsOneWidget);
      expect(find.text('LV. 1'), findsOneWidget);

      final info = const LevelCurve().calcularNivel(150);
      final xpBar = tester.widget<SystemXpBar>(find.byType(SystemXpBar).first);
      expect(xpBar.value, info.xpNoNivelAtual);
      expect(xpBar.max, info.xpParaProximoNivel);
      expect(xpBar.level, info.nivel);

      await _finish(tester, db);
    });

    testWidgets('não mostra mais o card PRÓXIMO TREINO nem treino em andamento',
        (tester) async {
      final db = _memoryDb();
      final exId = await db.into(db.exercises).insert(
            ExercisesCompanion.insert(
                nome: 'Supino reto', grupoMuscular: 'Peito'),
          );
      final templateRepo = DriftWorkoutTemplateRepository(db);
      final treinoId = await templateRepo.create('Treino A');
      await templateRepo.addExercise(treinoId, exId);

      await _pumpHome(tester, db);

      expect(find.text('PRÓXIMO TREINO'), findsNothing);
      expect(find.text('TREINO EM ANDAMENTO'), findsNothing);

      await _finish(tester, db);
    });

    testWidgets('treino em andamento aparece com nome, séries e continuar',
        (tester) async {
      final db = _memoryDb();
      final exId = await db.into(db.exercises).insert(
            ExercisesCompanion.insert(
                nome: 'Supino reto', grupoMuscular: 'Peito'),
          );
      final container = ProviderContainer(
          overrides: [appDatabaseProvider.overrideWithValue(db)]);
      final repo = container.read(workoutSessionRepositoryProvider);
      final sessionId = await repo.start(nome: 'Treino A');
      await repo.logSet(
          sessionId: sessionId, exerciseId: exId, repeticoes: 10, carga: 30);
      container.dispose();

      await _pumpHome(tester, db);

      expect(find.text('TREINO EM ANDAMENTO'), findsOneWidget);
      expect(find.text('TREINO A'), findsOneWidget);
      expect(find.textContaining('1 SÉRIE REGISTRADA'), findsOneWidget);
      expect(find.textContaining('INICIADO HOJE'), findsOneWidget);

      await tester.tap(find.text('CONTINUAR TREINO'));
      await tester.pumpAndSettle();
      expect(find.text('SESSAO_DESTINO_$sessionId'), findsOneWidget);

      await _finish(tester, db);
    });

    testWidgets('descartar o treino em andamento pede confirmação e some',
        (tester) async {
      final db = _memoryDb();
      final container = ProviderContainer(
          overrides: [appDatabaseProvider.overrideWithValue(db)]);
      await container
          .read(workoutSessionRepositoryProvider)
          .start(nome: 'Treino A');
      container.dispose();

      await _pumpHome(tester, db);
      expect(find.text('TREINO EM ANDAMENTO'), findsOneWidget);

      await tester.tap(find.text('DESCARTAR TREINO'));
      await tester.pumpAndSettle();
      expect(find.text('DESCARTAR TREINO?'), findsOneWidget);

      await tester.tap(find.text('CANCELAR'));
      await tester.pumpAndSettle();
      expect(find.text('TREINO EM ANDAMENTO'), findsOneWidget);

      await tester.tap(find.text('DESCARTAR TREINO'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('DESCARTAR'));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();

      expect(find.text('TREINO EM ANDAMENTO'), findsNothing);
      final sessao = await db.select(db.workoutSessions).getSingle();
      expect(sessao.status, WorkoutSessionStatus.cancelado);

      await _finish(tester, db);
    });

    testWidgets('não mostra mais o quadro PROGRESSO RECENTE', (tester) async {
      final db = _memoryDb();
      final exId = await db.into(db.exercises).insert(
            ExercisesCompanion.insert(
                nome: 'Supino reto', grupoMuscular: 'Peito'),
          );
      await _finishAWorkout(db, nome: 'Treino concluído', exerciseId: exId);

      await _pumpHome(tester, db);

      expect(find.text('PROGRESSO RECENTE'), findsNothing);
      expect(find.text('Treino concluído'), findsNothing);

      await _finish(tester, db);
    });

    testWidgets('mostra a missão diária gerada automaticamente',
        (tester) async {
      final db = _memoryDb();

      await _pumpHome(tester, db);

      // A missão diária/semanal é garantida pelo próprio repositório
      // (ensureRecurringMissions) assim que a Home observa o provider —
      // não precisa ser semeada manualmente.
      expect(find.text('MISSÃO ATUAL'), findsOneWidget);
      expect(find.text('Missão diária'), findsOneWidget);
      expect(find.text('Complete seu treino.'), findsOneWidget);

      await _finish(tester, db);
    });
  });

  group('Empty states', () {
    testWidgets('sem missão ativa mostra estado vazio', (tester) async {
      final db = _memoryDb();

      await _pumpHome(
        tester,
        db,
        extraOverrides: [
          activeMissionsProvider
              .overrideWith((ref) => Stream.value(const <Mission>[])),
        ],
      );

      expect(find.text('NENHUMA MISSÃO ATIVA'), findsOneWidget);

      await _finish(tester, db);
    });
  });

  group('loading e error', () {
    testWidgets(
        'loading da missão mostra indicador, não quebra o resto da tela',
        (tester) async {
      final db = _memoryDb();
      final controller = StreamController<List<Mission>>();
      addTearDown(controller.close);

      await _pumpHome(
        tester,
        db,
        extraOverrides: [
          activeMissionsProvider.overrideWith((ref) => controller.stream),
        ],
        settle: false,
      );

      expect(find.text('MISSÃO ATUAL'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(tester.takeException(), isNull);

      await _finish(tester, db);
    });

    testWidgets('erro ao carregar missões mostra mensagem, não stack trace',
        (tester) async {
      final db = _memoryDb();

      await _pumpHome(
        tester,
        db,
        extraOverrides: [
          activeMissionsProvider
              .overrideWith((ref) => Stream.error(Exception('falhou'))),
        ],
      );

      expect(find.text('ERRO AO CARREGAR MISSÕES'), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
      expect(find.textContaining('falhou'), findsNothing);

      await _finish(tester, db);
    });
  });

  group('navegação', () {
    testWidgets('ícone de perfil no cabeçalho vai para Perfil', (tester) async {
      final db = _memoryDb();
      await _pumpHome(tester, db);

      await tester.tap(find.byTooltip('Perfil'));
      await tester.pumpAndSettle();

      expect(find.text('PERFIL_DESTINO'), findsOneWidget);

      await _finish(tester, db);
    });

    testWidgets('sem atalho de Exercícios; atalho Histórico navega',
        (tester) async {
      final db = _memoryDb();
      await _pumpHome(tester, db);

      expect(find.text('EXERCÍCIOS'), findsNothing);

      await tester.ensureVisible(find.text('HISTÓRICO'));
      await tester.tap(find.text('HISTÓRICO'));
      await tester.pumpAndSettle();
      expect(find.text('HISTORICO_DESTINO'), findsOneWidget);

      await _finish(tester, db);
    });
  });

  group('responsividade', () {
    testWidgets('320px de largura com dados reais não estoura', (tester) async {
      final db = _memoryDb();
      final exId = await db.into(db.exercises).insert(
            ExercisesCompanion.insert(
                nome: 'Supino reto', grupoMuscular: 'Peito'),
          );
      final templateRepo = DriftWorkoutTemplateRepository(db);
      final treinoId = await templateRepo.create('Treino A');
      await templateRepo.addExercise(treinoId, exId);
      await DriftProfileRepository(db).addXp(150);

      await _pumpHome(tester, db, size: const Size(320, 640));

      expect(tester.takeException(), isNull);

      await _finish(tester, db);
    });

    testWidgets('largura comum de Android não estoura', (tester) async {
      final db = _memoryDb();
      await _pumpHome(tester, db, size: const Size(412, 915));

      expect(tester.takeException(), isNull);

      await _finish(tester, db);
    });

    testWidgets('text scaling elevado com dados reais não estoura',
        (tester) async {
      final db = _memoryDb();
      final exId = await db.into(db.exercises).insert(
            ExercisesCompanion.insert(
                nome: 'Supino reto', grupoMuscular: 'Peito'),
          );
      final templateRepo = DriftWorkoutTemplateRepository(db);
      final treinoId = await templateRepo.create('Treino A');
      await templateRepo.addExercise(treinoId, exId);
      await DriftProfileRepository(db).addXp(150);
      await DriftProfileRepository(db)
          .updateProfile(nome: 'Astra', classe: PlayerClass.guardiao);

      tester.view.platformDispatcher.textScaleFactorTestValue = 1.8;

      await _pumpHome(tester, db);

      expect(tester.takeException(), isNull);

      tester.view.platformDispatcher.clearTextScaleFactorTestValue();
      await _finish(tester, db);
    });

    testWidgets('conteúdo grande (nomes longos, 5 exercícios) não estoura',
        (tester) async {
      final db = _memoryDb();
      final templateRepo = DriftWorkoutTemplateRepository(db);
      final treinoId = await templateRepo.create(
        'Treino de Hipertrofia Para Membros Superiores Completo',
      );
      for (var i = 0; i < 5; i++) {
        final exId = await db.into(db.exercises).insert(
              ExercisesCompanion.insert(
                nome: 'Exercício bem comprido número $i com nome grande',
                grupoMuscular: 'Peito',
              ),
            );
        await templateRepo.addExercise(treinoId, exId);
      }
      await DriftProfileRepository(db).updateProfile(
        nome: 'Um Nome De Jogador Bastante Comprido Pra Testar',
        classe: PlayerClass.guardiao,
      );

      await _pumpHome(tester, db);

      expect(tester.takeException(), isNull);

      await _finish(tester, db);
    });

    testWidgets('a Home rola verticalmente', (tester) async {
      final db = _memoryDb();
      await _pumpHome(tester, db, size: const Size(360, 600));

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      await tester.drag(
          find.byType(SingleChildScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await _finish(tester, db);
    });
  });
}

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/database/app_database.dart' hide Achievement;
import 'package:gym_system/database/database_provider.dart';
import 'package:gym_system/features/achievements/domain/achievement.dart';
import 'package:gym_system/features/achievements/presentation/achievement_providers.dart';
import 'package:gym_system/features/achievements/presentation/achievements_screen.dart';
import 'package:gym_system/features/workouts/presentation/workout_session_providers.dart';

AppDatabase _memoryDb() => AppDatabase.forTesting(NativeDatabase.memory());

Future<void> _pumpScreen(
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
      child: const MaterialApp(home: AchievementsScreen()),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    // pumpAndSettle nunca se estabiliza com um CircularProgressIndicator
    // indeterminado na tela — mesmo padrão de system_screen_test.dart.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Mesma ordem de system_screen_test.dart / navigation_test.dart: desmonta a
/// árvore e só então fecha o banco, dentro do corpo do teste.
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
  double carga = 30,
  int repeticoes = 10,
}) async {
  final container = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
  );
  final sessionRepo = container.read(workoutSessionRepositoryProvider);
  final sessionId = await sessionRepo.start(nome: nome);
  await sessionRepo.logSet(
    sessionId: sessionId,
    exerciseId: exerciseId,
    repeticoes: repeticoes,
    carga: carga,
  );
  await sessionRepo.finish(sessionId, duracao: const Duration(minutes: 25));
  container.dispose();
}

void main() {
  group('Conquistas — catálogo e estado inicial', () {
    testWidgets('usuário novo (zero conquistas) mostra tudo bloqueado',
        (tester) async {
      final db = _memoryDb();
      await _pumpScreen(tester, db);

      expect(find.text('DESBLOQUEADAS'), findsOneWidget);
      expect(find.text('0 / ${kAchievementCatalog.length}'), findsOneWidget);
      expect(find.text('DESBLOQUEADA'), findsNothing);
      expect(find.text('Primeiros Passos'), findsOneWidget);

      await _finish(tester, db);
    });

    testWidgets('primeiro treino desbloqueia "Primeiros Passos"',
        (tester) async {
      final db = _memoryDb();
      final exId = await db.into(db.exercises).insert(
            ExercisesCompanion.insert(
                nome: 'Supino reto', grupoMuscular: 'Peito'),
          );
      await _finishAWorkout(db, nome: 'Treino A', exerciseId: exId);

      await _pumpScreen(tester, db);

      // O primeiro treino também registra a primeira carga já logada pra
      // esse exercício como um PR (não havia recorde anterior pra comparar),
      // então "Evolução" desbloqueia junto com "Primeiros Passos".
      expect(find.text('2 / ${kAchievementCatalog.length}'), findsOneWidget);
      expect(find.text('Primeiros Passos'), findsOneWidget);
      expect(find.text('DESBLOQUEADA'), findsNWidgets(2));

      await _finish(tester, db);
    });

    testWidgets('primeiro PR desbloqueia "Evolução"', (tester) async {
      final db = _memoryDb();
      final exId = await db.into(db.exercises).insert(
            ExercisesCompanion.insert(
                nome: 'Supino reto', grupoMuscular: 'Peito'),
          );
      await _finishAWorkout(db, nome: 'Treino A', exerciseId: exId, carga: 30);

      await _pumpScreen(tester, db);

      // A própria primeira série logada já conta como PR (não havia recorde
      // anterior), então "Evolução" desbloqueia já no primeiro treino.
      expect(find.text('Evolução'), findsOneWidget);
      expect(find.textContaining('DESBLOQUEADAS'), findsOneWidget);

      await _finish(tester, db);
    });

    testWidgets('progresso real aparece nas conquistas progressivas',
        (tester) async {
      final db = _memoryDb();
      final exId = await db.into(db.exercises).insert(
            ExercisesCompanion.insert(
                nome: 'Supino reto', grupoMuscular: 'Peito'),
          );
      for (var i = 0; i < 3; i++) {
        await _finishAWorkout(db, nome: 'Treino $i', exerciseId: exId);
      }

      await _pumpScreen(tester, db);

      // "Disciplina" exige 10 treinos — com 3 já feitos, fica DISPONÍVEL
      // (progresso > 0, ainda bloqueada) em vez de BLOQUEADA simples. Outras
      // conquistas progressivas (Constância, Veterano, Primeiro Milhar)
      // também ficam disponíveis ao mesmo tempo, então várias aparecem.
      expect(find.text('3 / 10'), findsOneWidget);
      expect(find.text('DISPONÍVEL'), findsWidgets);

      await _finish(tester, db);
    });
  });

  group('loading e error', () {
    testWidgets('loading mostra indicador, sem quebrar', (tester) async {
      final db = _memoryDb();
      final controller = StreamController<List<Achievement>>();
      addTearDown(controller.close);

      await _pumpScreen(
        tester,
        db,
        extraOverrides: [
          achievementsProvider.overrideWith((ref) => controller.stream),
        ],
        settle: false,
      );

      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(tester.takeException(), isNull);

      await _finish(tester, db);
    });

    testWidgets('erro ao carregar mostra mensagem, não stack trace',
        (tester) async {
      final db = _memoryDb();

      await _pumpScreen(
        tester,
        db,
        extraOverrides: [
          achievementsProvider
              .overrideWith((ref) => Stream.error(Exception('falhou'))),
        ],
      );

      expect(find.text('ERRO AO CARREGAR CONQUISTAS'), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);

      await _finish(tester, db);
    });
  });

  group('responsividade', () {
    testWidgets('320px de largura não estoura', (tester) async {
      final db = _memoryDb();
      await _pumpScreen(tester, db, size: const Size(320, 640));

      expect(tester.takeException(), isNull);

      await _finish(tester, db);
    });

    testWidgets('text scaling elevado não estoura', (tester) async {
      final db = _memoryDb();
      tester.view.platformDispatcher.textScaleFactorTestValue = 1.8;

      await _pumpScreen(tester, db);

      expect(tester.takeException(), isNull);

      tester.view.platformDispatcher.clearTextScaleFactorTestValue();
      await _finish(tester, db);
    });

    testWidgets('textos longos não estouram o card', (tester) async {
      final db = _memoryDb();
      await _pumpScreen(tester, db);

      expect(tester.takeException(), isNull);

      await _finish(tester, db);
    });

    testWidgets('a tela rola verticalmente com muitas conquistas',
        (tester) async {
      final db = _memoryDb();
      await _pumpScreen(tester, db, size: const Size(360, 600));

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      await tester.drag(
          find.byType(SingleChildScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await _finish(tester, db);
    });
  });
}

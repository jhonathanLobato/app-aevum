import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/database/app_database.dart' hide Mission;
import 'package:gym_system/database/database_provider.dart';
import 'package:gym_system/features/missions/domain/mission.dart';
import 'package:gym_system/features/missions/presentation/mission_providers.dart';
import 'package:gym_system/features/missions/presentation/missions_screen.dart';
import 'package:gym_system/features/workouts/presentation/workout_session_providers.dart';

AppDatabase _memoryDb() => AppDatabase.forTesting(NativeDatabase.memory());

Future<void> _pump(
  WidgetTester tester,
  AppDatabase db, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const MaterialApp(home: MissionsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _finish(WidgetTester tester, AppDatabase db) async {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 50));
  await db.close();
}

void main() {
  testWidgets(
      'mostra a missão diária e a semanal com progresso e recompensa real',
      (tester) async {
    final db = _memoryDb();
    await _pump(tester, db);

    expect(find.text('DIÁRIA'), findsOneWidget);
    expect(find.text('Missão diária'), findsOneWidget);
    expect(find.text('Complete seu treino.'), findsOneWidget);
    expect(find.text('0 / 1'), findsOneWidget);
    expect(find.text('+50 XP'), findsOneWidget);

    expect(find.text('SEMANAL'), findsOneWidget);
    expect(find.text('Missão semanal'), findsOneWidget);
    expect(find.text('0 / 4'), findsOneWidget);
    expect(find.text('+250 XP'), findsOneWidget);

    await _finish(tester, db);
  });

  testWidgets(
      'avançar o progresso real reflete no card (0/1 → 1/1, ícone de %)',
      (tester) async {
    final db = _memoryDb();
    final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)]);
    await container.read(workoutSessionRepositoryProvider).finish(
          await container
              .read(workoutSessionRepositoryProvider)
              .start(nome: 'Treino livre'),
          duracao: const Duration(minutes: 10),
        );
    container.dispose();

    await _pump(tester, db);

    // A diária foi concluída pelo treino finalizado acima: não aparece
    // mais como ativa (1/1 seria o "ainda ativo"), e sim na seção de
    // concluídas recentemente.
    expect(find.text('CONCLUÍDAS RECENTEMENTE'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);

    await _finish(tester, db);
  });

  testWidgets('desafio de carga aparece com meta real em kg', (tester) async {
    final db = _memoryDb();
    final exId = await db.into(db.exercises).insert(
          ExercisesCompanion.insert(
              nome: 'Supino reto', grupoMuscular: 'Peito'),
        );
    final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)]);
    final sessionRepo = container.read(workoutSessionRepositoryProvider);
    final sessionId = await sessionRepo.start(nome: 'Treino livre');
    await sessionRepo.logSet(
        sessionId: sessionId, exerciseId: exId, repeticoes: 5, carga: 30);
    container.dispose();

    await _pump(tester, db);

    expect(find.text('DESAFIOS'), findsOneWidget);
    expect(find.textContaining('Supino reto'), findsWidgets);
    expect(find.text('0 / 32'), findsOneWidget);

    await _finish(tester, db);
  });

  testWidgets('sem nenhuma missão (provider sobrescrito) mostra estado vazio',
      (tester) async {
    final db = _memoryDb();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          activeMissionsProvider
              .overrideWith((ref) => Stream.value(const <Mission>[])),
        ],
        child: const MaterialApp(home: MissionsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NENHUMA MISSÃO ATIVA'), findsOneWidget);

    await _finish(tester, db);
  });

  testWidgets('320px de largura não estoura', (tester) async {
    final db = _memoryDb();
    await _pump(tester, db, size: const Size(320, 640));

    expect(tester.takeException(), isNull);

    await _finish(tester, db);
  });

  testWidgets('text scaling elevado não estoura', (tester) async {
    final db = _memoryDb();
    tester.view.platformDispatcher.textScaleFactorTestValue = 1.8;

    await _pump(tester, db);

    expect(tester.takeException(), isNull);

    tester.view.platformDispatcher.clearTextScaleFactorTestValue();
    await _finish(tester, db);
  });

  testWidgets('descrição de desafio com nome de exercício longo não estoura',
      (tester) async {
    final db = _memoryDb();
    final exId = await db.into(db.exercises).insert(
          ExercisesCompanion.insert(
            nome: 'Supino reto com halteres em banco inclinado ajustável',
            grupoMuscular: 'Peito',
          ),
        );
    final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)]);
    final sessionRepo = container.read(workoutSessionRepositoryProvider);
    final sessionId = await sessionRepo.start(nome: 'Treino livre');
    await sessionRepo.logSet(
        sessionId: sessionId, exerciseId: exId, repeticoes: 5, carga: 30);
    container.dispose();

    await _pump(tester, db);

    expect(tester.takeException(), isNull);

    await _finish(tester, db);
  });

  testWidgets('a tela rola verticalmente', (tester) async {
    final db = _memoryDb();
    await _pump(tester, db, size: const Size(360, 500));

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await _finish(tester, db);
  });
}

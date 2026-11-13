import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/database/app_database.dart';
import 'package:gym_system/database/database_provider.dart';
import 'package:gym_system/design_system/rank_badge.dart';
import 'package:gym_system/features/profile/data/profile_repository_impl.dart';
import 'package:gym_system/features/profile/domain/player_class.dart';
import 'package:gym_system/features/statistics/domain/statistics.dart';
import 'package:gym_system/features/statistics/presentation/statistics_providers.dart';
import 'package:gym_system/features/statistics/presentation/statistics_screen.dart';
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
      child: const MaterialApp(home: StatisticsScreen()),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }
}

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
  group('Status — identidade e atributos', () {
    testWidgets('usuário novo mostra identidade real e atributos zerados',
        (tester) async {
      final db = _memoryDb();
      await DriftProfileRepository(db)
          .updateProfile(nome: 'Astra', classe: PlayerClass.guerreiro);

      await _pumpScreen(tester, db);

      // A identidade (nome/rank/nível) fica na tela Sistema, não aqui.
      expect(find.text('ASTRA'), findsNothing);
      expect(find.byType(RankBadge), findsNothing);
      expect(find.text('RELATÓRIO SEMANAL'), findsOneWidget);
      expect(find.text('ATRIBUTOS'), findsOneWidget);
      expect(find.text('FORÇA'), findsOneWidget);
      expect(find.text('RESISTÊNCIA'), findsOneWidget);
      expect(find.text('CONSTÂNCIA'), findsOneWidget);
      // Sem nenhum treino, os 3 atributos (e as estatísticas globais) ficam
      // todos em 0 (ver PlayerAttributesCalculator) — '0' aparece várias
      // vezes na tela, então só confirmamos que aparece, não a contagem.
      expect(find.text('0'), findsWidgets);

      await _finish(tester, db);
    });

    testWidgets('treino registrado reflete nas estatísticas globais',
        (tester) async {
      final db = _memoryDb();
      final exId = await db.into(db.exercises).insert(
            ExercisesCompanion.insert(
                nome: 'Supino reto', grupoMuscular: 'Peito'),
          );
      await _finishAWorkout(db, nome: 'Treino A', exerciseId: exId);

      await _pumpScreen(tester, db);

      expect(find.text('TREINOS'), findsWidgets);
      // SystemStatBox sempre renderiza o rótulo em maiúsculas.
      expect(find.text('PRS'), findsOneWidget);
      expect(find.text('VOLUME'), findsOneWidget);
      expect(find.textContaining('KG'), findsWidgets);

      await _finish(tester, db);
    });

    testWidgets('detalhes por exercício aparecem quando há histórico',
        (tester) async {
      final db = _memoryDb();
      final exId = await db.into(db.exercises).insert(
            ExercisesCompanion.insert(
                nome: 'Supino reto', grupoMuscular: 'Peito'),
          );
      await _finishAWorkout(db, nome: 'Treino A', exerciseId: exId);

      await _pumpScreen(tester, db);

      expect(find.text('DETALHES POR EXERCÍCIO'), findsOneWidget);
      expect(find.text('Supino reto'), findsOneWidget);

      await _finish(tester, db);
    });

    testWidgets('sem exercícios registrados mostra estado vazio nos detalhes',
        (tester) async {
      final db = _memoryDb();
      await _pumpScreen(tester, db);

      expect(find.text('NENHUM EXERCÍCIO REGISTRADO AINDA'), findsOneWidget);

      await _finish(tester, db);
    });
  });

  group('loading e error', () {
    testWidgets('loading das estatísticas globais mostra indicador',
        (tester) async {
      final db = _memoryDb();
      final controller = StreamController<GlobalStatistics>();
      addTearDown(controller.close);

      await _pumpScreen(
        tester,
        db,
        extraOverrides: [
          globalStatisticsProvider.overrideWith((ref) => controller.stream),
        ],
        settle: false,
      );

      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(tester.takeException(), isNull);

      await _finish(tester, db);
    });

    testWidgets(
        'erro ao carregar estatísticas mostra mensagem, não stack trace',
        (tester) async {
      final db = _memoryDb();

      await _pumpScreen(
        tester,
        db,
        extraOverrides: [
          globalStatisticsProvider
              .overrideWith((ref) => Stream.error(Exception('falhou'))),
        ],
      );

      expect(find.text('ERRO AO CARREGAR ESTATÍSTICAS'), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);

      await _finish(tester, db);
    });
  });

  group('responsividade', () {
    testWidgets('320px de largura não estoura', (tester) async {
      final db = _memoryDb();
      final exId = await db.into(db.exercises).insert(
            ExercisesCompanion.insert(
                nome: 'Supino reto', grupoMuscular: 'Peito'),
          );
      await _finishAWorkout(db, nome: 'Treino A', exerciseId: exId);
      await DriftProfileRepository(db)
          .updateProfile(nome: 'Astra', classe: PlayerClass.guardiao);

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

    testWidgets('nome de jogador longo não estoura', (tester) async {
      final db = _memoryDb();
      await DriftProfileRepository(db).updateProfile(
        nome: 'Um Nome De Jogador Bastante Comprido Pra Testar',
        classe: PlayerClass.guardiao,
      );

      await _pumpScreen(tester, db);

      expect(tester.takeException(), isNull);

      await _finish(tester, db);
    });

    testWidgets('muitos exercícios registrados não estouram o layout',
        (tester) async {
      final db = _memoryDb();
      for (var i = 0; i < 8; i++) {
        final exId = await db.into(db.exercises).insert(
              ExercisesCompanion.insert(
                nome: 'Exercício bem comprido número $i com nome grande',
                grupoMuscular: 'Peito',
              ),
            );
        await _finishAWorkout(db, nome: 'Treino $i', exerciseId: exId);
      }

      await _pumpScreen(tester, db);

      expect(tester.takeException(), isNull);

      await _finish(tester, db);
    });

    testWidgets('a tela rola verticalmente', (tester) async {
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

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_system/database/app_database.dart';
import 'package:gym_system/database/database_provider.dart';
import 'package:gym_system/features/achievements/data/achievement_repository_impl.dart';
import 'package:gym_system/features/exercises/presentation/exercise_history_screen.dart';
import 'package:gym_system/features/missions/data/mission_repository_impl.dart';
import 'package:gym_system/features/profile/data/profile_repository_impl.dart';
import 'package:gym_system/features/progression/data/personal_record_repository_impl.dart';
import 'package:gym_system/features/workouts/data/workout_session_repository_impl.dart';
import 'package:gym_system/features/workouts/presentation/active_workout_screen.dart';
import 'package:gym_system/features/workouts/presentation/workout_history_screen.dart';

void main() {
  testWidgets('lista treinos finalizados e expande o detalhe ao tocar',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final exercicioId = await db.into(db.exercises).insert(
          ExercisesCompanion.insert(
              nome: 'Supino reto', grupoMuscular: 'Peito'),
        );
    final sessionRepo = DriftWorkoutSessionRepository(
      db,
      DriftPersonalRecordRepository(db),
      DriftProfileRepository(db),
      DriftMissionRepository(db),
      DriftAchievementRepository(db),
    );
    final sessionId = await sessionRepo.start(nome: 'Treino livre');
    await sessionRepo.logSet(
        sessionId: sessionId,
        exerciseId: exercicioId,
        repeticoes: 10,
        carga: 30);
    await sessionRepo.finish(sessionId, duracao: const Duration(minutes: 5));

    final router = GoRouter(
      initialLocation: '/history',
      routes: [
        GoRoute(
          path: '/history',
          builder: (context, state) => const WorkoutHistoryScreen(),
        ),
        GoRoute(
          path: '/sessions/:id',
          builder: (context, state) => ActiveWorkoutScreen(
            sessionId: int.parse(state.pathParameters['id']!),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('TREINO LIVRE'), findsOneWidget);
    expect(find.text('EXERCÍCIOS'), findsOneWidget);
    expect(find.text('300 KG'), findsOneWidget);

    await tester.tap(find.text('TREINO LIVRE'));
    await tester.pumpAndSettle();

    expect(find.text('SUPINO RETO'), findsOneWidget);
    expect(find.text('30.0 KG × 10'), findsOneWidget);
    expect(find.text('FINALIZAR TREINO'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('mostra o histórico de um exercício com indicador de tendência',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final exercicioId = await db.into(db.exercises).insert(
          ExercisesCompanion.insert(
              nome: 'Supino reto', grupoMuscular: 'Peito'),
        );
    final sessionRepo = DriftWorkoutSessionRepository(
      db,
      DriftPersonalRecordRepository(db),
      DriftProfileRepository(db),
      DriftMissionRepository(db),
      DriftAchievementRepository(db),
    );

    final sessao1 = await sessionRepo.start(nome: 'Treino livre');
    await sessionRepo.logSet(
        sessionId: sessao1, exerciseId: exercicioId, repeticoes: 10, carga: 30);
    await sessionRepo.finish(sessao1, duracao: const Duration(minutes: 5));

    final sessao2 = await sessionRepo.start(nome: 'Treino livre');
    await sessionRepo.logSet(
        sessionId: sessao2, exerciseId: exercicioId, repeticoes: 10, carga: 32);
    await sessionRepo.finish(sessao2, duracao: const Duration(minutes: 5));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: ExerciseHistoryScreen(
            exerciseId: exercicioId,
            exerciseNome: 'Supino reto',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('10 × 30.0kg'), findsOneWidget);
    expect(find.text('10 × 32.0kg'), findsOneWidget);
    expect(find.byIcon(Icons.trending_up), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });
}

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_system/database/app_database.dart';
import 'package:gym_system/database/database_provider.dart';
import 'package:gym_system/features/workouts/data/workout_template_repository_impl.dart';
import 'package:gym_system/features/workouts/presentation/active_workout_screen.dart';
import 'package:gym_system/features/workouts/presentation/workout_template_detail_screen.dart';

void main() {
  testWidgets(
      'inicia um treino, registra uma série e finaliza, voltando pro detalhe do treino',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final exercicioId = await db.into(db.exercises).insert(
          ExercisesCompanion.insert(
              nome: 'Supino reto', grupoMuscular: 'Peito'),
        );
    final templateRepo = DriftWorkoutTemplateRepository(db);
    final treinoId = await templateRepo.create('Treino A');
    await templateRepo.addExercise(treinoId, exercicioId);

    final router = GoRouter(
      initialLocation: '/workouts/$treinoId',
      routes: [
        GoRoute(
          path: '/workouts/:id',
          builder: (context, state) => WorkoutTemplateDetailScreen(
            templateId: int.parse(state.pathParameters['id']!),
          ),
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

    await tester.tap(find.text('Iniciar treino'));
    await tester.pumpAndSettle();

    expect(find.text('Treino A'), findsOneWidget);
    expect(find.textContaining('Duração:'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Repetições'), '10');
    await tester.enterText(find.widgetWithText(TextField, 'Carga (kg)'), '30');
    await tester.tap(find.byIcon(Icons.check_circle_outline));
    await tester.pumpAndSettle();

    expect(find.text('Série 1: 10 × 30.0kg'), findsOneWidget);

    // A primeira série já é um PR: fecha o diálogo antes de continuar.
    expect(find.text('PR DETECTADO'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // O primeiro PR de todos também desbloqueia a conquista "Evolução".
    expect(find.text('CONQUISTA DESBLOQUEADA'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Finalizar treino'));
    await tester.pumpAndSettle();

    // Finalizar o primeiro treino do dia também bate a missão diária.
    expect(find.text('MISSÃO CONCLUÍDA'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // E desbloqueia a conquista "Primeiros Passos".
    expect(find.text('CONQUISTA DESBLOQUEADA'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Voltou para a tela de detalhe do treino (não mais a sessão ativa).
    expect(find.textContaining('Duração:'), findsNothing);
    expect(find.byIcon(Icons.check_circle_outline), findsNothing);
    expect(find.byIcon(Icons.drag_handle), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });
}

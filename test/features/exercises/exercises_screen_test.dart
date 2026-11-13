import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/database/app_database.dart';
import 'package:gym_system/database/database_provider.dart';
import 'package:gym_system/features/exercises/data/exercise_repository_impl.dart';
import 'package:gym_system/features/exercises/domain/exercise_repository.dart';
import 'package:gym_system/features/exercises/presentation/exercises_screen.dart';
import 'package:gym_system/features/progression/domain/personal_record.dart';

Finder _campo(String chave) => find.descendant(
    of: find.byKey(Key(chave)), matching: find.byType(TextField));

void main() {
  testWidgets('cria, edita e exclui um exercício', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: ExercisesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NENHUM EXERCÍCIO CADASTRADO'), findsOneWidget);

    await tester.tap(find.text('NOVO EXERCÍCIO'));
    await tester.pumpAndSettle();

    await tester.enterText(_campo('exercise_nome_field'), 'Supino reto');
    await tester.enterText(_campo('exercise_grupo_field'), 'Peito');
    await tester.tap(find.text('ADICIONAR'));
    await tester.pumpAndSettle();

    expect(find.text('SUPINO RETO'), findsOneWidget);
    expect(find.text('PEITO'), findsOneWidget);

    await tester.tap(find.text('SUPINO RETO'));
    await tester.pumpAndSettle();

    await tester.enterText(_campo('exercise_nome_field'), 'Supino inclinado');
    await tester.tap(find.text('SALVAR'));
    await tester.pumpAndSettle();

    expect(find.text('SUPINO INCLINADO'), findsOneWidget);
    expect(find.text('SUPINO RETO'), findsNothing);

    // Cancelar a confirmação mantém o exercício.
    await tester.tap(find.byTooltip('Excluir exercício'));
    await tester.pumpAndSettle();
    expect(find.text('EXCLUIR EXERCÍCIO?'), findsOneWidget);
    await tester.tap(find.text('CANCELAR'));
    await tester.pumpAndSettle();
    expect(find.text('SUPINO INCLINADO'), findsOneWidget);

    await tester.tap(find.byTooltip('Excluir exercício'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('EXCLUIR'));
    await tester.pumpAndSettle();

    expect(find.text('SUPINO INCLINADO'), findsNothing);
    expect(find.text('NENHUM EXERCÍCIO CADASTRADO'), findsOneWidget);

    // Desmonta a árvore explicitamente para que o timer de fechamento da
    // stream do Drift dispare antes do teardown do teste verificar timers.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('exercício em uso não é excluído e mostra uma mensagem',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final exId = await db.into(db.exercises).insert(
        ExercisesCompanion.insert(nome: 'Supino reto', grupoMuscular: 'Peito'));
    final treinoId = await db
        .into(db.workoutTemplates)
        .insert(WorkoutTemplatesCompanion.insert(nome: 'Treino A'));
    await db.into(db.workoutTemplateExercises).insert(
        WorkoutTemplateExercisesCompanion.insert(
            templateId: treinoId, exerciseId: exId, ordem: 0));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: ExercisesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Excluir exercício'));
    await tester.pumpAndSettle();

    expect(find.text('EXERCÍCIO EM USO'), findsOneWidget);
    expect(find.text('EXCLUIR EXERCÍCIO?'), findsNothing);
    await tester.tap(find.text('ENTENDI'));
    await tester.pumpAndSettle();

    expect(find.text('SUPINO RETO'), findsOneWidget);
    expect(await db.select(db.exercises).get(), hasLength(1));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets(
      'exercício com séries ou PRs registrados também conta como em uso',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = DriftExerciseRepository(db);
    final livre = await repo.create(nome: 'Rosca', grupoMuscular: 'Bíceps');
    final comPr = await repo.create(nome: 'Supino', grupoMuscular: 'Peito');
    await db.into(db.personalRecords).insert(PersonalRecordsCompanion.insert(
        exerciseId: comPr, tipo: PersonalRecordType.carga, valor: 40));

    expect(await repo.isInUse(livre), isFalse);
    expect(await repo.isInUse(comPr), isTrue);
    await expectLater(
        repo.delete(comPr), throwsA(isA<ExerciseInUseException>()));
    await repo.delete(livre);
    expect(await db.select(db.exercises).get(), hasLength(1));
  });

  testWidgets('não salva exercício com campos vazios e mostra o erro',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: ExercisesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('NOVO EXERCÍCIO'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ADICIONAR'));
    await tester.pumpAndSettle();

    expect(find.text('Informe o nome do exercício'), findsOneWidget);
    expect(find.text('Informe o grupo muscular'), findsOneWidget);
    expect(await db.select(db.exercises).get(), isEmpty);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });
}

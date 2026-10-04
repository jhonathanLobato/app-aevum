import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/database/app_database.dart';
import 'package:gym_system/database/database_provider.dart';
import 'package:gym_system/features/exercises/presentation/exercises_screen.dart';

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

    await tester.tap(find.byTooltip('Excluir exercício'));
    await tester.pumpAndSettle();

    expect(find.text('SUPINO INCLINADO'), findsNothing);
    expect(find.text('NENHUM EXERCÍCIO CADASTRADO'), findsOneWidget);

    // Desmonta a árvore explicitamente para que o timer de fechamento da
    // stream do Drift dispare antes do teardown do teste verificar timers.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
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

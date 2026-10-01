import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/database/app_database.dart';
import 'package:gym_system/database/database_provider.dart';
import 'package:gym_system/features/exercises/presentation/exercises_screen.dart';

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

    expect(find.text('Nenhum exercício cadastrado ainda.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome'), 'Supino reto');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Grupo muscular'), 'Peito');
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    expect(find.text('Supino reto'), findsOneWidget);
    expect(find.text('Peito'), findsOneWidget);

    await tester.tap(find.text('Supino reto'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome'), 'Supino inclinado');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Supino inclinado'), findsOneWidget);
    expect(find.text('Supino reto'), findsNothing);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('Supino inclinado'), findsNothing);
    expect(find.text('Nenhum exercício cadastrado ainda.'), findsOneWidget);

    // Desmonta a árvore explicitamente para que o timer de fechamento da
    // stream do Drift dispare antes do teardown do teste verificar timers.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });
}

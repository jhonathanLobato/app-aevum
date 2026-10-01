import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/database/app_database.dart';
import 'package:gym_system/database/database_provider.dart';
import 'package:gym_system/features/profile/presentation/profile_screen.dart';

void main() {
  testWidgets('edita nome, classe, título e tema, e salva', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Nome'), 'Ana');
    await tester.enterText(find.widgetWithText(TextField, 'Título'), 'Campeã');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Guardião'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.star));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Perfil salvo.'), findsOneWidget);

    final user = await db.select(db.users).getSingle();
    expect(user.nome, 'Ana');
    expect(user.titulo, 'Campeã');
    expect(user.avatar, 'star');

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });
}

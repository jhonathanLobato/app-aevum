import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/database/app_database.dart';
import 'package:gym_system/database/database_provider.dart';
import 'package:gym_system/features/profile/domain/player_class.dart';
import 'package:gym_system/features/profile/presentation/profile_screen.dart';

void main() {
  testWidgets('edita nome, avatar e classe, e salva a ficha', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
        find.descendant(
            of: find.byKey(const Key('profile_nome_field')),
            matching: find.byType(TextField)),
        'Ana');
    await tester.ensureVisible(find.text('GUARDIÃO'));
    await tester.tap(find.text('GUARDIÃO'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byIcon(Icons.star));
    await tester.tap(find.byIcon(Icons.star));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('profile_salvar')));
    await tester.tap(find.byKey(const Key('profile_salvar')));
    await tester.pumpAndSettle();

    expect(find.text('Ficha salva.'), findsOneWidget);

    final user = await db.select(db.users).getSingle();
    expect(user.nome, 'Ana');
    expect(user.titulo, 'Despertado');
    expect(user.avatar, 'star');
    expect(user.classe, PlayerClass.guardiao);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });
}

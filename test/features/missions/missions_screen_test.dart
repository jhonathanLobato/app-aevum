import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/database/app_database.dart';
import 'package:gym_system/database/database_provider.dart';
import 'package:gym_system/features/missions/presentation/missions_screen.dart';

void main() {
  testWidgets('mostra as missões diária e semanal com o progresso atual',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: MissionsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Missão diária'), findsOneWidget);
    expect(find.text('Complete seu treino.'), findsOneWidget);
    expect(find.text('0 / 1'), findsOneWidget);
    expect(find.text('Recompensa: +50 XP'), findsOneWidget);

    expect(find.text('Missão semanal'), findsOneWidget);
    expect(find.text('0 / 4'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });
}

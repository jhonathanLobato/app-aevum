import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/app/app.dart';
import 'package:gym_system/database/app_database.dart';
import 'package:gym_system/database/database_provider.dart';

void main() {
  testWidgets('abre a tela Sistema', (tester) async {
    // Banco em memória, como o resto da suíte (Fase 5 passou a observar
    // vários providers na Home — num banco real em arquivo, a E/S real
    // atrasa o primeiro valor o suficiente pra um `CircularProgressIndicator`
    // indeterminado ficar visível por um instante, e `pumpAndSettle` nunca
    // se estabiliza enquanto uma animação indeterminada está na tela).
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home_titulo')), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
    await db.close();
  });
}

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/database/app_database.dart';
import 'package:gym_system/database/database_provider.dart';
import 'package:gym_system/features/daily/presentation/daily_mission_screen.dart';
import 'package:gym_system/features/workouts/presentation/widgets/week_schedule_panel.dart';

AppDatabase _memoryDb() => AppDatabase.forTesting(NativeDatabase.memory());

Future<void> _pump(WidgetTester tester, AppDatabase db, Widget home,
    {Size size = const Size(390, 900)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp(home: home),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _finish(WidgetTester tester, AppDatabase db) async {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 50));
  await db.close();
}

Finder _campo(String chave) => find.descendant(
    of: find.byKey(Key(chave)), matching: find.byType(TextField));

Future<void> _tocar(WidgetTester tester, String chave) async {
  await tester.ensureVisible(find.byKey(Key(chave)));
  await tester.tap(find.byKey(Key(chave)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('botões +10/+25 somam, desfazer remove o último', (tester) async {
    final db = _memoryDb();
    await _pump(tester, db, const DailyMissionScreen());

    expect(find.text('MISSÃO DIÁRIA'), findsWidgets);
    expect(find.text('0 / 50'), findsNWidgets(2));

    await _tocar(tester, 'daily_flexoes_mais_10');
    await _tocar(tester, 'daily_flexoes_mais_25');
    expect(find.text('35 / 50'), findsOneWidget);

    await _tocar(tester, 'daily_flexoes_desfazer');
    expect(find.text('10 / 50'), findsOneWidget);

    await _finish(tester, db);
  });

  testWidgets('campo livre soma quantidade e km (aceita vírgula)',
      (tester) async {
    final db = _memoryDb();
    await _pump(tester, db, const DailyMissionScreen());

    await tester.enterText(_campo('daily_abdominais_campo'), '30');
    await _tocar(tester, 'daily_abdominais_registrar');
    expect(find.text('30 / 50'), findsOneWidget);

    await tester.enterText(_campo('daily_km_campo'), '1,5');
    await _tocar(tester, 'daily_km_registrar');
    expect(find.text('1,50 / 2 KM'), findsOneWidget);
    await tester.enterText(_campo('daily_km_campo'), '0.5');
    await _tocar(tester, 'daily_km_registrar');
    expect(find.text('2 / 2 KM'), findsOneWidget);

    await _finish(tester, db);
  });

  testWidgets('completar as 3 partes mostra missão cumprida e dá 50 XP',
      (tester) async {
    final db = _memoryDb();
    await _pump(tester, db, const DailyMissionScreen());

    await tester.enterText(_campo('daily_flexoes_campo'), '50');
    await _tocar(tester, 'daily_flexoes_registrar');
    await tester.enterText(_campo('daily_abdominais_campo'), '50');
    await _tocar(tester, 'daily_abdominais_registrar');
    expect(find.textContaining('MISSÃO CUMPRIDA'), findsNothing);
    await tester.enterText(_campo('daily_km_campo'), '2');
    await _tocar(tester, 'daily_km_registrar');

    expect(find.textContaining('MISSÃO CUMPRIDA'), findsWidgets);
    expect((await db.select(db.users).getSingle()).xp, 50);
    // Depois de concluída, os registros ficam travados.
    expect(tester.widget<TextField>(_campo('daily_flexoes_campo')).enabled,
        isFalse);

    await _finish(tester, db);
  });

  testWidgets('usar folga hoje marca o dia e libera desfazer', (tester) async {
    final db = _memoryDb();
    await _pump(tester, db, const DailyMissionScreen());

    await tester.ensureVisible(find.text('USAR FOLGA HOJE'));
    await tester.tap(find.text('USAR FOLGA HOJE'));
    await tester.pumpAndSettle();

    expect(find.textContaining('DIA DE FOLGA'), findsOneWidget);
    expect(find.text('FOLGAS: 1/4'), findsOneWidget);
    expect(find.text('DESFAZER FOLGA DE HOJE'), findsOneWidget);

    await _finish(tester, db);
  });

  testWidgets('320px de largura não estoura', (tester) async {
    final db = _memoryDb();
    await _pump(tester, db, const DailyMissionScreen(),
        size: const Size(320, 640));
    expect(tester.takeException(), isNull);
    await _finish(tester, db);
  });

  group('Minha semana (programação)', () {
    testWidgets('marcar dias de treino; os outros são descanso',
        (tester) async {
      final db = _memoryDb();
      await _pump(tester, db, const Scaffold(body: WeekSchedulePanel()));

      expect(find.text('0 TREINOS · 7 DESCANSOS'), findsOneWidget);

      for (final dia in [1, 3, 5]) {
        await tester.tap(find.byKey(Key('schedule_day_$dia')));
        await tester.pumpAndSettle();
      }
      expect(find.text('3 TREINOS · 4 DESCANSOS'), findsOneWidget);
      expect((await db.select(db.scheduleDays).get()).map((s) => s.weekday),
          unorderedEquals([1, 3, 5]));

      await tester.tap(find.byKey(const Key('schedule_day_3')));
      await tester.pumpAndSettle();
      expect(find.text('2 TREINOS · 5 DESCANSOS'), findsOneWidget);

      // Qualquer combinação vale: 6 treinos e 1 descanso.
      for (final dia in [2, 3, 4, 6]) {
        await tester.tap(find.byKey(Key('schedule_day_$dia')));
        await tester.pumpAndSettle();
      }
      expect(find.text('6 TREINOS · 1 DESCANSO'), findsOneWidget);

      await _finish(tester, db);
    });
  });
}

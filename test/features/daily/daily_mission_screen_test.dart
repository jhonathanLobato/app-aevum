import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/database/app_database.dart';
import 'package:gym_system/database/database_provider.dart';
import 'package:gym_system/features/daily/presentation/daily_mission_screen.dart';
import 'package:gym_system/features/profile/data/profile_repository_impl.dart';
import 'package:gym_system/features/rank_exam/data/tables/rank_exam_table.dart';
import 'package:gym_system/features/workouts/presentation/week_schedule_screen.dart';
import 'package:gym_system/features/workouts/presentation/widgets/week_schedule_summary.dart';

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
    Future<void> abrirEditor(WidgetTester tester, AppDatabase db) =>
        _pump(tester, db, const WeekScheduleScreen());

    Future<void> marcar(WidgetTester tester, List<int> dias) async {
      for (final d in dias) {
        await tester.tap(find.byKey(Key('schedule_day_$d')));
        await tester.pumpAndSettle();
      }
    }

    testWidgets('o quadro mostra só os dias marcados, sem edição direta',
        (tester) async {
      final db = _memoryDb();
      await _pump(tester, db, const Scaffold(body: WeekScheduleSummary()));
      expect(find.text('Nenhum dia marcado'), findsOneWidget);

      await db
          .into(db.scheduleDays)
          .insert(ScheduleDaysCompanion.insert(weekday: const Value(1)));
      await db
          .into(db.scheduleDays)
          .insert(ScheduleDaysCompanion.insert(weekday: const Value(3)));
      await db
          .into(db.scheduleDays)
          .insert(ScheduleDaysCompanion.insert(weekday: const Value(5)));
      await tester.pumpAndSettle();

      expect(find.text('Seg · Qua · Sex'), findsOneWidget);
      expect(find.text('3 TREINOS'), findsOneWidget);
      // Sem botões de dia no quadro: tocar nele não altera nada.
      expect(find.byKey(const Key('schedule_day_2')), findsNothing);

      await _finish(tester, db);
    });

    testWidgets('marcar não salva até tocar em Salvar; Salvar persiste',
        (tester) async {
      final db = _memoryDb();
      await abrirEditor(tester, db);

      expect(find.text('0 TREINOS · 7 DESCANSOS'), findsOneWidget);
      await marcar(tester, [1, 3, 5]);
      expect(find.text('3 TREINOS · 4 DESCANSOS'), findsOneWidget);
      expect(await db.select(db.scheduleDays).get(), isEmpty); // ainda não

      await tester.tap(find.byKey(const Key('salvar_programacao')));
      await tester.pumpAndSettle();

      expect((await db.select(db.scheduleDays).get()).map((s) => s.weekday),
          unorderedEquals([1, 3, 5]));

      // "Reabre o app": árvore e providers novos sobre o mesmo banco.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
      await _pump(tester, db, const Scaffold(body: WeekScheduleSummary()));
      expect(find.text('Seg · Qua · Sex'), findsOneWidget);

      await _finish(tester, db);
    });

    testWidgets('sair sem salvar descarta as mudanças', (tester) async {
      final db = _memoryDb();
      await db
          .into(db.scheduleDays)
          .insert(ScheduleDaysCompanion.insert(weekday: const Value(2)));
      await abrirEditor(tester, db);

      await marcar(tester, [4, 6]);
      expect(find.text('3 TREINOS · 4 DESCANSOS'), findsOneWidget);

      // Sai e volta: o rascunho foi descartado.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
      await abrirEditor(tester, db);
      expect(find.text('1 TREINO · 6 DESCANSOS'), findsOneWidget);
      expect((await db.select(db.scheduleDays).get()), hasLength(1));

      await _finish(tester, db);
    });

    testWidgets('Salvar fica desabilitado enquanto nada mudou', (tester) async {
      final db = _memoryDb();
      await abrirEditor(tester, db);
      final botao = find.byKey(const Key('salvar_programacao'));
      await tester.tap(botao);
      await tester.pumpAndSettle();
      expect(await db.select(db.scheduleDays).get(), isEmpty);

      await marcar(tester, [7]);
      await tester.tap(botao);
      await tester.pumpAndSettle();
      expect((await db.select(db.scheduleDays).get()).single.weekday, 7);

      await _finish(tester, db);
    });

    testWidgets('qualquer combinação vale: 6 treinos e 1 descanso',
        (tester) async {
      final db = _memoryDb();
      await abrirEditor(tester, db);
      await marcar(tester, [1, 2, 3, 4, 5, 6]);
      expect(find.text('6 TREINOS · 1 DESCANSO'), findsOneWidget);
      await _finish(tester, db);
    });

    testWidgets('durante o exame em andamento não dá para remover dias salvos',
        (tester) async {
      final db = _memoryDb();
      await DriftProfileRepository(db).addXp(1); // cria o usuário
      for (final d in [1, 3]) {
        await db
            .into(db.scheduleDays)
            .insert(ScheduleDaysCompanion.insert(weekday: Value(d)));
      }
      await db.into(db.rankExams).insert(RankExamsCompanion.insert(
          rankAlvo: 'E', inicio: DateTime.now(), prazoDias: 35));
      await abrirEditor(tester, db);

      expect(find.textContaining('EXAME DE RANK EM ANDAMENTO'), findsOneWidget);

      await tester.tap(find.byKey(const Key('schedule_day_1'))); // travado
      await tester.pumpAndSettle();
      expect(find.text('2 TREINOS · 5 DESCANSOS'), findsOneWidget);

      await marcar(tester, [5]); // adicionar pode
      await tester.tap(find.byKey(const Key('salvar_programacao')));
      await tester.pumpAndSettle();
      expect((await db.select(db.scheduleDays).get()), hasLength(3));

      await _finish(tester, db);
    });

    testWidgets('exame disponível lembra do mínimo de 2 dias', (tester) async {
      final db = _memoryDb();
      await DriftProfileRepository(db).addXp(1);
      await db.into(db.rankExams).insert(RankExamsCompanion.insert(
          rankAlvo: 'E',
          inicio: DateTime.now(),
          prazoDias: 35,
          status: const Value(RankExamStatus.disponivel)));
      await abrirEditor(tester, db);

      expect(
          find.textContaining('pelo menos 2 dias de treino'), findsOneWidget);

      await _finish(tester, db);
    });
  });
}

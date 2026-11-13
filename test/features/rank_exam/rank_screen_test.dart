import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/database/app_database.dart';
import 'package:gym_system/database/database_provider.dart';
import 'package:gym_system/features/profile/data/profile_repository_impl.dart';
import 'package:gym_system/features/profile/domain/level_curve.dart';
import 'package:gym_system/features/rank_exam/data/tables/rank_exam_table.dart';
import 'package:gym_system/features/rank_exam/presentation/rank_screen.dart';

AppDatabase _memoryDb() => AppDatabase.forTesting(NativeDatabase.memory());

Future<void> _pump(WidgetTester tester, AppDatabase db) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1.0;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const MaterialApp(home: RankScreen()),
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

Future<void> _usuario(AppDatabase db, {int nivel = 1}) async {
  await DriftProfileRepository(db)
      .addXp(const LevelCurve().xpNoInicioDoNivel(nivel) + 1);
}

Future<void> _programar(AppDatabase db, List<int> dias) async {
  for (final d in dias) {
    await db
        .into(db.scheduleDays)
        .insert(ScheduleDaysCompanion.insert(weekday: Value(d)));
  }
}

void main() {
  testWidgets('explica ranks, níveis, tempos mínimos, exames e regras',
      (tester) async {
    final db = _memoryDb();
    await _usuario(db);
    await _pump(tester, db);

    for (final trecho in [
      'COMO FUNCIONA',
      'F → E',
      'E → D',
      'A → S',
      'NÍVEL 10 · 2 MESES NO RANK F',
      'NÍVEL 25 · 3 MESES NO RANK E',
      'NÍVEL 45 · 5 MESES NO RANK D',
      'NÍVEL 70 · 7 MESES NO RANK C',
      'NÍVEL 100 · 9 MESES NO RANK B',
      'NÍVEL 140 · 10 MESES NO RANK A',
      'Prazo 35 dias · treinos 80% · missão diária 75% · extras 3 atividades × 1',
      'Prazo 140 dias · treinos 95% · missão diária 90% · extras 4 atividades × 3',
    ]) {
      await tester.ensureVisible(find.textContaining(trecho).first);
      expect(find.textContaining(trecho), findsWidgets, reason: trecho);
    }
    await tester.ensureVisible(find.textContaining('Janela de 7 dias'));
    expect(find.textContaining('Janela de 7 dias'), findsOneWidget);
    expect(find.textContaining('Reinício:'), findsOneWidget);

    await _finish(tester, db);
  });

  testWidgets('bloqueado: mostra o que falta de nível e de dias',
      (tester) async {
    final db = _memoryDb();
    await _usuario(db, nivel: 4);
    await _pump(tester, db);

    expect(find.text('PRÓXIMO EXAME (E) BLOQUEADO'), findsOneWidget);
    expect(find.textContaining('Faltam 6 níveis'), findsOneWidget);
    expect(find.textContaining('Faltam'), findsWidgets);
    expect(find.textContaining('no rank F'), findsWidgets);
    expect(find.byKey(const Key('iniciar_exame')), findsNothing);

    await _finish(tester, db);
  });

  testWidgets('disponível: iniciar exige escolher as atividades extras',
      (tester) async {
    final db = _memoryDb();
    await _usuario(db, nivel: 10);
    await _programar(db, [1, 3, 5]);
    await db.into(db.rankExams).insert(RankExamsCompanion.insert(
        rankAlvo: 'E',
        inicio: DateTime.now(),
        prazoDias: 35,
        status: const Value(RankExamStatus.disponivel)));
    await _pump(tester, db);

    expect(find.text('EXAME PARA E DISPONÍVEL'), findsOneWidget);
    expect(find.textContaining('Inicie até'), findsOneWidget);
    expect(find.textContaining('começa sozinho'), findsWidgets);

    await tester.ensureVisible(find.byKey(const Key('iniciar_exame')));
    await tester.tap(find.byKey(const Key('iniciar_exame')));
    await tester.pumpAndSettle();
    expect(find.textContaining('ESCOLHA 3 ATIVIDADES EXTRAS'), findsOneWidget);

    // Só habilita ao escolher exatamente 3.
    final confirmar = find.byKey(const Key('exame_confirmar_atividades'));
    await tester.tap(find.byKey(const Key('exame_ciclismo')));
    await tester.tap(find.byKey(const Key('exame_skate')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(confirmar);
    await tester.tap(confirmar);
    await tester.pumpAndSettle();
    expect((await db.select(db.rankExams).getSingle()).status,
        RankExamStatus.disponivel); // faltava a 3ª

    await tester.tap(find.byKey(const Key('exame_futebol')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(confirmar);
    await tester.tap(confirmar);
    await tester.pumpAndSettle();

    final exame = await db.select(db.rankExams).getSingle();
    expect(exame.status, RankExamStatus.ativo);
    expect(
        exame.modalidades.split(',').toSet(), {'ciclismo', 'skate', 'futebol'});
    // Agora aparece o progresso em número absoluto.
    expect(find.text('EXAME PARA E EM ANDAMENTO'), findsOneWidget);
    expect(find.textContaining('TREINOS PROGRAMADOS (80% DE '), findsOneWidget);

    await _finish(tester, db);
  });

  testWidgets('disponível sem 2 dias programados: botão desabilitado e aviso',
      (tester) async {
    final db = _memoryDb();
    await _usuario(db, nivel: 10);
    await _programar(db, [3]);
    await db.into(db.rankExams).insert(RankExamsCompanion.insert(
        rankAlvo: 'E',
        inicio: DateTime.now(),
        prazoDias: 35,
        status: const Value(RankExamStatus.disponivel)));
    await _pump(tester, db);

    expect(find.textContaining('pelo menos 2 dias de treino programados'),
        findsWidgets);
    await tester.ensureVisible(find.byKey(const Key('iniciar_exame')));
    await tester.tap(find.byKey(const Key('iniciar_exame')));
    await tester.pumpAndSettle();
    expect(find.textContaining('ESCOLHA'), findsNothing); // nada abriu

    await _finish(tester, db);
  });

  testWidgets(
      'em andamento: cada requisito em número absoluto e dias restantes',
      (tester) async {
    final db = _memoryDb();
    await _usuario(db, nivel: 10);
    await _programar(db, [1, 3, 5]);
    await db.into(db.rankExams).insert(RankExamsCompanion.insert(
        rankAlvo: 'E',
        inicio: DateTime.now(),
        prazoDias: 35,
        modalidades: const Value('ciclismo,skate,futebol')));
    await _pump(tester, db);

    expect(find.text('EXAME PARA E EM ANDAMENTO'), findsOneWidget);
    expect(find.textContaining('DIAS RESTANTES'), findsOneWidget);
    expect(find.textContaining('MISSÕES DIÁRIAS (75% DE 35 DIAS)'),
        findsOneWidget);
    expect(find.text('0 / 27'), findsOneWidget); // missões
    expect(find.text('Ciclismo'), findsOneWidget);

    await _finish(tester, db);
  });
}

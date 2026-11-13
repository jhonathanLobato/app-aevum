import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/database/app_database.dart';
import 'package:gym_system/database/database_provider.dart';
import 'package:gym_system/design_system/system_button.dart';
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

Future<void> _expandirSecoes(WidgetTester tester) async {
  for (final id in [
    'o_que_e',
    'como_subir',
    'experiencia',
    'exame',
    'falhar',
    'tabela',
    'perguntas',
  ]) {
    final f = find.byKey(Key('rank_secao_$id'));
    await tester.ensureVisible(f);
    await tester.tap(f);
    await tester.pumpAndSettle();
  }
}

bool _botaoAtivo(WidgetTester tester) =>
    tester
        .widget<SystemButton>(find.byKey(const Key('iniciar_exame')))
        .onPressed !=
    null;

void main() {
  testWidgets('explica ranks, níveis, experiência, exames e regras',
      (tester) async {
    final db = _memoryDb();
    await _usuario(db);
    await _pump(tester, db);

    // Seções começam recolhidas.
    expect(find.textContaining('Janela de 7 dias'), findsNothing);
    expect(find.textContaining('Posso perder o rank?'), findsNothing);
    await _expandirSecoes(tester);

    for (final trecho in [
      'COMO FUNCIONA',
      'O QUE É O RANK',
      'SE FALHAR',
      'PERGUNTAS RÁPIDAS',
      'Posso perder o rank?',
      'E se eu ficar doente?',
      'F → E',
      'E → D',
      'A → S',
      'NÍVEL 10 · 12 DE EXPERIÊNCIA NO RANK F',
      'NÍVEL 25 · 15 DE EXPERIÊNCIA NO RANK E',
      'NÍVEL 45 · 25 DE EXPERIÊNCIA NO RANK D',
      'NÍVEL 70 · 50 DE EXPERIÊNCIA NO RANK C',
      'NÍVEL 100 · 95 DE EXPERIÊNCIA NO RANK B',
      'NÍVEL 140 · 210 DE EXPERIÊNCIA NO RANK A',
      'EXPERIÊNCIA DE CAÇADOR',
      'Treino de academia concluído: +1 ponto',
      'Atividade extra de 30+ min: +0,5 ponto',
      'A missão diária não dá experiência',
      'Prazo 35 dias · treinos 80% · missão diária 75% · extras 3 atividades × 1',
      'Prazo 140 dias · treinos 95% · missão diária 90% · extras 4 atividades × 3',
    ]) {
      await tester.ensureVisible(find.textContaining(trecho).first);
      expect(find.textContaining(trecho), findsWidgets, reason: trecho);
    }
    expect(find.textContaining('você tem 7 dias para iniciar'), findsOneWidget);
    expect(find.textContaining('O exame reinicia se'), findsOneWidget);

    await _finish(tester, db);
  });

  testWidgets('bloqueado: mostra o que falta de nível e de experiência',
      (tester) async {
    final db = _memoryDb();
    await _usuario(db, nivel: 4);
    await _pump(tester, db);

    expect(find.text('PRÓXIMO EXAME (E) BLOQUEADO'), findsOneWidget);
    expect(find.textContaining('Faltam 6 níveis'), findsOneWidget);
    expect(find.textContaining('Faltam'), findsWidgets);
    expect(
        find.textContaining('Faltam 12 pontos de experiência'), findsOneWidget);
    expect(find.text('EXPERIÊNCIA DE CAÇADOR'), findsWidgets);
    expect(find.byKey(const Key('hunter_experience_value')), findsOneWidget);
    expect(find.text('0 / 12'), findsOneWidget);
    expect(find.byKey(const Key('rank_resumo')), findsOneWidget);
    expect(
        find.textContaining(
            'Você é Rank F. Para liberar o exame faltam 6 níveis e 12 pontos de experiência.'),
        findsOneWidget);
    // Botão sempre visível, apagado, com o motivo em números.
    expect(find.byKey(const Key('iniciar_exame')), findsOneWidget);
    expect(_botaoAtivo(tester), isFalse);
    expect(find.textContaining('Exame bloqueado: faltam 6 níveis'),
        findsOneWidget);

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
    expect(_botaoAtivo(tester), isTrue);
    expect(find.textContaining('Restam 7 dias para iniciar'), findsOneWidget);
    expect(find.textContaining('Você tem 7 dias para iniciar'), findsOneWidget);

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
    expect(_botaoAtivo(tester), isFalse);

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
    expect(find.text('EXAME EM ANDAMENTO'), findsOneWidget); // botão
    expect(_botaoAtivo(tester), isFalse);
    expect(find.textContaining('DIAS RESTANTES'), findsOneWidget);
    expect(find.textContaining('MISSÕES DIÁRIAS (75% DE 35 DIAS)'),
        findsOneWidget);
    expect(find.text('0 / 27'), findsOneWidget); // missões
    expect(find.text('Ciclismo'), findsOneWidget);

    await _finish(tester, db);
  });
}

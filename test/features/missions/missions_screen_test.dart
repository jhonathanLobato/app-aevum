import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/database/app_database.dart' hide Mission;
import 'package:gym_system/database/database_provider.dart';
import 'package:gym_system/features/missions/presentation/missions_screen.dart';
import 'package:gym_system/features/profile/data/profile_repository_impl.dart';
import 'package:gym_system/features/rank_exam/data/tables/rank_exam_table.dart';
import 'package:gym_system/features/workouts/presentation/workout_session_providers.dart';

AppDatabase _memoryDb() => AppDatabase.forTesting(NativeDatabase.memory());

Future<void> _pump(
  WidgetTester tester,
  AppDatabase db, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const MaterialApp(home: MissionsScreen()),
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

void main() {
  Future<void> programar(AppDatabase db, int treinos) async {
    for (var dia = 1; dia <= treinos; dia++) {
      await db
          .into(db.scheduleDays)
          .insert(ScheduleDaysCompanion.insert(weekday: Value(dia)));
    }
  }

  testWidgets('mostra a missão diária no topo e a semanal da programação',
      (tester) async {
    final db = _memoryDb();
    await programar(db, 4);
    await _pump(tester, db);

    expect(find.text('MISSÃO DIÁRIA'), findsOneWidget);
    expect(find.text('FLEXÕES'), findsOneWidget);
    expect(find.text('Complete seu treino.'), findsNothing);

    expect(find.text('SEMANAL'), findsOneWidget);
    expect(find.text('Missão semanal'), findsOneWidget);
    expect(find.text('Conclua os 4 treinos programados da semana.'),
        findsOneWidget);
    expect(find.text('0 / 4'), findsOneWidget);
    expect(find.text('+250 XP'), findsOneWidget);

    await _finish(tester, db);
  });

  testWidgets('quadro mostra as missões ativas e as bloqueadas',
      (tester) async {
    final db = _memoryDb();
    await DriftProfileRepository(db).addXp(1);
    await _pump(tester, db); // sem programação e sem recordes
    await tester.ensureVisible(find.text('TODAS AS MISSÕES'));

    expect(find.text('TODAS AS MISSÕES'), findsOneWidget);
    expect(find.text('MISSÃO DE HOJE'), findsOneWidget);
    expect(find.text('ATIVA'), findsOneWidget); // diária
    expect(find.text('BLOQUEADA'), findsWidgets); // semanal, desafio, exame
    expect(find.textContaining('Minha semana'), findsWidgets);
    expect(find.textContaining('Para liberar faltam'), findsOneWidget);

    await _finish(tester, db);
  });

  testWidgets('semanal concluída vai para "concluídas recentemente"',
      (tester) async {
    final db = _memoryDb();
    await programar(db, 1);
    final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)]);
    final repo = container.read(workoutSessionRepositoryProvider);
    await repo.finish(await repo.start(nome: 'Treino livre'),
        duracao: const Duration(minutes: 10));
    container.dispose();

    await _pump(tester, db);

    expect(find.text('CONCLUÍDAS RECENTEMENTE'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);

    await _finish(tester, db);
  });

  testWidgets('sem treinos programados, avisa que não há missão semanal',
      (tester) async {
    final db = _memoryDb();
    await _pump(tester, db);

    expect(find.text('MISSÃO DIÁRIA'), findsOneWidget);
    expect(find.text('SEM MISSÃO SEMANAL'), findsOneWidget);
    expect(find.text('EXAME DE RANK'), findsNothing);

    await _finish(tester, db);
  });

  testWidgets('resumo do exame em andamento leva para a tela de Rank',
      (tester) async {
    final db = _memoryDb();
    await DriftProfileRepository(db).addXp(1); // cria o usuário
    await programar(db, 3);
    await db.into(db.rankExams).insert(RankExamsCompanion.insert(
        rankAlvo: 'E', inicio: DateTime.now(), prazoDias: 35));
    await _pump(tester, db);

    await tester.ensureVisible(find.byKey(const Key('rank_card')));
    expect(find.text('EXAME PARA E EM ANDAMENTO'), findsOneWidget);
    // Só um resumo: os requisitos ficam na tela de Rank.
    expect(find.textContaining('TREINOS PROGRAMADOS ('), findsNothing);

    await _finish(tester, db);
  });

  testWidgets('resumo do exame disponível mostra até quando iniciar',
      (tester) async {
    final db = _memoryDb();
    await DriftProfileRepository(db).addXp(1);
    await db.into(db.rankExams).insert(RankExamsCompanion.insert(
        rankAlvo: 'E',
        inicio: DateTime.now(),
        prazoDias: 35,
        status: const Value(RankExamStatus.disponivel)));
    await _pump(tester, db);

    await tester.ensureVisible(find.byKey(const Key('rank_card')));
    expect(find.text('EXAME PARA E DISPONÍVEL'), findsOneWidget);
    expect(find.textContaining('Inicie até'), findsOneWidget);

    await _finish(tester, db);
  });

  testWidgets('sem exame disponível o card de rank não aparece em Missões',
      (tester) async {
    final db = _memoryDb();
    await DriftProfileRepository(db).addXp(1);
    await _pump(tester, db);
    expect(find.byKey(const Key('rank_card')), findsNothing);
    await _finish(tester, db);
  });

  testWidgets('penalidade pendente aparece como card vermelho', (tester) async {
    final db = _memoryDb();
    await db.into(db.dailyDays).insert(DailyDaysCompanion.insert(
          dia: '2026-01-01',
          processado: const Value(true),
          penalidadeXp: const Value(100),
          avisado: const Value(false),
        ));
    await _pump(tester, db);

    expect(find.textContaining('PENALIDADE: -100 XP'), findsOneWidget);

    await _finish(tester, db);
  });

  testWidgets('desafio de carga aparece com meta real em kg', (tester) async {
    final db = _memoryDb();
    final exId = await db.into(db.exercises).insert(
          ExercisesCompanion.insert(
              nome: 'Supino reto', grupoMuscular: 'Peito'),
        );
    final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)]);
    final sessionRepo = container.read(workoutSessionRepositoryProvider);
    // O primeiro treino só estabelece a referência (30 kg); o desafio nasce
    // no primeiro PR de carga de verdade, no treino seguinte.
    final anterior = await sessionRepo.start(nome: 'Treino anterior');
    await sessionRepo.logSet(
        sessionId: anterior, exerciseId: exId, repeticoes: 5, carga: 30);
    await sessionRepo.finish(anterior, duracao: const Duration(minutes: 10));
    final sessionId = await sessionRepo.start(nome: 'Treino livre');
    await sessionRepo.logSet(
        sessionId: sessionId, exerciseId: exId, repeticoes: 5, carga: 31);
    container.dispose();

    await _pump(tester, db);

    expect(find.text('DESAFIOS'), findsOneWidget);
    expect(find.textContaining('Supino reto'), findsWidgets);
    expect(find.text('0 / 33'), findsOneWidget);

    await _finish(tester, db);
  });

  testWidgets('320px de largura não estoura', (tester) async {
    final db = _memoryDb();
    await _pump(tester, db, size: const Size(320, 640));

    expect(tester.takeException(), isNull);

    await _finish(tester, db);
  });

  testWidgets('text scaling elevado não estoura', (tester) async {
    final db = _memoryDb();
    tester.view.platformDispatcher.textScaleFactorTestValue = 1.8;

    await _pump(tester, db);

    expect(tester.takeException(), isNull);

    tester.view.platformDispatcher.clearTextScaleFactorTestValue();
    await _finish(tester, db);
  });

  testWidgets('descrição de desafio com nome de exercício longo não estoura',
      (tester) async {
    final db = _memoryDb();
    final exId = await db.into(db.exercises).insert(
          ExercisesCompanion.insert(
            nome: 'Supino reto com halteres em banco inclinado ajustável',
            grupoMuscular: 'Peito',
          ),
        );
    final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)]);
    final sessionRepo = container.read(workoutSessionRepositoryProvider);
    final sessionId = await sessionRepo.start(nome: 'Treino livre');
    await sessionRepo.logSet(
        sessionId: sessionId, exerciseId: exId, repeticoes: 5, carga: 30);
    container.dispose();

    await _pump(tester, db);

    expect(tester.takeException(), isNull);

    await _finish(tester, db);
  });

  testWidgets('a tela rola verticalmente', (tester) async {
    final db = _memoryDb();
    await _pump(tester, db, size: const Size(360, 500));

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await _finish(tester, db);
  });
}

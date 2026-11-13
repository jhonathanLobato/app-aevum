import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_system/database/app_database.dart';
import 'package:gym_system/database/database_provider.dart';
import 'package:gym_system/features/achievements/data/achievement_repository_impl.dart';
import 'package:gym_system/features/activities/data/sport_activity_repository_impl.dart';
import 'package:gym_system/features/activities/domain/sport_activity.dart';
import 'package:gym_system/features/activities/presentation/sport_activity_detail_screen.dart';
import 'package:gym_system/features/missions/data/mission_repository_impl.dart';
import 'package:gym_system/features/profile/data/profile_repository_impl.dart';
import 'package:gym_system/features/progression/data/personal_record_repository_impl.dart';
import 'package:gym_system/features/workouts/data/workout_session_repository_impl.dart';
import 'package:gym_system/features/workouts/domain/workout_session.dart';
import 'package:gym_system/features/workouts/presentation/active_workout_screen.dart';
import 'package:gym_system/features/workouts/presentation/general_history.dart';
import 'package:gym_system/features/workouts/presentation/workout_history_screen.dart';

AppDatabase _memoryDb() => AppDatabase.forTesting(NativeDatabase.memory());

Future<void> _aguardar(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}

Future<void> _finish(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 50));
  await db.close();
}

Future<void> _treino(AppDatabase db, String nome, DateTime data) {
  return db.into(db.workoutSessions).insert(WorkoutSessionsCompanion.insert(
        nome: nome,
        status: WorkoutSessionStatus.concluido,
        data: Value(data),
        duracaoSegundos: const Value(1800),
      ));
}

Future<int> _atividade(AppDatabase db, SportType tipo, DateTime data,
    {int duracao = 31, double? km, int? rounds}) {
  return DriftSportActivityRepository(db).create(SportActivityInput(
    tipo: tipo,
    data: data,
    duracaoMinutos: duracao,
    distanciaKm: km,
    rounds: rounds,
  ));
}

GoRouter _router() => GoRouter(
      initialLocation: '/history',
      routes: [
        GoRoute(
            path: '/history', builder: (c, s) => const WorkoutHistoryScreen()),
        GoRoute(
            path: '/sessions/:id',
            builder: (c, s) => ActiveWorkoutScreen(
                sessionId: int.parse(s.pathParameters['id']!))),
        GoRoute(
            path: '/activities/:type/:id',
            builder: (c, s) => SportActivityDetailScreen(
                tipo: SportType.fromName(s.pathParameters['type'])!,
                activityId: int.parse(s.pathParameters['id']!))),
      ],
    );

Future<void> _pump(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp.router(routerConfig: _router()),
    ),
  );
  await _aguardar(tester);
}

void main() {
  group('composição e agrupamento (puro)', () {
    WorkoutSessionSummary treino(int id, DateTime data) =>
        WorkoutSessionSummary(
          id: id,
          nome: 'Treino $id',
          data: data,
          duracaoSegundos: 60,
          totalSeries: 1,
          volumeTotal: 10,
          totalExercicios: 1,
        );
    SportActivity ativ(int id, DateTime data) => SportActivity(
          id: id,
          tipo: SportType.corridaCaminhada,
          data: data,
          duracaoMinutos: 30,
          criadoEm: data,
        );

    test('ordena musculação + atividades do mais recente pro mais antigo', () {
      final linha = montarLinhaDoTempo(
        [treino(1, DateTime(2026, 10, 1)), treino(2, DateTime(2026, 9, 25))],
        [ativ(1, DateTime(2026, 10, 3)), ativ(2, DateTime(2026, 9, 29))],
      );
      expect(linha.map((e) => e.data), [
        DateTime(2026, 10, 3),
        DateTime(2026, 10, 1),
        DateTime(2026, 9, 29),
        DateTime(2026, 9, 25),
      ]);
      expect(linha[0], isA<SportHistoryEntry>());
      expect(linha[1], isA<WorkoutHistoryEntry>());
    });

    test('agrupa por mês e ano, inclusive anos diferentes, com contagem', () {
      final meses = agruparPorMes(montarLinhaDoTempo(
        [
          treino(1, DateTime(2026, 10, 4)),
          treino(2, DateTime(2026, 10, 1)),
          treino(3, DateTime(2025, 10, 2)),
        ],
        [
          ativ(1, DateTime(2026, 10, 3)),
          ativ(2, DateTime(2026, 9, 29)),
        ],
      ));

      expect(meses.map((m) => m.chave), ['2026-10', '2026-09', '2025-10']);
      expect(meses.map((m) => m.total), [3, 1, 1]);
      expect(meses.first.registros.map((e) => e.data.day), [4, 3, 1]);
    });

    test('só musculação, só atividades e vazio', () {
      expect(
          agruparPorMes(
              montarLinhaDoTempo([treino(1, DateTime(2026, 1, 1))], const [])),
          hasLength(1));
      expect(
          agruparPorMes(
              montarLinhaDoTempo(const [], [ativ(1, DateTime(2026, 1, 1))])),
          hasLength(1));
      expect(agruparPorMes(montarLinhaDoTempo(const [], const [])), isEmpty);
    });
  });

  testWidgets('histórico vazio mostra o estado vazio', (tester) async {
    final db = _memoryDb();
    await _pump(tester, db);
    expect(find.text('NENHUM REGISTRO NO HISTÓRICO'), findsOneWidget);
    await _finish(tester, db);
  });

  testWidgets('só musculação continua aparecendo normalmente', (tester) async {
    final db = _memoryDb();
    await _treino(db, 'Treino A', DateTime(2026, 10, 4));
    await _pump(tester, db);

    expect(find.text('OUTUBRO 2026'), findsOneWidget);
    expect(find.text('1 REGISTRO'), findsOneWidget);
    expect(find.text('TREINO A'), findsOneWidget);
    expect(find.text('EXERCÍCIOS'), findsOneWidget);
    await _finish(tester, db);
  });

  testWidgets('só atividades aparecem, sem campos ausentes', (tester) async {
    final db = _memoryDb();
    await _atividade(db, SportType.corridaCaminhada, DateTime(2026, 10, 3),
        km: 5.2, duracao: 31);
    await _atividade(db, SportType.muayThaiBoxe, DateTime(2026, 10, 2),
        duracao: 60, rounds: 8);
    await _atividade(db, SportType.futebol, DateTime(2026, 10, 1), duracao: 90);
    await _pump(tester, db);

    expect(find.text('3 REGISTROS'), findsOneWidget);
    expect(find.text('5,2 KM · 31 MIN'), findsOneWidget);
    expect(find.text('5:58 /KM'), findsOneWidget);
    expect(find.text('60 MIN · 8 ROUNDS'), findsOneWidget);
    expect(find.text('90 MIN'), findsOneWidget);
    expect(find.textContaining('null'), findsNothing);
    await _finish(tester, db);
  });

  testWidgets('histórico misto: ordem cronológica, meses e anos diferentes',
      (tester) async {
    final db = _memoryDb();
    await _treino(db, 'Treino A', DateTime(2026, 10, 4));
    await _treino(db, 'Treino B', DateTime(2026, 10, 1));
    await _treino(db, 'Treino C', DateTime(2026, 9, 25));
    await _treino(db, 'Treino Antigo', DateTime(2025, 12, 10));
    await _atividade(db, SportType.corridaCaminhada, DateTime(2026, 10, 3),
        km: 5.2, duracao: 31);
    await _atividade(db, SportType.muayThaiBoxe, DateTime(2026, 9, 29),
        duracao: 60, rounds: 8);
    await _atividade(db, SportType.ciclismo, DateTime(2026, 9, 27),
        km: 18.4, duracao: 58);
    await _pump(tester, db);

    double topo(String t) => tester.getTopLeft(find.text(t)).dy;
    final ordem = [
      'OUTUBRO 2026',
      'TREINO A',
      'CORRIDA/CAMINHADA',
      'TREINO B',
      'SETEMBRO 2026',
      'MUAY THAI/BOXE',
      'CICLISMO',
      'TREINO C',
      'DEZEMBRO 2025',
      'TREINO ANTIGO',
    ];
    for (var i = 0; i < ordem.length - 1; i++) {
      expect(topo(ordem[i]), lessThan(topo(ordem[i + 1])),
          reason: '${ordem[i]} antes de ${ordem[i + 1]}');
    }
    expect(find.text('3 REGISTROS'), findsNWidgets(2)); // outubro e setembro
    expect(find.text('1 REGISTRO'), findsOneWidget); // dezembro/2025
    expect(find.text('18,4 KM · 58 MIN'), findsOneWidget);
    expect(find.text('18,4 KM/H'), findsNothing);
    expect(find.text('19 KM/H'), findsOneWidget);
    await _finish(tester, db);
  });

  testWidgets('tocar no cabeçalho do mês recolhe e expande os registros',
      (tester) async {
    final db = _memoryDb();
    await _treino(db, 'Treino A', DateTime(2026, 10, 4));
    await _atividade(db, SportType.corridaCaminhada, DateTime(2026, 10, 3),
        km: 5);
    await _treino(db, 'Treino C', DateTime(2026, 9, 25));
    await _pump(tester, db);

    expect(find.text('TREINO A'), findsOneWidget);
    expect(find.text('CORRIDA/CAMINHADA'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_down), findsNWidgets(2));

    // Cabeçalho inteiro é tocável (não só a seta): toca no texto do mês.
    await tester.tap(find.text('OUTUBRO 2026'));
    await tester.pumpAndSettle();
    expect(find.text('TREINO A'), findsNothing);
    expect(find.text('CORRIDA/CAMINHADA'), findsNothing);
    expect(find.text('2 REGISTROS'), findsOneWidget); // contagem continua
    expect(find.text('TREINO C'), findsOneWidget); // outros meses intactos
    expect(find.byIcon(Icons.keyboard_arrow_right), findsOneWidget);

    await tester.tap(find.text('OUTUBRO 2026'));
    await tester.pumpAndSettle();
    expect(find.text('TREINO A'), findsOneWidget);
    expect(find.text('CORRIDA/CAMINHADA'), findsOneWidget);
    await _finish(tester, db);
  });

  testWidgets('tocar em musculação abre a sessão, sem alterar XP',
      (tester) async {
    final db = _memoryDb();
    final exId = await db.into(db.exercises).insert(
        ExercisesCompanion.insert(nome: 'Supino reto', grupoMuscular: 'Peito'));
    final repo = DriftWorkoutSessionRepository(
      db,
      DriftPersonalRecordRepository(db),
      DriftProfileRepository(db),
      DriftMissionRepository(db),
      DriftAchievementRepository(db),
    );
    final id = await repo.start(nome: 'Treino livre');
    await repo.logSet(
        sessionId: id, exerciseId: exId, repeticoes: 10, carga: 30);
    await repo.finish(id, duracao: const Duration(minutes: 5));
    final xpAntes = (await db.select(db.users).getSingle()).xp;

    await _pump(tester, db);
    expect(find.text('EXERCÍCIOS'), findsOneWidget);
    await tester.tap(find.text('TREINO LIVRE'));
    await _aguardar(tester);

    expect(find.text('30.0 KG × 10'), findsOneWidget);
    expect(find.text('TREINO FINALIZADO'), findsOneWidget);
    expect((await db.select(db.users).getSingle()).xp, xpAntes);
    await _finish(tester, db);
  });

  testWidgets(
      'tocar em atividade abre o detalhe; excluir atualiza o histórico, sem XP',
      (tester) async {
    final db = _memoryDb();
    await _atividade(db, SportType.corridaCaminhada, DateTime(2026, 10, 3),
        km: 5.2, duracao: 31);
    await _treino(db, 'Treino A', DateTime(2026, 10, 4));
    await _pump(tester, db);

    await tester.tap(find.text('CORRIDA/CAMINHADA'));
    await _aguardar(tester);
    expect(find.text('DETALHE DO REGISTRO'), findsOneWidget);

    await tester.tap(find.text('EXCLUIR'));
    await _aguardar(tester);
    await tester.tap(find.text('EXCLUIR').last);
    await _aguardar(tester);

    // Voltou pro histórico geral já sem a corrida; musculação segue lá.
    expect(find.text('LINHA DO TEMPO'), findsOneWidget);
    expect(find.text('CORRIDA/CAMINHADA'), findsNothing);
    expect(find.text('TREINO A'), findsOneWidget);
    expect(find.text('1 REGISTRO'), findsOneWidget);
    expect(await db.select(db.sportActivities).get(), isEmpty);
    expect(await db.select(db.users).get(), isEmpty);
    await _finish(tester, db);
  });
}

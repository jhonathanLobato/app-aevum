import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_system/database/app_database.dart';
import 'package:gym_system/database/database_provider.dart';
import 'package:gym_system/features/activities/data/sport_activity_repository_impl.dart';
import 'package:gym_system/features/activities/domain/sport_activity.dart';
import 'package:gym_system/features/activities/presentation/activities_screen.dart';
import 'package:gym_system/features/activities/presentation/sport_activity_detail_screen.dart';
import 'package:gym_system/features/activities/presentation/sport_activity_form_screen.dart';
import 'package:gym_system/features/activities/presentation/sport_activity_tile.dart';
import 'package:gym_system/features/activities/presentation/sport_history_screen.dart';
import 'package:gym_system/features/activities/presentation/sport_type_screen.dart';

AppDatabase _memoryDb() => AppDatabase.forTesting(NativeDatabase.memory());

SportType _tipo(GoRouterState s) =>
    SportType.fromName(s.pathParameters['type'])!;

GoRouter _router() => GoRouter(
      initialLocation: '/activities',
      routes: [
        GoRoute(
            path: '/activities', builder: (c, s) => const ActivitiesScreen()),
        GoRoute(
            path: '/activities/:type',
            builder: (c, s) => SportTypeScreen(tipo: _tipo(s))),
        GoRoute(
            path: '/activities/:type/new',
            builder: (c, s) => SportActivityFormScreen(tipo: _tipo(s))),
        GoRoute(
            path: '/activities/:type/history',
            builder: (c, s) => SportHistoryScreen(tipo: _tipo(s))),
        GoRoute(
            path: '/activities/:type/:id',
            builder: (c, s) => SportActivityDetailScreen(
                tipo: _tipo(s),
                activityId: int.parse(s.pathParameters['id']!))),
        GoRoute(
            path: '/activities/:type/:id/edit',
            builder: (c, s) => SportActivityFormScreen(
                tipo: _tipo(s),
                activityId: int.parse(s.pathParameters['id']!))),
      ],
    );

Future<void> _aguardar(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}

Future<void> _pump(WidgetTester tester, AppDatabase db,
    {String inicial = '/activities'}) async {
  final router = _router();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  if (inicial != '/activities') router.go(inicial);
  await _aguardar(tester);
}

Future<void> _finish(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 50));
  await db.close();
}

SportActivityInput _in(SportType tipo,
        {int dia = 4,
        int mes = 10,
        int duracao = 31,
        double? km,
        int? rounds}) =>
    SportActivityInput(
      tipo: tipo,
      data: DateTime(2026, mes, dia),
      duracaoMinutos: duracao,
      distanciaKm: km,
      rounds: rounds,
    );

Finder _campo(String chave) => find.descendant(
    of: find.byKey(Key(chave)), matching: find.byType(TextField));

void main() {
  testWidgets('aba mostra as 8 modalidades fixas, sem "Outra" nem adicionar',
      (tester) async {
    final db = _memoryDb();
    await _pump(tester, db);

    expect(find.text('ATIVIDADES'), findsOneWidget);
    expect(find.text('REGISTRO ESPORTIVO'), findsOneWidget);
    for (final nome in [
      'CORRIDA',
      'CICLISMO',
      'CAMINHADA',
      'BOXE',
      'MUAY THAI',
      'BASQUETE',
      'FUTEBOL',
      'SKATE',
    ]) {
      expect(find.text(nome), findsOneWidget, reason: nome);
    }
    expect(find.textContaining('OUTRA'), findsNothing);
    expect(find.byIcon(Icons.add), findsNothing);

    await tester.tap(find.text('CORRIDA'));
    await _aguardar(tester);
    expect(find.text('ADICIONAR REGISTRO'), findsOneWidget);

    await _finish(tester, db);
  });

  testWidgets('modalidade sem registros mostra o estado vazio com contexto',
      (tester) async {
    final db = _memoryDb();
    await _pump(tester, db);
    await tester.tap(find.text('BOXE'));
    await _aguardar(tester);

    expect(find.text('ADICIONAR REGISTRO'), findsOneWidget);
    expect(find.text('HISTÓRICO'), findsOneWidget);
    expect(find.text('NENHUMA ATIVIDADE REGISTRADA'), findsOneWidget);
    expect(
        find.text('Seus registros de Boxe aparecerão aqui.'), findsOneWidget);

    await _finish(tester, db);
  });

  testWidgets('página mostra só os 3 mais recentes; histórico mostra todos',
      (tester) async {
    final db = _memoryDb();
    final repo = DriftSportActivityRepository(db);
    for (var dia = 1; dia <= 5; dia++) {
      await repo.create(_in(SportType.corrida, dia: dia, km: 5, duracao: 30));
    }
    // Outra modalidade não pode aparecer na corrida.
    await repo.create(_in(SportType.ciclismo, dia: 20, km: 30, duracao: 60));

    await _pump(tester, db);
    await tester.tap(find.text('CORRIDA'));
    await _aguardar(tester);

    expect(find.byType(SportActivityTile), findsNWidgets(3));
    expect(find.text('05 OUT'), findsOneWidget);
    expect(find.text('04 OUT'), findsOneWidget);
    expect(find.text('03 OUT'), findsOneWidget);
    expect(find.text('02 OUT'), findsNothing);
    expect(find.text('20 OUT'), findsNothing);

    await tester.tap(find.text('HISTÓRICO'));
    await _aguardar(tester);

    expect(find.text('HISTÓRICO COMPLETO'), findsOneWidget);
    expect(find.byType(SportActivityTile), findsNWidgets(5));
    expect(find.text('01 OUT 2026'), findsOneWidget);
    expect(find.text('20 OUT 2026'), findsNothing);

    await _finish(tester, db);
  });

  testWidgets('cria uma corrida pelo formulário e mostra o ritmo médio',
      (tester) async {
    final db = _memoryDb();
    await _pump(tester, db);
    await tester.tap(find.text('CORRIDA'));
    await _aguardar(tester);
    await tester.tap(find.text('ADICIONAR REGISTRO'));
    await _aguardar(tester);

    // Corrida: distância sim, rounds não.
    expect(find.byKey(const Key('atividade_distancia_field')), findsOneWidget);
    expect(find.byKey(const Key('atividade_rounds_field')), findsNothing);

    await tester.enterText(_campo('atividade_duracao_field'), '31');
    await tester.enterText(_campo('atividade_distancia_field'), '5,2');
    await tester.pump();
    await tester.ensureVisible(find.text('SALVAR REGISTRO'));
    await tester.tap(find.text('SALVAR REGISTRO'));
    await _aguardar(tester);

    expect(find.text('5,2 KM · 31 MIN'), findsOneWidget);
    expect(find.text('5:58 /KM'), findsOneWidget);

    await _finish(tester, db);
  });

  testWidgets('formulário só mostra os campos da modalidade', (tester) async {
    final db = _memoryDb();
    await _pump(tester, db);

    Future<void> abrirForm(String nome) async {
      await tester.tap(find.text(nome));
      await _aguardar(tester);
      await tester.tap(find.text('ADICIONAR REGISTRO'));
      await _aguardar(tester);
    }

    await abrirForm('BOXE');
    expect(find.byKey(const Key('atividade_rounds_field')), findsOneWidget);
    expect(find.byKey(const Key('atividade_distancia_field')), findsNothing);
    await tester.tap(find.byTooltip('Voltar'));
    await _aguardar(tester);
    await tester.tap(find.byTooltip('Voltar'));
    await _aguardar(tester);

    await abrirForm('FUTEBOL');
    expect(find.byKey(const Key('atividade_rounds_field')), findsNothing);
    expect(find.byKey(const Key('atividade_distancia_field')), findsNothing);
    expect(find.byKey(const Key('atividade_duracao_field')), findsOneWidget);

    await _finish(tester, db);
  });

  testWidgets('não salva com duração vazia e mostra o erro', (tester) async {
    final db = _memoryDb();
    await _pump(tester, db);
    await tester.tap(find.text('CORRIDA'));
    await _aguardar(tester);
    await tester.tap(find.text('ADICIONAR REGISTRO'));
    await _aguardar(tester);

    await tester.ensureVisible(find.text('SALVAR REGISTRO'));
    await tester.tap(find.text('SALVAR REGISTRO'));
    await _aguardar(tester);

    expect(find.text('Informe a duração em minutos'), findsOneWidget);
    expect(await db.select(db.sportActivities).get(), isEmpty);

    await tester.enterText(_campo('atividade_duracao_field'), '0');
    await tester.pump();
    expect(find.text('Informe a duração em minutos'), findsOneWidget);

    await _finish(tester, db);
  });

  testWidgets(
      'detalhe mostra velocidade do ciclismo; edita e exclui com confirmação',
      (tester) async {
    final db = _memoryDb();
    final repo = DriftSportActivityRepository(db);
    await repo.create(_in(SportType.ciclismo, km: 15, duracao: 30));

    await _pump(tester, db);
    await tester.tap(find.text('CICLISMO'));
    await _aguardar(tester);
    await tester.tap(find.byType(SportActivityTile));
    await _aguardar(tester);

    expect(find.text('DETALHE DO REGISTRO'), findsOneWidget);
    expect(find.text('30 KM/H'), findsOneWidget);
    expect(find.text('15 KM'), findsOneWidget);
    expect(find.text('RITMO MÉDIO'), findsNothing);

    // Editar reaproveita o formulário, já preenchido.
    await tester.tap(find.text('EDITAR'));
    await _aguardar(tester);
    expect(find.text('EDITAR REGISTRO'), findsOneWidget);
    await tester.enterText(_campo('atividade_duracao_field'), '60');
    await tester.pump();
    await tester.ensureVisible(find.text('SALVAR ALTERAÇÕES'));
    await tester.tap(find.text('SALVAR ALTERAÇÕES'));
    await _aguardar(tester);
    expect(find.text('15 KM/H'), findsOneWidget);

    // Excluir pede confirmação.
    await tester.tap(find.text('EXCLUIR'));
    await _aguardar(tester);
    expect(find.text('EXCLUIR REGISTRO?'), findsOneWidget);
    await tester.tap(find.text('CANCELAR'));
    await _aguardar(tester);
    expect(await db.select(db.sportActivities).get(), hasLength(1));

    await tester.tap(find.text('EXCLUIR'));
    await _aguardar(tester);
    await tester.tap(find.text('EXCLUIR').last);
    await _aguardar(tester);

    expect(await db.select(db.sportActivities).get(), isEmpty);
    expect(find.text('NENHUMA ATIVIDADE REGISTRADA'), findsOneWidget);

    await _finish(tester, db);
  });
}

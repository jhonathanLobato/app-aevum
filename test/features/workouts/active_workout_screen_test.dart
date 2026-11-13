import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_system/database/app_database.dart' hide Mission;
import 'package:gym_system/database/database_provider.dart';
import 'package:gym_system/design_system/system_navigation_bar.dart';
import 'package:gym_system/features/workouts/data/workout_template_repository_impl.dart';
import 'package:gym_system/features/workouts/domain/workout_session.dart';
import 'package:gym_system/features/workouts/presentation/active_workout_screen.dart';
import 'package:gym_system/features/workouts/presentation/workout_session_providers.dart';
import 'package:gym_system/features/workouts/presentation/workout_template_detail_screen.dart';

AppDatabase _memoryDb() => AppDatabase.forTesting(NativeDatabase.memory());

Future<int> _criarExercicio(AppDatabase db, String nome) {
  return db
      .into(db.exercises)
      .insert(ExercisesCompanion.insert(nome: nome, grupoMuscular: 'Peito'));
}

GoRouter _router(int treinoId) => GoRouter(
      initialLocation: '/workouts/$treinoId',
      routes: [
        GoRoute(
          path: '/workouts/:id',
          builder: (context, state) => WorkoutTemplateDetailScreen(
              templateId: int.parse(state.pathParameters['id']!)),
        ),
        GoRoute(
          path: '/sessions/:id',
          builder: (context, state) => ActiveWorkoutScreen(
              sessionId: int.parse(state.pathParameters['id']!)),
        ),
      ],
    );

Future<void> _pump(WidgetTester tester, AppDatabase db, int treinoId) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp.router(routerConfig: _router(treinoId)),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _finish(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 50));
  await db.close();
}

Future<void> _registrarSerie(WidgetTester tester,
    {required String carga, required String reps}) async {
  await tester.enterText(
    find.descendant(
        of: find.byKey(const Key('workout_carga_field')),
        matching: find.byType(TextField)),
    carga,
  );
  await tester.enterText(
    find.descendant(
        of: find.byKey(const Key('workout_reps_field')),
        matching: find.byType(TextField)),
    reps,
  );
  await tester.pumpAndSettle();
  // A lista de séries registradas cresce a cada chamada, empurrando o
  // botão pra baixo na rolagem — sem isso, a partir da 2ª série o tap
  // acerta coordenadas que já não correspondem mais ao botão.
  await tester.ensureVisible(find.text('REGISTRAR SÉRIE'));
  await tester.tap(find.text('REGISTRAR SÉRIE'));
  await tester.pumpAndSettle();
}

/// Fecha, em sequência, todos os diálogos de feedback que podem aparecer
/// depois de uma série (PR, missão, conquista, level up) — o teste de
/// fluxo completo já cobre o conteúdo deles; aqui só preciso destravar a
/// tela pra continuar testando a navegação do carrossel.
Future<void> _fecharDialogosSeHouver(WidgetTester tester) async {
  while (find.text('OK').evaluate().isNotEmpty) {
    await tester.tap(find.text('OK').first);
    await tester.pumpAndSettle();
  }
}

void main() {
  group('carrossel — navegação', () {
    testWidgets(
        'sessão com 1 exercício: contador 01/01, sem navegação possível',
        (tester) async {
      final db = _memoryDb();
      final exId = await _criarExercicio(db, 'Supino reto');
      final templateRepo = DriftWorkoutTemplateRepository(db);
      final treinoId = await templateRepo.create('Treino A');
      await templateRepo.addExercise(treinoId, exId);

      await _pump(tester, db, treinoId);
      await tester.tap(find.text('INICIAR TREINO'));
      await tester.pumpAndSettle();

      expect(find.text('01 / 01'), findsOneWidget);
      expect(find.text('SUPINO RETO'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(find.text('01 / 01'), findsOneWidget);

      await _finish(tester, db);
    });

    testWidgets(
        'próximo/anterior navegam entre exercícios sem passar dos limites',
        (tester) async {
      final db = _memoryDb();
      final templateRepo = DriftWorkoutTemplateRepository(db);
      final treinoId = await templateRepo.create('Treino A');
      for (final nome in ['Supino reto', 'Agachamento', 'Remada curvada']) {
        final exId = await _criarExercicio(db, nome);
        await templateRepo.addExercise(treinoId, exId);
      }

      await _pump(tester, db, treinoId);
      await tester.tap(find.text('INICIAR TREINO'));
      await tester.pumpAndSettle();

      expect(find.text('01 / 03'), findsOneWidget);
      expect(find.text('SUPINO RETO'), findsOneWidget);

      // Não volta antes do primeiro.
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      expect(find.text('01 / 03'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(find.text('02 / 03'), findsOneWidget);
      expect(find.text('AGACHAMENTO'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(find.text('03 / 03'), findsOneWidget);
      expect(find.text('REMADA CURVADA'), findsOneWidget);

      // Não avança além do último.
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(find.text('03 / 03'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      expect(find.text('02 / 03'), findsOneWidget);

      await _finish(tester, db);
    });

    testWidgets('voltar a um exercício anterior mantém as séries registradas',
        (tester) async {
      final db = _memoryDb();
      final templateRepo = DriftWorkoutTemplateRepository(db);
      final treinoId = await templateRepo.create('Treino A');
      final ex1 = await _criarExercicio(db, 'Supino reto');
      final ex2 = await _criarExercicio(db, 'Agachamento');
      await templateRepo.addExercise(treinoId, ex1);
      await templateRepo.addExercise(treinoId, ex2);

      await _pump(tester, db, treinoId);
      await tester.tap(find.text('INICIAR TREINO'));
      await tester.pumpAndSettle();

      await _registrarSerie(tester, carga: '30', reps: '10');
      await _fecharDialogosSeHouver(tester);
      expect(find.text('30.0 KG × 10'), findsOneWidget);

      // Registrar a série rolou a tela pra baixo (ensureVisible) — o
      // cabeçalho com as setas ficou fora da área visível.
      await tester.ensureVisible(find.byIcon(Icons.chevron_right));
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(find.text('02 / 02'), findsOneWidget);
      expect(find.text('NENHUMA SÉRIE REGISTRADA NESTE EXERCÍCIO'),
          findsOneWidget);

      await tester.ensureVisible(find.byIcon(Icons.chevron_left));
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      expect(find.text('01 / 02'), findsOneWidget);
      expect(find.text('30.0 KG × 10'), findsOneWidget);

      await _finish(tester, db);
    });
  });

  group('registro de séries', () {
    testWidgets('exercício sem séries mostra estado vazio contextual',
        (tester) async {
      final db = _memoryDb();
      final exId = await _criarExercicio(db, 'Supino reto');
      final templateRepo = DriftWorkoutTemplateRepository(db);
      final treinoId = await templateRepo.create('Treino A');
      await templateRepo.addExercise(treinoId, exId);

      await _pump(tester, db, treinoId);
      await tester.tap(find.text('INICIAR TREINO'));
      await tester.pumpAndSettle();

      expect(find.text('NENHUMA SÉRIE REGISTRADA NESTE EXERCÍCIO'),
          findsOneWidget);

      await _finish(tester, db);
    });

    testWidgets(
        'registra carga decimal (vírgula) e persiste corretamente no banco',
        (tester) async {
      final db = _memoryDb();
      final exId = await _criarExercicio(db, 'Supino reto');
      final templateRepo = DriftWorkoutTemplateRepository(db);
      final treinoId = await templateRepo.create('Treino A');
      await templateRepo.addExercise(treinoId, exId);

      await _pump(tester, db, treinoId);
      await tester.tap(find.text('INICIAR TREINO'));
      await tester.pumpAndSettle();

      await _registrarSerie(tester, carga: '32,5', reps: '8');
      await _fecharDialogosSeHouver(tester);

      expect(find.text('32.5 KG × 8'), findsOneWidget);

      final linha = await (db.select(db.setEntries)).getSingle();
      expect(linha.carga, 32.5);
      expect(linha.repeticoes, 8);
      expect(linha.serie, 1);

      await _finish(tester, db);
    });

    testWidgets('várias séries ficam numeradas em ordem', (tester) async {
      final db = _memoryDb();
      final exId = await _criarExercicio(db, 'Supino reto');
      final templateRepo = DriftWorkoutTemplateRepository(db);
      final treinoId = await templateRepo.create('Treino A');
      await templateRepo.addExercise(treinoId, exId);

      await _pump(tester, db, treinoId);
      await tester.tap(find.text('INICIAR TREINO'));
      await tester.pumpAndSettle();

      await _registrarSerie(tester, carga: '30', reps: '10');
      await _fecharDialogosSeHouver(tester);
      await _registrarSerie(tester, carga: '30', reps: '10');
      await _fecharDialogosSeHouver(tester);
      await _registrarSerie(tester, carga: '32', reps: '8');
      await _fecharDialogosSeHouver(tester);

      expect(find.text('SÉRIE 01'), findsOneWidget);
      expect(find.text('SÉRIE 02'), findsOneWidget);
      expect(find.text('SÉRIE 03'), findsOneWidget);
      expect(find.text('32.0 KG × 8'), findsOneWidget);

      final linhas = await db.select(db.setEntries).get();
      expect(linhas.length, 3);

      await _finish(tester, db);
    });

    testWidgets('sem PR ainda, a caixa PR ATUAL não aparece', (tester) async {
      final db = _memoryDb();
      final exId = await _criarExercicio(db, 'Supino reto');
      final templateRepo = DriftWorkoutTemplateRepository(db);
      final treinoId = await templateRepo.create('Treino A');
      await templateRepo.addExercise(treinoId, exId);

      await _pump(tester, db, treinoId);
      await tester.tap(find.text('INICIAR TREINO'));
      await tester.pumpAndSettle();

      expect(find.text('PR ATUAL'), findsNothing);

      await _finish(tester, db);
    });

    testWidgets('com PR existente, a caixa PR ATUAL mostra o valor real',
        (tester) async {
      final db = _memoryDb();
      final exId = await _criarExercicio(db, 'Supino reto');
      final templateRepo = DriftWorkoutTemplateRepository(db);
      final treinoId = await templateRepo.create('Treino A');
      await templateRepo.addExercise(treinoId, exId);

      // Registra um PR de verdade através do fluxo real (repositório), sem
      // tocar na tela, só pra ter um PR já existente quando a tela abrir.
      final container = ProviderContainer(
          overrides: [appDatabaseProvider.overrideWithValue(db)]);
      final sessionRepo = container.read(workoutSessionRepositoryProvider);
      final primeiraSessaoId = await sessionRepo.start(nome: 'Treino anterior');
      await sessionRepo.logSet(
          sessionId: primeiraSessaoId,
          exerciseId: exId,
          repeticoes: 5,
          carga: 65);
      await sessionRepo.finish(primeiraSessaoId,
          duracao: const Duration(minutes: 10));
      container.dispose();

      await _pump(tester, db, treinoId);
      await tester.tap(find.text('INICIAR TREINO'));
      await tester.pumpAndSettle();

      expect(find.text('PR ATUAL'), findsOneWidget);
      expect(find.text('65.0 KG'), findsOneWidget);

      await _finish(tester, db);
    });
  });

  group('finalizar exercício e finalizar treino', () {
    testWidgets(
        'finalizar exercício esconde a nova série, persiste no banco e retornar traz de volta',
        (tester) async {
      final db = _memoryDb();
      final templateRepo = DriftWorkoutTemplateRepository(db);
      final treinoId = await templateRepo.create('Treino A');
      final ex1 = await _criarExercicio(db, 'Supino reto');
      final ex2 = await _criarExercicio(db, 'Agachamento');
      await templateRepo.addExercise(treinoId, ex1);
      await templateRepo.addExercise(treinoId, ex2);

      await _pump(tester, db, treinoId);
      await tester.tap(find.text('INICIAR TREINO'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('FINALIZAR EXERCÍCIO'));
      await tester.tap(find.text('FINALIZAR EXERCÍCIO'));
      await tester.pumpAndSettle();

      // Campos e botões somem; só resta "Retornar ao exercício".
      expect(find.text('RETORNAR AO EXERCÍCIO'), findsOneWidget);
      expect(find.byKey(const Key('workout_carga_field')), findsNothing);
      expect(find.byKey(const Key('workout_reps_field')), findsNothing);
      expect(find.text('REGISTRAR SÉRIE'), findsNothing);
      expect(find.text('FINALIZAR EXERCÍCIO'), findsNothing);
      // Continua no mesmo exercício e não cria dado de série/diálogo.
      expect(find.text('01 / 02'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(await db.select(db.setEntries).get(), isEmpty);
      final salvos = await db.select(db.finishedExercises).get();
      expect(salvos.map((f) => f.exerciseId), [ex1]);

      await tester.ensureVisible(find.text('RETORNAR AO EXERCÍCIO'));
      await tester.tap(find.text('RETORNAR AO EXERCÍCIO'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('workout_carga_field')), findsOneWidget);
      expect(find.text('REGISTRAR SÉRIE'), findsOneWidget);
      expect(await db.select(db.finishedExercises).get(), isEmpty);

      await _finish(tester, db);
    });

    testWidgets('exercício finalizado continua finalizado ao reabrir a sessão',
        (tester) async {
      final db = _memoryDb();
      final templateRepo = DriftWorkoutTemplateRepository(db);
      final treinoId = await templateRepo.create('Treino A');
      final ex1 = await _criarExercicio(db, 'Supino reto');
      await templateRepo.addExercise(treinoId, ex1);

      await _pump(tester, db, treinoId);
      await tester.tap(find.text('INICIAR TREINO'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('FINALIZAR EXERCÍCIO'));
      await tester.tap(find.text('FINALIZAR EXERCÍCIO'));
      await tester.pumpAndSettle();

      // Simula "fechar e reabrir o app": volta ao detalhe e entra de novo.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('INICIAR TREINO'));
      await tester.pumpAndSettle();

      expect(find.text('RETORNAR AO EXERCÍCIO'), findsOneWidget);
      expect(find.byKey(const Key('workout_carga_field')), findsNothing);

      await _finish(tester, db);
    });

    testWidgets(
        'finalizar treino exige confirmação e cancelar não encerra a sessão',
        (tester) async {
      final db = _memoryDb();
      final exId = await _criarExercicio(db, 'Supino reto');
      final templateRepo = DriftWorkoutTemplateRepository(db);
      final treinoId = await templateRepo.create('Treino A');
      await templateRepo.addExercise(treinoId, exId);

      await _pump(tester, db, treinoId);
      await tester.tap(find.text('INICIAR TREINO'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('FINALIZAR TREINO'));
      await tester.pumpAndSettle();
      expect(find.text('ENCERRAR TREINO?'), findsOneWidget);

      await tester.tap(find.text('CANCELAR'));
      await tester.pumpAndSettle();

      expect(find.text('ENCERRAR TREINO?'), findsNothing);
      final sessao = await (db.select(db.workoutSessions)).getSingle();
      expect(sessao.status, WorkoutSessionStatus.emAndamento);

      await _finish(tester, db);
    });

    testWidgets(
        'fluxo completo: inicia, registra série (sem PR), finaliza (missão+conquista) e volta',
        (tester) async {
      final db = _memoryDb();
      final exercicioId = await _criarExercicio(db, 'Supino reto');
      final templateRepo = DriftWorkoutTemplateRepository(db);
      final treinoId = await templateRepo.create('Treino A');
      await templateRepo.addExercise(treinoId, exercicioId);
      // 1 treino programado na semana: finalizar este conclui a semanal.
      await db
          .into(db.scheduleDays)
          .insert(ScheduleDaysCompanion.insert(weekday: const Value(1)));

      await _pump(tester, db, treinoId);
      await tester.tap(find.text('INICIAR TREINO'));
      await tester.pumpAndSettle();

      expect(find.text('SUPINO RETO'), findsOneWidget);
      expect(find.textContaining('DURAÇÃO:'), findsOneWidget);

      await _registrarSerie(tester, carga: '30', reps: '10');

      expect(find.text('30.0 KG × 10'), findsOneWidget);

      // A primeira série só estabelece a referência: nada de PR/diálogo.
      expect(find.text('NOVO RECORDE'), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);

      await tester.tap(find.text('FINALIZAR TREINO'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('FINALIZAR'));
      await tester.pumpAndSettle();

      // Finalizar o único treino programado bate a missão semanal.
      expect(find.text('MISSÃO CONCLUÍDA'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // E desbloqueia a conquista "Primeiros Passos".
      expect(find.text('CONQUISTA DESBLOQUEADA'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Voltou para a tela de detalhe do treino (não mais a sessão ativa).
      // Depois de finalizar a tela continua aberta, em modo "finalizado":
      // sem os campos de nova série e sem opção de reabrir o treino.
      expect(find.text('TREINO FINALIZADO'), findsOneWidget);
      expect(find.text('RETORNAR TREINO'), findsNothing);
      expect(find.text('REGISTRAR SÉRIE'), findsNothing);
      expect(find.text('FINALIZAR TREINO'), findsNothing);

      final sessao = await (db.select(db.workoutSessions)).getSingle();
      expect(sessao.status, WorkoutSessionStatus.concluido);

      await _finish(tester, db);
    });
  });

  group('PR só depois de uma referência', () {
    testWidgets('com treino anterior, superar o melhor mostra o diálogo de PR',
        (tester) async {
      final db = _memoryDb();
      final exId = await _criarExercicio(db, 'Supino reto');
      final templateRepo = DriftWorkoutTemplateRepository(db);
      final treinoId = await templateRepo.create('Treino A');
      await templateRepo.addExercise(treinoId, exId);

      final container = ProviderContainer(
          overrides: [appDatabaseProvider.overrideWithValue(db)]);
      final sessionRepo = container.read(workoutSessionRepositoryProvider);
      final anterior = await sessionRepo.start(nome: 'Treino anterior');
      await sessionRepo.logSet(
          sessionId: anterior, exerciseId: exId, repeticoes: 10, carga: 30);
      await sessionRepo.finish(anterior, duracao: const Duration(minutes: 10));
      container.dispose();

      await _pump(tester, db, treinoId);
      await tester.tap(find.text('INICIAR TREINO'));
      await tester.pumpAndSettle();

      await _registrarSerie(tester, carga: '32', reps: '10');

      expect(find.text('NOVO RECORDE'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await _finish(tester, db);
    });
  });

  group('rascunho de série persistido', () {
    testWidgets('carga e repetições digitadas voltam depois de reabrir o app',
        (tester) async {
      final db = _memoryDb();
      final exId = await _criarExercicio(db, 'Supino reto');
      final templateRepo = DriftWorkoutTemplateRepository(db);
      final treinoId = await templateRepo.create('Treino A');
      await templateRepo.addExercise(treinoId, exId);

      await _pump(tester, db, treinoId);
      await tester.tap(find.text('INICIAR TREINO'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
            of: find.byKey(const Key('workout_carga_field')),
            matching: find.byType(TextField)),
        '42,5',
      );
      await tester.enterText(
        find.descendant(
            of: find.byKey(const Key('workout_reps_field')),
            matching: find.byType(TextField)),
        '8',
      );
      await tester.pumpAndSettle();

      final salvo = await db.select(db.setDrafts).getSingle();
      expect(salvo.carga, '42,5');
      expect(salvo.reps, '8');

      // "Fecha o app": derruba toda a árvore e os providers (cache em
      // memória some); o banco permanece.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));

      await _pump(tester, db, treinoId);
      await tester.tap(find.text('INICIAR TREINO'));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TextField>(find.descendant(
                of: find.byKey(const Key('workout_carga_field')),
                matching: find.byType(TextField)))
            .controller!
            .text,
        '42,5',
      );
      expect(
        tester
            .widget<TextField>(find.descendant(
                of: find.byKey(const Key('workout_reps_field')),
                matching: find.byType(TextField)))
            .controller!
            .text,
        '8',
      );

      await _finish(tester, db);
    });

    testWidgets('registrar a série ou finalizar o treino apaga o rascunho',
        (tester) async {
      final db = _memoryDb();
      final exId = await _criarExercicio(db, 'Supino reto');
      final templateRepo = DriftWorkoutTemplateRepository(db);
      final treinoId = await templateRepo.create('Treino A');
      await templateRepo.addExercise(treinoId, exId);

      await _pump(tester, db, treinoId);
      await tester.tap(find.text('INICIAR TREINO'));
      await tester.pumpAndSettle();
      await _registrarSerie(tester, carga: '30', reps: '10');
      expect(await db.select(db.setDrafts).get(), isEmpty);

      await tester.enterText(
        find.descendant(
            of: find.byKey(const Key('workout_carga_field')),
            matching: find.byType(TextField)),
        '35',
      );
      await tester.pumpAndSettle();
      expect(await db.select(db.setDrafts).get(), hasLength(1));

      await tester.tap(find.text('FINALIZAR TREINO'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('FINALIZAR'));
      await tester.pumpAndSettle();
      await _fecharDialogosSeHouver(tester);
      expect(await db.select(db.setDrafts).get(), isEmpty);

      await _finish(tester, db);
    });
  });

  group('Android back e navigation bar', () {
    testWidgets('botão voltar do Android volta pro detalhe do treino',
        (tester) async {
      final db = _memoryDb();
      final exId = await _criarExercicio(db, 'Supino reto');
      final templateRepo = DriftWorkoutTemplateRepository(db);
      final treinoId = await templateRepo.create('Treino A');
      await templateRepo.addExercise(treinoId, exId);

      await _pump(tester, db, treinoId);
      await tester.tap(find.text('INICIAR TREINO'));
      await tester.pumpAndSettle();
      expect(find.textContaining('DURAÇÃO:'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('DURAÇÃO:'), findsNothing);
      expect(find.byTooltip('Editar treino'), findsOneWidget);

      await _finish(tester, db);
    });

    testWidgets('a navigation bar das 6 abas não aparece na sessão ativa',
        (tester) async {
      final db = _memoryDb();
      final exId = await _criarExercicio(db, 'Supino reto');
      final templateRepo = DriftWorkoutTemplateRepository(db);
      final treinoId = await templateRepo.create('Treino A');
      await templateRepo.addExercise(treinoId, exId);

      await _pump(tester, db, treinoId);
      await tester.tap(find.text('INICIAR TREINO'));
      await tester.pumpAndSettle();

      expect(find.byType(SystemNavigationBar), findsNothing);

      await _finish(tester, db);
    });
  });

  group('responsividade', () {
    testWidgets('320px de largura não estoura', (tester) async {
      final db = _memoryDb();
      final exId = await _criarExercicio(db, 'Supino reto');
      final templateRepo = DriftWorkoutTemplateRepository(db);
      final treinoId = await templateRepo.create('Treino A');
      await templateRepo.addExercise(treinoId, exId);

      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;

      await _pump(tester, db, treinoId);
      await tester.tap(find.text('INICIAR TREINO'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await _finish(tester, db);
    });

    testWidgets('text scaling elevado não estoura', (tester) async {
      final db = _memoryDb();
      final exId = await _criarExercicio(db, 'Supino reto');
      final templateRepo = DriftWorkoutTemplateRepository(db);
      final treinoId = await templateRepo.create('Treino A');
      await templateRepo.addExercise(treinoId, exId);

      tester.view.platformDispatcher.textScaleFactorTestValue = 1.8;

      await _pump(tester, db, treinoId);
      await tester.tap(find.text('INICIAR TREINO'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      tester.view.platformDispatcher.clearTextScaleFactorTestValue();
      await _finish(tester, db);
    });

    testWidgets('teclado aberto mantém campos e botão acessíveis, sem overflow',
        (tester) async {
      final db = _memoryDb();
      final exId = await _criarExercicio(db, 'Supino reto');
      final templateRepo = DriftWorkoutTemplateRepository(db);
      final treinoId = await templateRepo.create('Treino A');
      await templateRepo.addExercise(treinoId, exId);

      await _pump(tester, db, treinoId);
      await tester.tap(find.text('INICIAR TREINO'));
      await tester.pumpAndSettle();

      await tester.tap(find.descendant(
        of: find.byKey(const Key('workout_carga_field')),
        matching: find.byType(TextField),
      ));
      await tester.pumpAndSettle();
      // Simula o viewInset que o teclado real adicionaria.
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('REGISTRAR SÉRIE'), findsOneWidget);

      tester.view.resetViewInsets();
      await _finish(tester, db);
    });

    testWidgets('muitas séries registradas não estouram o layout',
        (tester) async {
      final db = _memoryDb();
      final exId = await _criarExercicio(db, 'Supino reto');
      final templateRepo = DriftWorkoutTemplateRepository(db);
      final treinoId = await templateRepo.create('Treino A');
      await templateRepo.addExercise(treinoId, exId);

      await _pump(tester, db, treinoId);
      await tester.tap(find.text('INICIAR TREINO'));
      await tester.pumpAndSettle();

      for (var i = 0; i < 10; i++) {
        await _registrarSerie(tester, carga: '30', reps: '10');
        await _fecharDialogosSeHouver(tester);
      }

      expect(tester.takeException(), isNull);
      final linhas = await db.select(db.setEntries).get();
      expect(linhas.length, 10);

      await _finish(tester, db);
    });
  });
}

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_system/database/app_database.dart';
import 'package:gym_system/database/database_provider.dart';
import 'package:gym_system/features/workouts/data/workout_template_repository_impl.dart';
import 'package:gym_system/features/workouts/domain/workout_session.dart';
import 'package:gym_system/features/workouts/presentation/active_workout_screen.dart';
import 'package:gym_system/features/workouts/presentation/workout_form_screen.dart';
import 'package:gym_system/features/workouts/presentation/workout_template_detail_screen.dart';
import 'package:gym_system/features/workouts/presentation/workouts_screen.dart';

/// Depois de um toque que dispara uma escrita assíncrona no banco (criar
/// treino, adicionar exercício...), `pumpAndSettle` sozinho pode retornar
/// antes da Future terminar (nenhum frame fica agendado enquanto ela
/// espera) — alguns frames curtos primeiro deixam a escrita concluir.
Future<void> _aguardar(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}

AppDatabase _memoryDb() => AppDatabase.forTesting(NativeDatabase.memory());

Future<int> _criarExercicio(AppDatabase db, String nome,
    {String grupoMuscular = 'Peito'}) {
  return db.into(db.exercises).insert(
      ExercisesCompanion.insert(nome: nome, grupoMuscular: grupoMuscular));
}

GoRouter _router() => GoRouter(
      initialLocation: '/workouts',
      routes: [
        GoRoute(
          path: '/workouts',
          builder: (context, state) => const WorkoutsScreen(),
        ),
        GoRoute(
          path: '/exercises',
          builder: (context, state) =>
              const Scaffold(body: Text('EXERCICIOS_DESTINO')),
        ),
        GoRoute(
          path: '/workouts/new',
          builder: (context, state) => const WorkoutFormScreen(),
        ),
        GoRoute(
          path: '/workouts/:id',
          builder: (context, state) => WorkoutTemplateDetailScreen(
              templateId: int.parse(state.pathParameters['id']!)),
        ),
        GoRoute(
          path: '/workouts/:id/edit',
          builder: (context, state) => WorkoutFormScreen(
              templateId: int.parse(state.pathParameters['id']!)),
        ),
        GoRoute(
          path: '/sessions/:id',
          builder: (context, state) => ActiveWorkoutScreen(
              sessionId: int.parse(state.pathParameters['id']!)),
        ),
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
  await _aguardar(tester);
  await tester.ensureVisible(find.text('REGISTRAR SÉRIE'));
  await tester.tap(find.text('REGISTRAR SÉRIE'));
  await _aguardar(tester);
}

Future<void> _fecharDialogosSeHouver(WidgetTester tester) async {
  while (find.text('OK').evaluate().isNotEmpty) {
    await tester.tap(find.text('OK').first);
    await _aguardar(tester);
  }
}

void main() {
  testWidgets('a aba Treinos dá acesso ao cadastro de exercícios',
      (tester) async {
    final db = _memoryDb();
    await _pump(tester, db);

    await tester.tap(find.text('EXERCÍCIOS'));
    await _aguardar(tester);

    expect(find.text('EXERCICIOS_DESTINO'), findsOneWidget);

    await _finish(tester, db);
  });

  testWidgets('lista vazia mostra estado vazio e permite criar um treino',
      (tester) async {
    final db = _memoryDb();
    await _pump(tester, db);

    expect(find.text('NENHUM TREINO CADASTRADO'), findsOneWidget);

    await tester.tap(find.text('NOVO TREINO'));
    await _aguardar(tester);
    expect(find.text('CRIAR PROTOCOLO'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Treino A');
    await tester.pump();
    await tester.tap(find.text('CRIAR TREINO'));
    await _aguardar(tester);

    // Navegou automaticamente pro detalhe do treino criado.
    expect(find.text('PROTOCOLO DE TREINAMENTO'), findsOneWidget);
    expect(find.text('NENHUM EXERCÍCIO ADICIONADO'), findsOneWidget);

    await _finish(tester, db);
  });

  testWidgets(
      'treino sem exercícios não deixa iniciar sessão; adicionar exercício libera',
      (tester) async {
    final db = _memoryDb();
    await _criarExercicio(db, 'Supino reto');
    await DriftWorkoutTemplateRepository(db).create('Treino A');

    await _pump(tester, db);
    await tester.tap(find.text('ABRIR'));
    await _aguardar(tester);

    expect(find.text('NENHUM EXERCÍCIO ADICIONADO'), findsOneWidget);
    await tester.tap(find.text('INICIAR TREINO'), warnIfMissed: false);
    await _aguardar(tester);
    // Não navegou pra nenhuma sessão: continuamos na tela de detalhe.
    expect(find.text('PROTOCOLO DE TREINAMENTO'), findsOneWidget);

    await tester.tap(find.text('ADICIONAR EXERCÍCIO'));
    await _aguardar(tester);
    await tester.tap(find.text('SUPINO RETO'));
    await _aguardar(tester);

    expect(find.text('SUPINO RETO'), findsOneWidget);
    expect(find.text('NENHUM EXERCÍCIO ADICIONADO'), findsNothing);

    await tester.tap(find.text('INICIAR TREINO'));
    await _aguardar(tester);

    // Entrou na sessão ativa — carrossel de 1 exercício.
    expect(find.textContaining('01 / 01'), findsOneWidget);
    expect(find.text('SUPINO RETO'), findsOneWidget);

    await _finish(tester, db);
  });

  testWidgets(
      'treino com 1 exercício: contador 01/01 e setas de navegação desabilitadas',
      (tester) async {
    final db = _memoryDb();
    final exId = await _criarExercicio(db, 'Supino reto');
    final templateRepo = DriftWorkoutTemplateRepository(db);
    final templateId = await templateRepo.create('Treino A');
    await templateRepo.addExercise(templateId, exId);

    await _pump(tester, db);
    await tester.tap(find.text('ABRIR'));
    await _aguardar(tester);
    await tester.tap(find.text('INICIAR TREINO'));
    await _aguardar(tester);

    expect(find.textContaining('01 / 01'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);

    // As duas setas existem mas não têm navegação possível (onPressed nulo).
    await tester.tap(find.byIcon(Icons.chevron_left), warnIfMissed: false);
    await tester.tap(find.byIcon(Icons.chevron_right), warnIfMissed: false);
    await _aguardar(tester);
    expect(find.textContaining('01 / 01'), findsOneWidget);

    await _finish(tester, db);
  });

  testWidgets(
      'fluxo completo: inicia, registra série, avança, volta, finaliza treino',
      (tester) async {
    final db = _memoryDb();
    final ex1 = await _criarExercicio(db, 'Supino reto');
    final ex2 = await _criarExercicio(db, 'Crucifixo');
    final templateRepo = DriftWorkoutTemplateRepository(db);
    final templateId = await templateRepo.create('Treino A');
    await templateRepo.addExercise(templateId, ex1);
    await templateRepo.addExercise(templateId, ex2);

    await _pump(tester, db);
    await tester.tap(find.text('ABRIR'));
    await _aguardar(tester);
    await tester.tap(find.text('INICIAR TREINO'));
    await _aguardar(tester);

    expect(find.textContaining('01 / 02'), findsOneWidget);
    expect(find.text('SUPINO RETO'), findsOneWidget);

    await _registrarSerie(tester, carga: '30', reps: '10');
    await _fecharDialogosSeHouver(tester);

    expect(find.text('30.0 KG × 10'), findsOneWidget);

    await tester.ensureVisible(find.byIcon(Icons.chevron_right));
    await tester.tap(find.byIcon(Icons.chevron_right));
    await _aguardar(tester);
    expect(find.textContaining('02 / 02'), findsOneWidget);
    expect(find.text('CRUCIFIXO'), findsOneWidget);

    await tester.ensureVisible(find.byIcon(Icons.chevron_left));
    await tester.tap(find.byIcon(Icons.chevron_left));
    await _aguardar(tester);
    expect(find.textContaining('01 / 02'), findsOneWidget);
    // A série registrada antes de avançar continua lá.
    expect(find.text('30.0 KG × 10'), findsOneWidget);

    await tester.tap(find.text('FINALIZAR TREINO'));
    await _aguardar(tester);
    await tester.tap(find.text('FINALIZAR'));
    await _aguardar(tester);
    await _fecharDialogosSeHouver(tester);

    final sessao = await (db.select(db.workoutSessions)).getSingle();
    expect(sessao.status, WorkoutSessionStatus.concluido);

    await _finish(tester, db);
  });

  testWidgets('editar treino atualiza o nome', (tester) async {
    final db = _memoryDb();
    await DriftWorkoutTemplateRepository(db).create('Treino A');

    await _pump(tester, db);
    await tester.tap(find.text('ABRIR'));
    await _aguardar(tester);

    await tester.tap(find.byTooltip('Editar treino'));
    await _aguardar(tester);
    expect(find.text('EDITAR PROTOCOLO'), findsOneWidget);

    final campo = find.byType(TextField);
    await tester.enterText(campo, 'Treino B');
    await tester.pump();
    await tester.tap(find.text('SALVAR ALTERAÇÕES'));
    await _aguardar(tester);

    expect(find.text('TREINO B'), findsOneWidget);

    await _finish(tester, db);
  });

  testWidgets('editar o exercício permite mudar a posição dele no treino',
      (tester) async {
    final db = _memoryDb();
    final a = await _criarExercicio(db, 'Supino reto');
    final b = await _criarExercicio(db, 'Crucifixo');
    final c = await _criarExercicio(db, 'Tríceps corda');
    final templateRepo = DriftWorkoutTemplateRepository(db);
    final templateId = await templateRepo.create('Treino A');
    await templateRepo.addExercise(templateId, a);
    await templateRepo.addExercise(templateId, b);
    await templateRepo.addExercise(templateId, c);

    await _pump(tester, db);
    await tester.tap(find.text('ABRIR'));
    await _aguardar(tester);

    double topo(String nome) => tester.getTopLeft(find.text(nome)).dy;
    expect(topo('SUPINO RETO'), lessThan(topo('TRÍCEPS CORDA')));

    // Não existe mais arrastar pra reordenar.
    expect(find.byType(ReorderableListView), findsNothing);

    // Terceiro exercício sobe duas posições pelo editar.
    await tester.tap(find.byTooltip('Editar exercício').at(2));
    await _aguardar(tester);
    expect(find.text('03 / 03'), findsOneWidget);
    await tester.tap(find.byTooltip('Subir posição'));
    await tester.pump();
    await tester.tap(find.byTooltip('Subir posição'));
    await tester.pump();
    expect(find.text('01 / 03'), findsOneWidget);
    await tester.tap(find.text('SALVAR POSIÇÃO'));
    await _aguardar(tester);

    expect(topo('TRÍCEPS CORDA'), lessThan(topo('SUPINO RETO')));
    expect(topo('SUPINO RETO'), lessThan(topo('CRUCIFIXO')));

    await _finish(tester, db);
  });

  testWidgets('remover exercício tira ele da lista do treino', (tester) async {
    final db = _memoryDb();
    final exId = await _criarExercicio(db, 'Supino reto');
    final templateRepo = DriftWorkoutTemplateRepository(db);
    final templateId = await templateRepo.create('Treino A');
    await templateRepo.addExercise(templateId, exId);

    await _pump(tester, db);
    await tester.tap(find.text('ABRIR'));
    await _aguardar(tester);

    expect(find.text('SUPINO RETO'), findsOneWidget);
    await tester.tap(find.byTooltip('Remover exercício'));
    await _aguardar(tester);

    expect(find.text('SUPINO RETO'), findsNothing);
    expect(find.text('NENHUM EXERCÍCIO ADICIONADO'), findsOneWidget);

    await _finish(tester, db);
  });

  testWidgets('botão voltar do Android sai da sessão ativa pro detalhe',
      (tester) async {
    final db = _memoryDb();
    final exId = await _criarExercicio(db, 'Supino reto');
    final templateRepo = DriftWorkoutTemplateRepository(db);
    final templateId = await templateRepo.create('Treino A');
    await templateRepo.addExercise(templateId, exId);

    await _pump(tester, db);
    await tester.tap(find.text('ABRIR'));
    await _aguardar(tester);
    await tester.tap(find.text('INICIAR TREINO'));
    await _aguardar(tester);

    expect(find.textContaining('01 / 01'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await _aguardar(tester);

    expect(find.text('PROTOCOLO DE TREINAMENTO'), findsOneWidget);

    await _finish(tester, db);
  });
}

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/app/app.dart';
import 'package:gym_system/app/router.dart';
import 'package:gym_system/database/app_database.dart';
import 'package:gym_system/database/database_provider.dart';
import 'package:gym_system/design_system/system_navigation_bar.dart';
import 'package:gym_system/features/workouts/data/workout_template_repository_impl.dart';

/// Testes de ponta a ponta da navegação principal (Fase 4): a [App] real,
/// com o `appRouter` real e um banco em memória isolado por teste.
AppDatabase _memoryDb() => AppDatabase.forTesting(NativeDatabase.memory());

Future<void> _pumpApp(WidgetTester tester, AppDatabase db) async {
  // `appRouter` é um singleton do app inteiro (reaproveitado por todos os
  // testes deste arquivo); sem resetar a localização aqui, cada teste
  // herdaria a navegação de onde o teste anterior parou.
  appRouter.go('/');

  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Desmonta a árvore e só então fecha o banco — nessa ordem, e *dentro do
/// corpo do teste* (não via `addTearDown`: o binding verifica timers
/// pendentes logo depois do corpo do teste retornar, antes de qualquer
/// `addTearDown` rodar). O Drift agenda um `Timer.run` ao perder o último
/// listener de um stream (pra não descartar cache cedo demais); sem
/// desmontar a árvore e dar um `pump` antes de fechar o banco, esse timer
/// fica pendente e o binding acusa erro na troca pro próximo teste.
Future<void> _finish(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 50));
  await db.close();
}

/// O cadastro de exercícios fica na aba TREINOS (não mais na tela Sistema).
Future<void> _abrirExercicios(WidgetTester tester) async {
  await tester.tap(find.text('TREINOS'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('EXERCÍCIOS'));
  await tester.tap(find.text('EXERCÍCIOS'));
  await tester.pumpAndSettle();
}

void main() {
  group('abas principais', () {
    testWidgets('inicializa na aba Sistema com a navigation bar visível',
        (tester) async {
      final db = _memoryDb();
      await _pumpApp(tester, db);

      expect(find.text('SYSTEM ONLINE'), findsOneWidget);
      expect(find.byType(SystemNavigationBar), findsOneWidget);
      expect(find.text('SISTEMA'), findsOneWidget); // label da aba ativa

      await _finish(tester, db);
    });

    testWidgets('Sistema → Treinos → Missões → Status → Conquistas → Sistema',
        (tester) async {
      final db = _memoryDb();
      await _pumpApp(tester, db);

      await tester.tap(find.text('TREINOS'));
      await tester.pumpAndSettle();
      expect(find.text('PROTOCOLOS DE TREINAMENTO'), findsOneWidget);

      await tester.tap(find.text('MISSÕES'));
      await tester.pumpAndSettle();
      // Missões usa SystemScaffold desde a Fase 7 (sem AppBar).
      expect(find.text('QUEST LOG'), findsOneWidget);

      await tester.tap(find.text('STATUS'));
      await tester.pumpAndSettle();
      // Status usa SystemScaffold desde a Fase 8 (sem AppBar).
      expect(find.text('FICHA DO CAÇADOR'), findsOneWidget);

      await tester.tap(find.text('CONQUISTAS'));
      await tester.pumpAndSettle();
      // Conquistas usa SystemScaffold desde a Fase 8 (sem AppBar).
      expect(find.text('TROFÉUS DO SISTEMA'), findsOneWidget);

      await tester.tap(find.text('SISTEMA'));
      await tester.pumpAndSettle();
      expect(find.text('SYSTEM ONLINE'), findsOneWidget);

      await _finish(tester, db);
    });

    testWidgets(
        'a aba ATIVIDADES fica entre Treinos e Missões e abre as modalidades',
        (tester) async {
      final db = _memoryDb();
      await _pumpApp(tester, db);

      final nav = find.byType(SystemNavigationBar);
      double x(String label) => tester
          .getCenter(find.descendant(of: nav, matching: find.text(label)))
          .dx;
      final ordem = [
        'SISTEMA',
        'TREINOS',
        'ATIVIDADES',
        'MISSÕES',
        'STATUS',
        'CONQUISTAS'
      ];
      for (var i = 0; i < ordem.length - 1; i++) {
        expect(x(ordem[i]), lessThan(x(ordem[i + 1])),
            reason: '${ordem[i]} antes de ${ordem[i + 1]}');
      }

      await tester
          .tap(find.descendant(of: nav, matching: find.text('ATIVIDADES')));
      await tester.pumpAndSettle();
      expect(find.text('REGISTRO ESPORTIVO'), findsOneWidget);
      expect(find.text('SKATE'), findsOneWidget);
      expect(find.byType(SystemNavigationBar), findsOneWidget);

      // Tela da modalidade é secundária: esconde a barra e voltar restaura.
      await tester.tap(find.text('SKATE'));
      await tester.pumpAndSettle();
      expect(find.text('ADICIONAR REGISTRO'), findsOneWidget);
      expect(find.byType(SystemNavigationBar), findsNothing);

      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();
      expect(find.text('REGISTRO ESPORTIVO'), findsOneWidget);
      expect(find.byType(SystemNavigationBar), findsOneWidget);

      // Treinos continua independente: não tem nenhuma modalidade esportiva.
      await tester
          .tap(find.descendant(of: nav, matching: find.text('TREINOS')));
      await tester.pumpAndSettle();
      expect(find.text('PROTOCOLOS DE TREINAMENTO'), findsOneWidget);
      expect(find.text('SKATE'), findsNothing);

      await _finish(tester, db);
    });

    testWidgets('a navigation bar está sempre visível nas 6 abas',
        (tester) async {
      final db = _memoryDb();
      await _pumpApp(tester, db);

      for (final label in [
        'TREINOS',
        'ATIVIDADES',
        'MISSÕES',
        'STATUS',
        'CONQUISTAS',
        'SISTEMA'
      ]) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(find.byType(SystemNavigationBar), findsOneWidget,
            reason: 'aba $label');
      }

      await _finish(tester, db);
    });

    testWidgets('trocar de aba repetidamente não acumula telas na pilha',
        (tester) async {
      final db = _memoryDb();
      await _pumpApp(tester, db);

      for (var i = 0; i < 5; i++) {
        await tester.tap(find.text('TREINOS'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('SISTEMA'));
        await tester.pumpAndSettle();
      }

      // Se houvesse acúmulo de páginas equivalentes empilhadas, haveria
      // mais de uma ocorrência destes widgets únicos da tela Sistema.
      expect(find.text('SYSTEM ONLINE'), findsOneWidget);
      expect(find.byType(AppBar),
          findsNothing); // Sistema usa SystemHeader, não AppBar

      await _finish(tester, db);
    });

    testWidgets('estado da aba Treinos é preservado ao trocar de aba e voltar',
        (tester) async {
      final db = _memoryDb();
      final repo = DriftWorkoutTemplateRepository(db);
      for (var i = 0; i < 30; i++) {
        await repo.create('Treino $i');
      }

      await _pumpApp(tester, db);
      await tester.tap(find.text('TREINOS'));
      await tester.pumpAndSettle();

      double offset() => tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels;

      expect(offset(), 0);
      await tester.drag(
          find.byType(SingleChildScrollView), const Offset(0, -800));
      await tester.pumpAndSettle();
      final rolado = offset();
      expect(rolado, greaterThan(0)); // rolou pra longe do topo

      // Troca pra outra aba e volta.
      await tester.tap(find.text('SISTEMA'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('TREINOS'));
      await tester.pumpAndSettle();

      // Se o branch tivesse sido reconstruído do zero, a lista teria
      // voltado pro topo (offset 0).
      expect(offset(), rolado);

      await _finish(tester, db);
    });

    testWidgets('indicador visual: só a aba ativa fica na cor primária',
        (tester) async {
      final db = _memoryDb();
      await _pumpApp(tester, db);

      Color labelColor(String label) {
        final text = tester.widget<Text>(find.descendant(
            of: find.byType(SystemNavigationBar), matching: find.text(label)));
        return text.style!.color!;
      }

      const primary = Color(0xFF00CDFD);
      expect(labelColor('SISTEMA'), primary);
      expect(labelColor('TREINOS'), isNot(primary));

      await tester.tap(find.text('TREINOS'));
      await tester.pumpAndSettle();

      expect(labelColor('TREINOS'), primary);
      expect(labelColor('SISTEMA'), isNot(primary));

      await _finish(tester, db);
    });
  });

  group('rotas secundárias', () {
    testWidgets(
        'abrir uma rota secundária esconde a navigation bar, voltar restaura',
        (tester) async {
      final db = _memoryDb();
      await _pumpApp(tester, db);

      await _abrirExercicios(tester);

      expect(find.text('BIBLIOTECA DE EXERCÍCIOS'), findsOneWidget);
      expect(find.byType(SystemNavigationBar), findsNothing);

      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();

      expect(find.text('PROTOCOLOS DE TREINAMENTO'), findsOneWidget);
      expect(find.byType(SystemNavigationBar), findsOneWidget);

      await _finish(tester, db);
    });

    testWidgets(
        'rota secundária aberta a partir de outra aba volta pra aba de origem',
        (tester) async {
      final db = _memoryDb();
      final repo = DriftWorkoutTemplateRepository(db);
      await repo.create('Treino A');

      await _pumpApp(tester, db);
      await tester.tap(find.text('TREINOS'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ABRIR'));
      await tester.pumpAndSettle();

      // O detalhe do treino tem o botão de editar no cabeçalho.
      expect(find.byTooltip('Editar treino'), findsOneWidget);
      expect(find.byType(SystemNavigationBar), findsNothing);

      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();

      // Voltou pra aba Treinos (não pro Sistema).
      expect(find.text('PROTOCOLOS DE TREINAMENTO'), findsOneWidget);
      expect(find.byType(SystemNavigationBar), findsOneWidget);

      await _finish(tester, db);
    });

    testWidgets('nenhuma rota existente ficou inacessível', (tester) async {
      final db = _memoryDb();
      final exercicioId = await db.into(db.exercises).insert(
            ExercisesCompanion.insert(
                nome: 'Supino reto', grupoMuscular: 'Peito'),
          );
      await _pumpApp(tester, db);

      // A tela Sistema agora rola (Fase 3/5): os atalhos no fim da página
      // (ex. "HISTÓRICO") podem estar fora da área visível
      // sem rolar até eles primeiro — sem isso, o tap acerta coordenadas
      // erradas (ex. a própria navigation bar, que fica fixa embaixo).
      await _abrirExercicios(tester);
      expect(find.text('BIBLIOTECA DE EXERCÍCIOS'), findsOneWidget);
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('SISTEMA'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('HISTÓRICO'));
      await tester.tap(find.text('HISTÓRICO'));
      await tester.pumpAndSettle();
      expect(find.text('LINHA DO TEMPO'), findsOneWidget);
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();

      // Perfil fica no cabeçalho (ícone, sem texto visível), não na lista
      // de atalhos do fim da página.
      await tester.tap(find.byTooltip('Perfil'));
      await tester.pumpAndSettle();
      expect(find.text('IDENTIDADE DO JOGADOR'), findsOneWidget);
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();

      expect(exercicioId, greaterThan(0));
      expect(find.text('SYSTEM ONLINE'), findsOneWidget);

      await _finish(tester, db);
    });
  });

  group('treino ativo', () {
    testWidgets('sessão ativa não mostra a navigation bar', (tester) async {
      final db = _memoryDb();
      final exercicioId = await db.into(db.exercises).insert(
            ExercisesCompanion.insert(
                nome: 'Supino reto', grupoMuscular: 'Peito'),
          );
      final templateRepo = DriftWorkoutTemplateRepository(db);
      final treinoId = await templateRepo.create('Treino A');
      await templateRepo.addExercise(treinoId, exercicioId);

      await _pumpApp(tester, db);
      await tester.tap(find.text('TREINOS'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ABRIR'));
      await tester.pumpAndSettle();

      expect(find.byType(SystemNavigationBar), findsNothing);

      await tester.tap(find.text('INICIAR TREINO'));
      await tester.pumpAndSettle();

      expect(find.text('Treino A'), findsOneWidget);
      expect(find.textContaining('DURAÇÃO:'), findsOneWidget);
      expect(find.byType(SystemNavigationBar), findsNothing);

      await _finish(tester, db);
    });
  });

  group('botão voltar do Android', () {
    testWidgets('na raiz (aba Sistema) não lança exceção nem cria loop',
        (tester) async {
      final db = _memoryDb();
      await _pumpApp(tester, db);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('SYSTEM ONLINE'), findsOneWidget);

      await _finish(tester, db);
    });

    testWidgets('fecha uma rota secundária e volta pra aba de origem',
        (tester) async {
      final db = _memoryDb();
      await _pumpApp(tester, db);

      await _abrirExercicios(tester);
      expect(find.text('BIBLIOTECA DE EXERCÍCIOS'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('PROTOCOLOS DE TREINAMENTO'), findsOneWidget);
      expect(find.byType(SystemNavigationBar), findsOneWidget);

      await _finish(tester, db);
    });
  });

  group('responsividade', () {
    testWidgets('320px de largura não estoura a navigation bar',
        (tester) async {
      final db = _memoryDb();
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;

      await _pumpApp(tester, db);

      expect(tester.takeException(), isNull);
      expect(find.text('CONQUISTAS'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await _finish(tester, db);
    });

    testWidgets('text scaling elevado não estoura a navigation bar',
        (tester) async {
      final db = _memoryDb();
      tester.view.platformDispatcher.textScaleFactorTestValue = 1.8;

      await _pumpApp(tester, db);

      expect(tester.takeException(), isNull);
      expect(find.text('CONQUISTAS'), findsOneWidget);

      tester.view.platformDispatcher.clearTextScaleFactorTestValue();
      await _finish(tester, db);
    });

    testWidgets('SafeArea inferior (gesto do Android) não esconde os itens',
        (tester) async {
      final db = _memoryDb();
      tester.view.padding = const FakeViewPadding(bottom: 34);

      await _pumpApp(tester, db);

      expect(tester.takeException(), isNull);
      expect(find.text('CONQUISTAS'), findsOneWidget);

      await tester.tap(find.text('CONQUISTAS'));
      await tester.pumpAndSettle();
      // Conquistas usa SystemScaffold desde a Fase 8 (sem AppBar).
      expect(find.text('TROFÉUS DO SISTEMA'), findsOneWidget);

      tester.view.resetPadding();
      await _finish(tester, db);
    });
  });
}

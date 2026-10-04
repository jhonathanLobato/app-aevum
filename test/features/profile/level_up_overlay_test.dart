import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/features/profile/presentation/level_up_overlay.dart';

Future<void> _abrir(
  WidgetTester tester, {
  required int nivelAnterior,
  required int novoNivel,
  String? rankAnterior,
  String? novoRank,
}) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showLevelUpOverlay(
            context,
            nivelAnterior: nivelAnterior,
            novoNivel: novoNivel,
            rankAnterior: rankAnterior,
            novoRank: novoRank,
          ),
          child: const Text('abrir'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  group('LevelUpOverlay', () {
    testWidgets('abre e mostra o nível anterior e o novo nível reais',
        (tester) async {
      await _abrir(tester, nivelAnterior: 12, novoNivel: 13);

      expect(find.text('LEVEL UP'), findsOneWidget);
      expect(find.text('LV. 12'), findsOneWidget);
      expect(find.text('LV. 13'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('sem mudança de rank, não mostra nenhum rank', (tester) async {
      await _abrir(
        tester,
        nivelAnterior: 12,
        novoNivel: 13,
        rankAnterior: 'E',
        novoRank: 'E',
      );

      expect(find.text('NOVO RANK'), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('com mudança real de rank, mostra o novo rank', (tester) async {
      await _abrir(
        tester,
        nivelAnterior: 9,
        novoNivel: 10,
        rankAnterior: 'F',
        novoRank: 'E',
      );

      expect(find.text('NOVO RANK'), findsOneWidget);
      expect(find.text('E'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('toque em qualquer lugar fecha o overlay', (tester) async {
      await _abrir(tester, nivelAnterior: 1, novoNivel: 2);
      expect(find.text('LEVEL UP'), findsOneWidget);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('LEVEL UP'), findsNothing);
    });

    testWidgets('botão Continuar fecha o overlay', (tester) async {
      await _abrir(tester, nivelAnterior: 1, novoNivel: 2);

      await tester.tap(find.text('CONTINUAR'));
      await tester.pumpAndSettle();
      expect(find.text('LEVEL UP'), findsNothing);
    });

    testWidgets('fecha sozinho depois do tempo de auto-close', (tester) async {
      await _abrir(tester, nivelAnterior: 1, novoNivel: 2);
      expect(find.text('LEVEL UP'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 4300));
      await tester.pumpAndSettle();
      expect(find.text('LEVEL UP'), findsNothing);
    });

    testWidgets('Reduced Motion mostra versão estática e funcional, sem travar',
        (tester) async {
      tester.view.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);

      await _abrir(
        tester,
        nivelAnterior: 9,
        novoNivel: 10,
        rankAnterior: 'F',
        novoRank: 'E',
      );

      expect(find.text('LEVEL UP'), findsOneWidget);
      expect(find.text('NOVO RANK'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Sem Reduced Motion, pumpAndSettle travaria (anéis/partículas em
      // loop) — aqui precisa concluir normalmente.
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('CONTINUAR'));
      await tester.pumpAndSettle();
      expect(find.text('LEVEL UP'), findsNothing);
    });

    testWidgets(
        'fechar antes do auto-close não deixa nenhum controller/timer pendente',
        (tester) async {
      // Reduced Motion (padrão global da suíte, ver flutter_test_config.dart)
      // já é suficiente pra esta checagem: o `_burstController` e o
      // `Timer` de auto-close existem de qualquer forma, com ou sem
      // animação visível — se não fossem descartados/cancelados em
      // `dispose()`, o binding acusaria isso ao encerrar o teste.
      await _abrir(tester, nivelAnterior: 1, novoNivel: 2);
      await tester.tap(find.text('CONTINUAR'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}

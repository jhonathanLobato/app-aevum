import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/design_system/system_background.dart';
import 'package:gym_system/design_system/system_online_indicator.dart';
import 'package:gym_system/design_system/system_scaffold.dart';

/// Ajusta a superfície de teste (`tester.view`) para o tamanho/escala de
/// texto/padding de SafeArea pedidos e faz o pump do [child] dentro de um
/// `MaterialApp`. Só trocar `MediaQueryData.size` manualmente não restringe
/// de fato o layout em um teste de widget — é preciso mudar a `view` real
/// que o binding usa, por isso o `tester.view.*`.
Future<void> _pumpScreen(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(390, 844),
  double textScaleFactor = 1.0,
  EdgeInsets viewPadding = EdgeInsets.zero,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  tester.view.padding = FakeViewPadding(
    top: viewPadding.top,
    bottom: viewPadding.bottom,
    left: viewPadding.left,
    right: viewPadding.right,
  );
  tester.view.platformDispatcher.textScaleFactorTestValue = textScaleFactor;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.view.resetPadding();
    tester.view.platformDispatcher.clearTextScaleFactorTestValue();
  });
  await tester.pumpWidget(MaterialApp(home: child));
}

void main() {
  group('SystemScaffold', () {
    testWidgets('renderiza título, subtítulo e body', (tester) async {
      await _pumpScreen(
        tester,
        const SystemScaffold(
          title: 'SYSTEM',
          subtitle: 'painel do jogador',
          body: Text('conteúdo da tela'),
        ),
      );

      expect(find.text('SYSTEM'), findsOneWidget);
      expect(find.text('PAINEL DO JOGADOR'), findsOneWidget);
      expect(find.text('conteúdo da tela'), findsOneWidget);
      expect(find.text('ONLINE'), findsOneWidget);
    });

    testWidgets('renderiza actions no cabeçalho', (tester) async {
      await _pumpScreen(
        tester,
        const SystemScaffold(
          title: 'STATUS',
          actions: [Icon(Icons.filter_list)],
          body: SizedBox(),
        ),
      );
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('header customizado substitui o padrão', (tester) async {
      await _pumpScreen(
        tester,
        const SystemScaffold(
          title: 'SYSTEM',
          header: Text('HEADER CUSTOMIZADO'),
          body: SizedBox(),
        ),
      );
      expect(find.text('HEADER CUSTOMIZADO'), findsOneWidget);
      expect(find.text('SYSTEM'), findsNothing);
      expect(find.text('ONLINE'), findsNothing);
    });

    testWidgets('navigationBar aparece abaixo do body', (tester) async {
      await _pumpScreen(
        tester,
        const SystemScaffold(
          title: 'SYSTEM',
          navigationBar:
              ColoredBox(color: Colors.black, child: SizedBox(height: 56)),
          body: SizedBox(),
        ),
      );
      expect(find.byType(ColoredBox), findsWidgets);
    });

    testWidgets('scrollable=true permite corpo maior que a tela sem estourar',
        (tester) async {
      await _pumpScreen(
        tester,
        SystemScaffold(
          title: 'SYSTEM',
          body: Column(
            children: List.generate(
              40,
              (i) => Padding(
                padding: const EdgeInsets.all(8),
                child: Text('item $i'),
              ),
            ),
          ),
        ),
        size: const Size(360, 600),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('item 0'), findsOneWidget);
    });

    testWidgets('scrollable=false não envolve o body num SingleChildScrollView',
        (tester) async {
      await _pumpScreen(
        tester,
        const SystemScaffold(
          title: 'SYSTEM',
          scrollable: false,
          body: Center(child: Text('fixo')),
        ),
      );
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(find.text('fixo'), findsOneWidget);
    });

    testWidgets(
        'não estoura em celular estreito com texto grande (text scaling)',
        (tester) async {
      await _pumpScreen(
        tester,
        const SystemScaffold(
          title: 'SYSTEM',
          subtitle: 'painel do jogador bem comprido para testar',
          actions: [Icon(Icons.settings)],
          body: Text('conteúdo'),
        ),
        size: const Size(320, 568),
        textScaleFactor: 1.8,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('não estoura em celular grande', (tester) async {
      await _pumpScreen(
        tester,
        const SystemScaffold(title: 'SYSTEM', body: Text('conteúdo')),
        size: const Size(480, 960),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('respeita SafeArea superior e inferior (notch/home indicator)',
        (tester) async {
      await _pumpScreen(
        tester,
        SystemScaffold(
          title: 'SYSTEM',
          body: Builder(
            builder: (context) =>
                Text('top=${MediaQuery.of(context).padding.top}'),
          ),
        ),
        viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
      );
      // A SafeArea consome o padding de notch/home-indicator antes do body;
      // o valor que o body recebe já deve vir sem o top reservado pro header.
      expect(find.text('top=0.0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fundo preenche a tela mesmo com pouco conteúdo',
        (tester) async {
      await _pumpScreen(
        tester,
        const SystemScaffold(title: 'SYSTEM', body: SizedBox(height: 10)),
      );
      final backgroundSize = tester.getSize(find.byType(SystemBackground));
      expect(backgroundSize, const Size(390, 844));
    });

    testWidgets('fundo não captura toque nem bloqueia o gesto do body',
        (tester) async {
      var tapped = false;
      await _pumpScreen(
        tester,
        SystemScaffold(
          title: 'SYSTEM',
          scrollable: false,
          body: Center(
            child: GestureDetector(
              onTap: () => tapped = true,
              child: const SizedBox(
                  width: 100,
                  height: 100,
                  child: ColoredBox(color: Colors.red)),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(GestureDetector));
      expect(tapped, isTrue);
    });
  });

  group('TechGridPainter', () {
    test('shouldRepaint só quando algum parâmetro muda', () {
      const a = TechGridPainter();
      const b = TechGridPainter();
      const c = TechGridPainter(spacing: 20);
      expect(a.shouldRepaint(b), isFalse);
      expect(a.shouldRepaint(c), isTrue);
    });

    test('não lança exceção pintando em tamanhos extremos', () {
      const painter = TechGridPainter();
      final canvas = Canvas(PictureRecorder());
      expect(() => painter.paint(canvas, const Size(1, 1)), returnsNormally);
      expect(
          () => painter.paint(canvas, const Size(2000, 3000)), returnsNormally);
      expect(() => painter.paint(canvas, Size.zero), returnsNormally);
    });
  });

  group('SystemOnlineIndicator', () {
    testWidgets('com Reduced Motion (padrão global), fica estático e visível',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: SystemOnlineIndicator()),
      ));

      expect(find.byType(SystemOnlineIndicator), findsOneWidget);
      // Sem Reduced Motion não existe nenhum AnimationController rodando —
      // pumpAndSettle precisa terminar sem travar.
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'sem Reduced Motion, a opacidade do ponto respira ao longo do tempo',
        (tester) async {
      tester.view.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: false);
      addTearDown(() {
        tester.view.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
      });

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: SystemOnlineIndicator()),
      ));

      double opacityOf() =>
          tester.widget<Opacity>(find.byType(Opacity)).opacity;

      await tester.pump();
      final primeiraLeitura = opacityOf();
      await tester.pump(const Duration(milliseconds: 500));
      final segundaLeitura = opacityOf();

      expect(primeiraLeitura, isNot(equals(segundaLeitura)));
      // Nunca pisca/some: a respiração fica sempre entre 55% e 100%.
      expect(primeiraLeitura, inInclusiveRange(0.55, 1.0));
      expect(segundaLeitura, inInclusiveRange(0.55, 1.0));
    });

    testWidgets(
        'TickerMode(enabled: false) pausa o pulso — simula a aba inativa do IndexedStack',
        (tester) async {
      tester.view.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: false);
      addTearDown(() {
        tester.view.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
      });

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: TickerMode(enabled: false, child: SystemOnlineIndicator()),
        ),
      ));

      // Se o ticker não estivesse realmente pausado, este pumpAndSettle
      // travaria (o controller fica em `repeat(reverse: true)` para
      // sempre) — terminar normalmente já é a prova de que o
      // `StatefulShellRoute.indexedStack` (que embrulha cada aba inativa
      // em `Offstage` + `TickerMode(enabled: false)`) é suficiente para
      // parar este pulso sozinho, sem nenhum código extra no app.
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('ScanlinePainter', () {
    test('shouldRepaint só quando algum parâmetro muda', () {
      const a = ScanlinePainter();
      const b = ScanlinePainter();
      const c = ScanlinePainter(opacity: 0.5);
      expect(a.shouldRepaint(b), isFalse);
      expect(a.shouldRepaint(c), isTrue);
    });

    test('não lança exceção pintando em tamanhos extremos', () {
      const painter = ScanlinePainter();
      final canvas = Canvas(PictureRecorder());
      expect(() => painter.paint(canvas, const Size(1, 1)), returnsNormally);
      expect(
          () => painter.paint(canvas, const Size(2000, 3000)), returnsNormally);
      expect(() => painter.paint(canvas, Size.zero), returnsNormally);
    });
  });
}

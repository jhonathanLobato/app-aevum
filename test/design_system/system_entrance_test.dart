import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/design_system/system_entrance.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('SystemEntrance', () {
    testWidgets(
        'com Reduced Motion (padrão global dos testes), o conteúdo aparece imediatamente sem nenhum wrapper de animação',
        (tester) async {
      await tester.pumpWidget(_wrap(const SystemEntrance(
        child: Text('conteúdo'),
      )));

      // Sem pump nenhum além do primeiro: já deve estar visível, sem esperar
      // o post-frame callback da animação (que nem chega a rodar) — o
      // widget.child é retornado direto, sem AnimatedOpacity/AnimatedSlide.
      expect(find.text('conteúdo'), findsOneWidget);
      expect(find.byType(AnimatedOpacity), findsNothing);
      expect(find.byType(AnimatedSlide), findsNothing);
    });

    testWidgets(
        'não bloqueia interação: um botão responde ao toque mesmo no meio da entrada (antes dela terminar)',
        (tester) async {
      tester.view.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: false);
      addTearDown(() {
        tester.view.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
      });

      var tapped = false;
      await tester.pumpWidget(_wrap(SystemEntrance(
        child: ElevatedButton(
          onPressed: () => tapped = true,
          child: const Text('TOCAR'),
        ),
      )));

      // Um único pump curto: o post-frame callback já ligou `_visible`, mas
      // a animação de fade/slide ainda está em andamento (não chegou a
      // `pumpAndSettle`) — o toque precisa funcionar mesmo assim.
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('TOCAR'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets(
        'sem Reduced Motion, entra com fade de 0 para 1 e depois fica parado',
        (tester) async {
      tester.view.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: false);
      addTearDown(() {
        tester.view.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
      });

      await tester.pumpWidget(_wrap(const SystemEntrance(
        child: Text('conteúdo'),
      )));

      // Primeiro frame: ainda não rodou o post-frame callback que liga
      // `_visible`, então a opacidade começa em 0.
      final opacityFinder = find.ancestor(
        of: find.text('conteúdo'),
        matching: find.byType(AnimatedOpacity),
      );
      expect(
        tester.widget<AnimatedOpacity>(opacityFinder).opacity,
        0,
      );

      // Depois do post-frame callback + a duração da animação, termina em 1.
      await tester.pumpAndSettle();
      expect(
        tester.widget<AnimatedOpacity>(opacityFinder).opacity,
        1,
      );
    });

    testWidgets(
        'rebuild do pai (ex.: texto mudando) não refaz a entrada do painel',
        (tester) async {
      tester.view.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: false);
      addTearDown(() {
        tester.view.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
      });

      final notifier = ValueNotifier('A');
      addTearDown(notifier.dispose);

      await tester.pumpWidget(_wrap(ValueListenableBuilder<String>(
        valueListenable: notifier,
        builder: (context, value, _) {
          return SystemEntrance(
            key: const ValueKey('painel-estavel'),
            child: Text(value),
          );
        },
      )));
      await tester.pumpAndSettle();

      Finder opacityFinderFor(String text) => find.ancestor(
            of: find.text(text),
            matching: find.byType(AnimatedOpacity),
          );

      expect(find.text('A'), findsOneWidget);
      expect(tester.widget<AnimatedOpacity>(opacityFinderFor('A')).opacity, 1);

      // Troca o conteúdo (simula XP mudando, stream emitindo): a mesma
      // chave/posição é reaproveitada, então o `State` da entrada não é
      // recriado — a opacidade continua em 1, nunca volta pra 0.
      notifier.value = 'B';
      await tester.pump();
      expect(find.text('B'), findsOneWidget);
      expect(tester.widget<AnimatedOpacity>(opacityFinderFor('B')).opacity, 1);
    });
  });
}

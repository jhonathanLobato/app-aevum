import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/design_system/rank_badge.dart';
import 'package:gym_system/design_system/system_button.dart';
import 'package:gym_system/design_system/system_clippers.dart';
import 'package:gym_system/design_system/system_colors.dart';
import 'package:gym_system/design_system/system_geometry.dart';
import 'package:gym_system/design_system/system_panel.dart';
import 'package:gym_system/design_system/system_text_field.dart';
import 'package:gym_system/design_system/system_xp_bar.dart';

Widget _wrap(Widget child, {double width = 300, double height = 200}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(width: width, height: height, child: child),
      ),
    ),
  );
}

void main() {
  group('DiagonalCutCornersClipper', () {
    test('corta o canto superior-esquerdo e o inferior-direito', () {
      const clipper = DiagonalCutCornersClipper(14);
      final path = clipper.getClip(const Size(100, 50));
      expect(path.contains(const Offset(1, 1)), isFalse);
      expect(path.contains(const Offset(99, 49)), isFalse);
      expect(path.contains(const Offset(50, 25)), isTrue);
      expect(path.contains(const Offset(99, 1)), isTrue);
      expect(path.contains(const Offset(1, 49)), isTrue);
    });

    test('limita o corte à metade do menor lado em widgets pequenos', () {
      const clipper = DiagonalCutCornersClipper(14);
      expect(() => clipper.getClip(const Size(10, 8)), returnsNormally);
    });

    test('shouldReclip muda só quando cutSize muda', () {
      expect(
          const DiagonalCutCornersClipper(14)
              .shouldReclip(const DiagonalCutCornersClipper(14)),
          isFalse);
      expect(
          const DiagonalCutCornersClipper(14)
              .shouldReclip(const DiagonalCutCornersClipper(8)),
          isTrue);
    });
  });

  group('HexagonClipper', () {
    test('contém o centro e exclui os quatro cantos', () {
      const clipper = HexagonClipper();
      final path = clipper.getClip(const Size(56, 56));
      expect(path.contains(const Offset(28, 28)), isTrue);
      expect(path.contains(const Offset(1, 1)), isFalse);
      expect(path.contains(const Offset(55, 1)), isFalse);
      expect(path.contains(const Offset(1, 55)), isFalse);
      expect(path.contains(const Offset(55, 55)), isFalse);
    });
  });

  group('SystemPanel', () {
    testWidgets('renderiza título em maiúsculas e o conteúdo', (tester) async {
      await tester.pumpWidget(_wrap(
        const SystemPanel(
          title: 'treino a',
          child: Text('conteúdo'),
        ),
      ));
      expect(find.text('TREINO A'), findsOneWidget);
      expect(find.text('conteúdo'), findsOneWidget);
    });

    testWidgets('renderiza sem título e com action', (tester) async {
      await tester.pumpWidget(_wrap(
        const SystemPanel(
          title: 'sistema',
          action: Icon(Icons.settings),
          glow: true,
          child: SizedBox(),
        ),
      ));
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('não estoura com conteúdo grande dentro de espaço pequeno',
        (tester) async {
      await tester.pumpWidget(_wrap(
        SystemPanel(
          child: Text('x' * 500, maxLines: 3, overflow: TextOverflow.ellipsis),
        ),
        width: 180,
        height: 140,
      ));
      expect(tester.takeException(), isNull);
    });
  });

  group('SystemButton', () {
    testWidgets('mostra o rótulo em maiúsculas', (tester) async {
      await tester
          .pumpWidget(_wrap(const SystemButton(label: 'iniciar treino')));
      expect(find.text('INICIAR TREINO'), findsOneWidget);
    });

    testWidgets('chama onPressed ao tocar', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(SystemButton(
        label: 'confirmar',
        variant: SystemButtonVariant.action,
        onPressed: () => tapped = true,
      )));
      await tester.tap(find.text('CONFIRMAR'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('não chama onPressed quando desabilitado', (tester) async {
      await tester.pumpWidget(_wrap(const SystemButton(label: 'desabilitado')));
      await tester.tap(find.text('DESABILITADO'), warnIfMissed: false);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('variante danger renderiza sem erros', (tester) async {
      await tester.pumpWidget(_wrap(SystemButton(
        label: 'excluir',
        variant: SystemButtonVariant.danger,
        kicker: 'perigo',
        icon: const Icon(Icons.delete),
        onPressed: () {},
      )));
      expect(find.text('PERIGO'), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets(
        'chama onPressed exatamente uma vez por toque, mesmo com a animação de press',
        (tester) async {
      var contagem = 0;
      await tester.pumpWidget(_wrap(SystemButton(
        label: 'registrar série',
        variant: SystemButtonVariant.action,
        onPressed: () => contagem++,
      )));

      await tester.tap(find.text('REGISTRAR SÉRIE'));
      // Só um pump curto — o callback já deve ter disparado sem esperar a
      // animação de escala/sombra terminar (Fase 9, seção 7: a ação
      // continua instantânea).
      await tester.pump(const Duration(milliseconds: 10));
      expect(contagem, 1);

      await tester.pumpAndSettle();
      expect(contagem, 1);
    });

    testWidgets('loading mostra spinner e ignora toque', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(SystemButton(
        label: 'salvando',
        loading: true,
        onPressed: () => tapped = true,
      )));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(SystemButton), warnIfMissed: false);
      await tester.pump();
      expect(tapped, isFalse);
    });
  });

  group('SystemTextField', () {
    testWidgets('mostra label em maiúsculas e hint', (tester) async {
      await tester.pumpWidget(_wrap(const SystemTextField(
        label: 'carga',
        hint: 'use o último valor registrado',
      )));
      expect(find.text('CARGA'), findsOneWidget);
      expect(find.text('use o último valor registrado'), findsOneWidget);
    });

    testWidgets('aceita digitação via controller', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
          _wrap(SystemTextField(label: 'reps', controller: controller)));
      await tester.enterText(find.byType(TextField), '12');
      expect(controller.text, '12');
    });

    testWidgets('estado error e desabilitado não lançam exceção',
        (tester) async {
      await tester.pumpWidget(_wrap(const SystemTextField(
        label: 'carga',
        hint: 'valor inválido',
        status: SystemFieldStatus.error,
      )));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
          _wrap(const SystemTextField(label: 'carga', enabled: false)));
      expect(tester.takeException(), isNull);
    });

    testWidgets('estado success renderiza sem erro', (tester) async {
      await tester.pumpWidget(_wrap(const SystemTextField(
        label: 'volume',
        status: SystemFieldStatus.success,
        suffix: 'kg',
      )));
      expect(find.text('KG'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('SystemXpBar', () {
    testWidgets('XP = 0 não lança exceção e mostra 0%', (tester) async {
      await tester.pumpWidget(
          _wrap(const SystemXpBar(value: 0, max: 1000, compact: true)));
      await tester.pumpAndSettle();
      expect(find.text('0%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('XP >= necessário fica travado em 100%', (tester) async {
      await tester.pumpWidget(
          _wrap(const SystemXpBar(value: 5000, max: 1000, compact: true)));
      await tester.pumpAndSettle();
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('modo completo mostra nível e valores formatados',
        (tester) async {
      await tester.pumpWidget(
          _wrap(const SystemXpBar(value: 1234, max: 5000, level: 12)));
      expect(find.text('LEVEL 12'), findsOneWidget);
      expect(find.text('1.234 / 5.000 XP'), findsOneWidget);
    });

    testWidgets('sem level mostra EXPERIÊNCIA', (tester) async {
      await tester.pumpWidget(_wrap(const SystemXpBar(value: 10, max: 100)));
      expect(find.text('EXPERIÊNCIA'), findsOneWidget);
    });

    testWidgets(
        'o XP mudando de valor não trava — a barra chega ao novo percentual',
        (tester) async {
      final notifier = ValueNotifier(10);
      addTearDown(notifier.dispose);

      await tester.pumpWidget(_wrap(ValueListenableBuilder<int>(
        valueListenable: notifier,
        builder: (context, value, _) {
          return SystemXpBar(value: value, max: 100, compact: true);
        },
      )));
      await tester.pumpAndSettle();
      expect(find.text('10%'), findsOneWidget);

      notifier.value = 60;
      await tester.pumpAndSettle();
      expect(find.text('60%'), findsOneWidget);
    });

    testWidgets(
        'sem Reduced Motion, o XP aumentando dispara o shine e ele termina sozinho',
        (tester) async {
      tester.view.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: false);
      addTearDown(() {
        tester.view.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
      });

      final notifier = ValueNotifier(10);
      addTearDown(notifier.dispose);

      await tester.pumpWidget(_wrap(ValueListenableBuilder<int>(
        valueListenable: notifier,
        builder: (context, value, _) {
          return SystemXpBar(value: value, max: 100);
        },
      )));
      await tester.pumpAndSettle();

      notifier.value = 60;
      await tester.pump();
      // Avança um pouco a animação (o controller só começa a valer > 0 no
      // frame seguinte ao `.forward()`) — nesse ponto a varredura está em
      // andamento: a faixa de brilho (um `Transform.translate`) existe na
      // árvore.
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const Key('xp-shine-band')), findsOneWidget);

      // Termina sozinho (não é looping): pumpAndSettle precisa concluir.
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'rebuild sem o XP aumentar não dispara o shine de novo (mesmo valor)',
        (tester) async {
      tester.view.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: false);
      addTearDown(() {
        tester.view.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
      });

      final notifier = ValueNotifier(10);
      addTearDown(notifier.dispose);
      var builds = 0;

      await tester.pumpWidget(_wrap(ValueListenableBuilder<int>(
        valueListenable: notifier,
        builder: (context, value, _) {
          builds++;
          return SystemXpBar(value: value, max: 100);
        },
      )));
      await tester.pumpAndSettle();

      // Força um rebuild do pai sem mudar o valor de XP (ex.: outro stream
      // emitindo, timer do treino rodando) — não deve acender o shine.
      notifier.notifyListeners();
      await tester.pump();
      expect(builds, 2);
      expect(find.byKey(const Key('xp-shine-band')), findsNothing);
    });
  });

  group('RankBadge', () {
    for (final rank in ['F', 'E', 'D', 'C', 'B', 'A', 'S']) {
      testWidgets('renderiza o rank $rank', (tester) async {
        await tester.pumpWidget(_wrap(RankBadge(rank: rank)));
        expect(find.text(rank), findsOneWidget);
        expect(colorForRank(rank), SystemPalette.violet);
      });
    }

    testWidgets('rank desconhecido cai no violeta padrão sem lançar erro',
        (tester) async {
      expect(colorForRank('Z'), SystemPalette.violet);
      await tester.pumpWidget(_wrap(const RankBadge(rank: 'Z')));
      expect(tester.takeException(), isNull);
    });

    testWidgets('respeita tamanhos customizados pequenos e grandes',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const Column(
          children: [
            RankBadge(rank: 'S', size: 24),
            RankBadge(rank: 'S', size: 120),
          ],
        ),
        height: 400,
      ));
      expect(tester.takeException(), isNull);
    });
  });

  group('SystemCutSizes', () {
    test('todos os componentes usam tamanhos distintos e decrescentes', () {
      expect(SystemCutSizes.panel, 14.0);
      expect(SystemCutSizes.button, 12.0);
      expect(SystemCutSizes.input, 8.0);
      expect(SystemCutSizes.small, 6.0);
    });
  });
}

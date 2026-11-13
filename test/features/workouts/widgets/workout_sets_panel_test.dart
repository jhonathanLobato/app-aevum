import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/features/workouts/domain/workout_session.dart';
import 'package:gym_system/features/workouts/presentation/widgets/workout_sets_panel.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

SetEntryRecord _serie(int id,
    {int serie = 1, double carga = 30, int reps = 10}) {
  return SetEntryRecord(
    id: id,
    exerciseId: 1,
    exerciseNome: 'Supino reto',
    serie: serie,
    repeticoes: reps,
    carga: carga,
    volume: carga * reps,
    data: DateTime(2026, 1, 1),
  );
}

void main() {
  group('WorkoutSetsPanel', () {
    testWidgets('lista vazia mostra estado vazio', (tester) async {
      await tester.pumpWidget(_wrap(const WorkoutSetsPanel(series: [])));
      expect(find.text('NENHUMA SÉRIE REGISTRADA NESTE EXERCÍCIO'),
          findsOneWidget);
    });

    testWidgets('uma nova série aparece registrada com os valores reais',
        (tester) async {
      await tester.pumpWidget(_wrap(
        WorkoutSetsPanel(series: [_serie(1)]),
      ));
      await tester.pumpAndSettle();

      expect(find.text('30.0 KG × 10'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets(
        'quando uma série nova é adicionada, ela entra com destaque e depois volta ao normal',
        (tester) async {
      tester.view.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: false);
      addTearDown(() {
        tester.view.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
      });

      final notifier = ValueNotifier<List<SetEntryRecord>>([_serie(1)]);
      addTearDown(notifier.dispose);

      await tester
          .pumpWidget(_wrap(ValueListenableBuilder<List<SetEntryRecord>>(
        valueListenable: notifier,
        builder: (context, series, _) {
          return WorkoutSetsPanel(series: series);
        },
      )));
      await tester.pumpAndSettle();

      // Registra a segunda série — deve ficar destacada logo em seguida.
      notifier.value = [_serie(1), _serie(2, serie: 2, carga: 32)];
      await tester.pump();

      final container = tester.widget<AnimatedContainer>(
        find.ancestor(
          of: find.text('32.0 KG × 10'),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border!.top.color, isNot(Colors.transparent));

      // Passa o tempo do destaque: some sozinho, sem precisar de nova ação.
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pumpAndSettle();

      final containerDepois = tester.widget<AnimatedContainer>(
        find.ancestor(
          of: find.text('32.0 KG × 10'),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final decoracaoDepois = containerDepois.decoration as BoxDecoration;
      expect(decoracaoDepois.border!.top.color, Colors.transparent);
    });
  });
}

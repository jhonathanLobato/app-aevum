import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/features/progression/domain/personal_record.dart';
import 'package:gym_system/features/workouts/presentation/pr_detected_dialog.dart';

void main() {
  group('showPrDetectedDialog', () {
    testWidgets('mostra o PR real, sem XP quando nenhum é informado',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showPrDetectedDialog(
                context,
                exerciseNome: 'Supino reto',
                prs: const [
                  PersonalRecordBreak(
                    tipo: PersonalRecordType.carga,
                    valorNovo: 32,
                    valorAnterior: 30,
                  ),
                ],
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(find.text('NOVO RECORDE'), findsOneWidget);
      expect(find.text('SUPINO RETO'), findsOneWidget);
      expect(find.text('Carga: 32.0 KG'), findsOneWidget);
      expect(find.text('Recorde anterior: 30.0 KG'), findsOneWidget);
      expect(find.textContaining('XP'), findsNothing);
    });

    testWidgets('mostra o XP real quando xpGanho é informado', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showPrDetectedDialog(
                context,
                exerciseNome: 'Supino reto',
                prs: const [
                  PersonalRecordBreak(
                    tipo: PersonalRecordType.carga,
                    valorNovo: 32,
                    valorAnterior: 30,
                  ),
                ],
                xpGanho: 50,
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(find.text('+50 XP'), findsOneWidget);
    });

    testWidgets('botão OK fecha o diálogo', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showPrDetectedDialog(
                context,
                exerciseNome: 'Supino reto',
                prs: const [
                  PersonalRecordBreak(
                      tipo: PersonalRecordType.carga, valorNovo: 32),
                ],
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.text('NOVO RECORDE'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('NOVO RECORDE'), findsNothing);
    });
  });
}

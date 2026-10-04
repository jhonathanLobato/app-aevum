import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/features/missions/domain/mission.dart';
import 'package:gym_system/features/missions/presentation/widgets/mission_card.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

Mission _mission({
  MissionStatus status = MissionStatus.ativa,
  String? minimumRank,
  int progresso = 1,
  int objetivo = 4,
}) {
  return Mission(
    id: 1,
    tipo: MissionType.semanal,
    nome: 'Missão semanal',
    descricao: 'Complete 4 treinos.',
    recompensaXp: 250,
    progresso: progresso,
    objetivo: objetivo,
    status: status,
    criadoEm: DateTime(2026, 1, 1),
    minimumRank: minimumRank,
  );
}

void main() {
  group('MissionCard — estados visuais', () {
    testWidgets('ativa mostra percentual e progresso real', (tester) async {
      await tester.pumpWidget(_wrap(MissionCard(
        mission: _mission(progresso: 1, objetivo: 4),
        userRank: 'F',
      )));

      expect(find.text('25%'), findsOneWidget);
      expect(find.text('1 / 4'), findsOneWidget);
      expect(find.text('+250 XP'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNothing);
      expect(find.byIcon(Icons.lock_outline), findsNothing);
    });

    testWidgets('concluída mostra ícone de check', (tester) async {
      await tester.pumpWidget(_wrap(MissionCard(
        mission: _mission(
            status: MissionStatus.concluida, progresso: 4, objetivo: 4),
        userRank: 'F',
      )));

      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.text('4 / 4'), findsOneWidget);
    });

    testWidgets('bloqueada por rank mostra cadeado, "???" e esconde progresso',
        (tester) async {
      await tester.pumpWidget(_wrap(MissionCard(
        mission: _mission(minimumRank: 'D'),
        userRank: 'F', // F é abaixo de D
      )));

      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.text('???'), findsOneWidget);
      expect(find.text('1 / 4'), findsNothing);
      expect(find.text('+250 XP'), findsNothing);
    });

    testWidgets('rank suficiente não bloqueia mesmo com minimumRank definido',
        (tester) async {
      await tester.pumpWidget(_wrap(MissionCard(
        mission: _mission(minimumRank: 'D'),
        userRank: 'D',
      )));

      expect(find.byIcon(Icons.lock_outline), findsNothing);
      expect(find.text('1 / 4'), findsOneWidget);
    });
  });
}

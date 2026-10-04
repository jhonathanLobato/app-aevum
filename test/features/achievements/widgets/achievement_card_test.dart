import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/features/achievements/domain/achievement.dart';
import 'package:gym_system/features/achievements/presentation/widgets/achievement_card.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

Achievement _achievement({
  AchievementStatus status = AchievementStatus.bloqueada,
  String chave = 'disciplina',
  String nome = 'Disciplina',
  String descricao = 'Complete 10 treinos.',
}) {
  return Achievement(
    id: 1,
    chave: chave,
    nome: nome,
    descricao: descricao,
    icone: 'military_tech',
    requisito: '10 treinos concluídos',
    status: status,
  );
}

void main() {
  group('AchievementCard — estados visuais', () {
    testWidgets('bloqueada sem progresso mostra cadeado e rótulo BLOQUEADA',
        (tester) async {
      await tester.pumpWidget(_wrap(const AchievementCard(
        achievement: Achievement(
          id: 1,
          chave: 'disciplina',
          nome: 'Disciplina',
          descricao: 'Complete 10 treinos.',
          icone: 'military_tech',
          requisito: '10 treinos concluídos',
          status: AchievementStatus.bloqueada,
        ),
        progresso: (0, 10),
      )));

      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.text('BLOQUEADA'), findsOneWidget);
      expect(find.text('0 / 10'), findsOneWidget);
    });

    testWidgets('bloqueada com progresso > 0 mostra rótulo DISPONÍVEL',
        (tester) async {
      await tester.pumpWidget(_wrap(AchievementCard(
        achievement: _achievement(),
        progresso: (7, 10),
      )));

      expect(find.byIcon(Icons.lock_outline), findsNothing);
      expect(find.text('DISPONÍVEL'), findsOneWidget);
      expect(find.text('7 / 10'), findsOneWidget);
    });

    testWidgets('desbloqueada mostra rótulo DESBLOQUEADA e ícone real',
        (tester) async {
      await tester.pumpWidget(_wrap(AchievementCard(
        achievement: _achievement(status: AchievementStatus.desbloqueada),
        progresso: (10, 10),
      )));

      expect(find.byIcon(Icons.lock_outline), findsNothing);
      expect(find.byIcon(Icons.military_tech), findsOneWidget);
      expect(find.text('DESBLOQUEADA'), findsOneWidget);
    });

    testWidgets(
        'sem progresso informado (conquista binária) não mostra contagem',
        (tester) async {
      await tester.pumpWidget(_wrap(AchievementCard(
        achievement: _achievement(
          chave: 'evolucao',
          nome: 'Evolução',
          descricao: 'Bata seu primeiro recorde pessoal.',
        ),
      )));

      expect(find.textContaining(' / '), findsNothing);
      expect(find.text('BLOQUEADA'), findsOneWidget);
    });

    testWidgets('título e descrição sempre visíveis, mesmo bloqueada',
        (tester) async {
      await tester.pumpWidget(_wrap(AchievementCard(
        achievement: _achievement(),
        progresso: (0, 10),
      )));

      expect(find.text('Disciplina'), findsOneWidget);
      expect(find.text('Complete 10 treinos.'), findsOneWidget);
    });
  });
}

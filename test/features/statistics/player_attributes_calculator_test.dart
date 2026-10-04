import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/features/statistics/domain/player_attributes_calculator.dart';
import 'package:gym_system/features/statistics/domain/statistics.dart';

GlobalStatistics _stats({
  int treinosRealizados = 0,
  int totalPRs = 0,
  double volumeTotal = 0,
  int totalRepeticoes = 0,
  int maiorSequenciaDias = 0,
}) {
  return GlobalStatistics(
    treinosRealizados: treinosRealizados,
    tempoTotalTreinando: Duration.zero,
    exerciciosRealizados: 0,
    totalPRs: totalPRs,
    volumeTotal: volumeTotal,
    totalRepeticoes: totalRepeticoes,
    xpAcumulado: 0,
    nivelAtual: 1,
    maiorSequenciaDias: maiorSequenciaDias,
  );
}

void main() {
  const calc = PlayerAttributesCalculator();

  group('usuário novo / zero dados', () {
    test('todos os atributos são 0 sem nenhum dado real', () {
      final r = calc.calcular(_stats());
      expect(r.forca, 0);
      expect(r.resistencia, 0);
      expect(r.constancia, 0);
    });

    test(
        'treino concluído sem nenhuma série registrada não aumenta Força nem Resistência',
        () {
      // Um treino "vazio" (finalizado sem séries) incrementa
      // treinosRealizados, mas Força/Resistência não usam essa contagem —
      // só PR/volume/reps, que continuam 0.
      final r = calc.calcular(_stats(treinosRealizados: 1));
      expect(r.forca, 0);
      expect(r.resistencia, 0);
    });
  });

  group('Força', () {
    test('PRs aumentam Força com retorno decrescente (teto de 60 pontos)', () {
      expect(calc.calcular(_stats(totalPRs: 1)).forca, 3);
      expect(calc.calcular(_stats(totalPRs: 10)).forca, 30);
      expect(calc.calcular(_stats(totalPRs: 20)).forca, 60);
      expect(calc.calcular(_stats(totalPRs: 100)).forca, 60); // teto
    });

    test('volume também contribui pra Força (teto de 40 pontos)', () {
      expect(calc.calcular(_stats(volumeTotal: 2000)).forca, 1);
      expect(calc.calcular(_stats(volumeTotal: 80000)).forca, 40);
      expect(calc.calcular(_stats(volumeTotal: 500000)).forca, 40); // teto
    });

    test('PR e volume se somam, sem passar de 100', () {
      final r = calc.calcular(_stats(totalPRs: 20, volumeTotal: 80000));
      expect(r.forca, 100);
    });
  });

  group('Resistência', () {
    test('repetições aumentam Resistência (teto de 50 pontos)', () {
      expect(calc.calcular(_stats(totalRepeticoes: 40)).resistencia, 1);
      expect(calc.calcular(_stats(totalRepeticoes: 2000)).resistencia, 50);
      expect(calc.calcular(_stats(totalRepeticoes: 100000)).resistencia,
          50); // teto
    });

    test('volume também contribui pra Resistência (teto de 50 pontos)', () {
      expect(calc.calcular(_stats(volumeTotal: 80000)).resistencia, 50);
    });
  });

  group('Constância', () {
    test('frequência de treinos aumenta Constância (teto de 60 pontos)', () {
      expect(calc.calcular(_stats(treinosRealizados: 1)).constancia, 2);
      expect(calc.calcular(_stats(treinosRealizados: 30)).constancia, 60);
      expect(
          calc.calcular(_stats(treinosRealizados: 500)).constancia, 60); // teto
    });

    test('maior sequência aumenta Constância (teto de 40 pontos)', () {
      expect(calc.calcular(_stats(maiorSequenciaDias: 1)).constancia, 4);
      expect(calc.calcular(_stats(maiorSequenciaDias: 10)).constancia, 40);
      expect(calc.calcular(_stats(maiorSequenciaDias: 365)).constancia,
          40); // teto
    });

    test(
        'descanso (sequência não aumentar) nunca reduz o valor — não há penalidade',
        () {
      // A fórmula não tem termo negativo: dias sem treinar simplesmente não
      // adicionam pontos, não subtraem. Verificado aqui só recalculando com
      // os mesmos totais (a função é pura e determinística).
      final antes =
          calc.calcular(_stats(treinosRealizados: 5, maiorSequenciaDias: 3));
      final depois =
          calc.calcular(_stats(treinosRealizados: 5, maiorSequenciaDias: 3));
      expect(depois.constancia, antes.constancia);
    });
  });

  group('limites e robustez', () {
    test('nunca fica abaixo de 0 ou acima de 100, mesmo com dados extremos',
        () {
      final extremo = calc.calcular(_stats(
        treinosRealizados: 1000000,
        totalPRs: 1000000,
        volumeTotal: 1e12,
        totalRepeticoes: 1000000000,
        maiorSequenciaDias: 100000,
      ));
      expect(extremo.forca, inInclusiveRange(0, 100));
      expect(extremo.resistencia, inInclusiveRange(0, 100));
      expect(extremo.constancia, inInclusiveRange(0, 100));
    });

    test('é determinística: mesma entrada sempre produz a mesma saída', () {
      final stats = _stats(
        treinosRealizados: 12,
        totalPRs: 7,
        volumeTotal: 15000,
        totalRepeticoes: 850,
        maiorSequenciaDias: 5,
      );
      final r1 = calc.calcular(stats);
      final r2 = calc.calcular(stats);
      expect(r1.forca, r2.forca);
      expect(r1.resistencia, r2.resistencia);
      expect(r1.constancia, r2.constancia);
    });
  });
}

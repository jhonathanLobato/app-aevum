import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/features/profile/domain/level_curve.dart';

void main() {
  const curve = LevelCurve();

  test('começa no nível 1 com 0 XP', () {
    final info = curve.calcularNivel(0);
    expect(info.nivel, 1);
    expect(info.xpNoNivelAtual, 0);
  });

  test('sobe de nível quando o XP acumulado atinge o necessário', () {
    final xpNecessario = curve.xpParaProximoNivel(1);
    final info = curve.calcularNivel(xpNecessario);

    expect(info.nivel, 2);
    expect(info.xpNoNivelAtual, 0);
  });

  test('mantém o XP excedente dentro do novo nível', () {
    final xpNecessario = curve.xpParaProximoNivel(1);
    final info = curve.calcularNivel(xpNecessario + 50);

    expect(info.nivel, 2);
    expect(info.xpNoNivelAtual, 50);
  });

  test('rank segue a distribuição por nível da seção 10', () {
    expect(rankParaNivel(1), 'F');
    expect(rankParaNivel(9), 'F');
    expect(rankParaNivel(10), 'E');
    expect(rankParaNivel(24), 'E');
    expect(rankParaNivel(25), 'D');
    expect(rankParaNivel(45), 'C');
    expect(rankParaNivel(70), 'B');
    expect(rankParaNivel(100), 'A');
    expect(rankParaNivel(139), 'A');
    expect(rankParaNivel(140), 'S');
  });

  test('XP por nível = 480 + 10 × nível; níveis mínimos dos exames', () {
    expect(curve.xpParaProximoNivel(1), 490);
    expect(curve.xpParaProximoNivel(10), 580);
    expect(curve.xpParaProximoNivel(139), 1870);
    // XP total para entrar nos níveis mínimos de cada rank.
    expect(curve.xpNoInicioDoNivel(10), 4770);
    expect(curve.xpNoInicioDoNivel(25), 14520);
    expect(curve.xpNoInicioDoNivel(45), 31020);
    expect(curve.xpNoInicioDoNivel(70), 57270);
    expect(curve.xpNoInicioDoNivel(100), 97020);
    expect(curve.xpNoInicioDoNivel(140), 164020);
    expect(['E', 'D', 'C', 'B', 'A', 'S'].map(nivelMinimoDoRank),
        [10, 25, 45, 70, 100, 140]);
  });
}

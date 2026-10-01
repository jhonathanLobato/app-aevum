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
    expect(rankParaNivel(30), 'C');
    expect(rankParaNivel(60), 'S');
    expect(rankParaNivel(120), 'S');
  });
}

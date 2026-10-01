import 'dart:math';

/// Curva de progressão de nível, isolada para poder ser trocada sem alterar
/// o resto do app (seção 9 do documento de design: "essa fórmula NÃO deve
/// ser considerada definitiva").
class LevelCurve {
  const LevelCurve();

  /// XP necessário para sair do [nivel] atual e alcançar o próximo.
  int xpParaProximoNivel(int nivel) => (1000 * pow(nivel, 1.2)).round();

  LevelInfo calcularNivel(int xpTotal) {
    var nivel = 1;
    var xpRestante = xpTotal;
    while (xpRestante >= xpParaProximoNivel(nivel)) {
      xpRestante -= xpParaProximoNivel(nivel);
      nivel++;
    }
    return LevelInfo(
      nivel: nivel,
      xpTotal: xpTotal,
      xpNoNivelAtual: xpRestante,
      xpParaProximoNivel: xpParaProximoNivel(nivel),
    );
  }
}

class LevelInfo {
  const LevelInfo({
    required this.nivel,
    required this.xpTotal,
    required this.xpNoNivelAtual,
    required this.xpParaProximoNivel,
  });

  final int nivel;
  final int xpTotal;
  final int xpNoNivelAtual;
  final int xpParaProximoNivel;

  double get progresso =>
      xpParaProximoNivel == 0 ? 0 : xpNoNivelAtual / xpParaProximoNivel;
}

/// Distribuição de rank por nível (seção 10), também configurável.
String rankParaNivel(int nivel) {
  if (nivel >= 60) return 'S';
  if (nivel >= 50) return 'A';
  if (nivel >= 40) return 'B';
  if (nivel >= 30) return 'C';
  if (nivel >= 20) return 'D';
  if (nivel >= 10) return 'E';
  return 'F';
}

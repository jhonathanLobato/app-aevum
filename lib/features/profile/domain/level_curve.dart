import 'dart:math';

/// Curva de progressão de nível, isolada para poder ser trocada sem alterar
/// o resto do app (seção 9 do documento de design: "essa fórmula NÃO deve
/// ser considerada definitiva").
class LevelCurve {
  const LevelCurve();

  /// XP necessário para sair do [nivel] atual e alcançar o próximo.
  int xpParaProximoNivel(int nivel) => (1000 * pow(nivel, 1.2)).round();

  /// XP total acumulado necessário para ENTRAR no [nivel] (início do nível).
  int xpNoInicioDoNivel(int nivel) {
    var total = 0;
    for (var k = 1; k < nivel; k++) {
      total += xpParaProximoNivel(k);
    }
    return total;
  }

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

/// Ordem de evolução dos ranks (seção 10), do mais baixo ao mais alto.
/// Nível mínimo para liberar o exame que leva ao [rank] (curva de ranks
/// original: E=10, D=20, C=30, B=40, A=50, S=60).
int nivelMinimoDoRank(String rank) {
  switch (rank.toUpperCase()) {
    case 'E':
      return 10;
    case 'D':
      return 20;
    case 'C':
      return 30;
    case 'B':
      return 40;
    case 'A':
      return 50;
    case 'S':
      return 60;
    default:
      return 1;
  }
}

/// Próximo rank depois de [atual] (`null` se já é o último).
String? proximoRank(String atual) {
  final i = _ordemDosRanks.indexOf(atual.toUpperCase());
  if (i == -1 || i + 1 >= _ordemDosRanks.length) return null;
  return _ordemDosRanks[i + 1];
}

const _ordemDosRanks = ['F', 'E', 'D', 'C', 'B', 'A', 'S'];

/// `true` se [atual] já alcançou (ou superou) o rank [minimo] — usado pelo
/// "rank lock" de missões (Fase 7, seção 8). Um rank desconhecido (fora da
/// lista) nunca bloqueia, pra não travar a UI por um dado inesperado.
bool rankAtende(String atual, String minimo) {
  final indiceAtual = _ordemDosRanks.indexOf(atual.toUpperCase());
  final indiceMinimo = _ordemDosRanks.indexOf(minimo.toUpperCase());
  if (indiceAtual == -1 || indiceMinimo == -1) return true;
  return indiceAtual >= indiceMinimo;
}

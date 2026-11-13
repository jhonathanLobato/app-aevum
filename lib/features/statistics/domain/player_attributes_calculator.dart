import 'statistics.dart';

/// Atributos derivados do jogador (seção 15 do CLAUDE.md) — escala 0-100,
/// sempre recalculados a partir de
/// [GlobalStatistics], nunca persistidos.
class PlayerAttributes {
  const PlayerAttributes({
    required this.forca,
    required this.resistencia,
    required this.constancia,
  });

  final int forca;
  final int resistencia;
  final int constancia;
}

/// Pesos e tetos da fórmula MVP, centralizados pra ajuste futuro sem mexer
/// na fórmula em si. Ver [PlayerAttributesCalculator] pra como são usados.
class PlayerAttributesValues {
  const PlayerAttributesValues._();

  // FORÇA = pontos de PR (até 60) + pontos de volume (até 40).
  static const pontosPorPR = 3;
  static const tetoPontosPRForca = 60;
  static const kgPorPontoVolumeForca = 2000;
  static const tetoPontosVolumeForca = 40;

  // RESISTÊNCIA = pontos de volume (até 50) + pontos de repetições (até 50).
  static const kgPorPontoVolumeResistencia = 1600;
  static const tetoPontosVolumeResistencia = 50;
  static const repsPorPontoResistencia = 40;
  static const tetoPontosRepsResistencia = 50;

  // CONSTÂNCIA = pontos de treinos (até 60) + pontos de sequência (até 40).
  static const pontosPorTreino = 2;
  static const tetoPontosTreino = 60;
  static const pontosPorDiaDeSequencia = 4;
  static const tetoPontosSequencia = 40;
}

/// Calcula os 3 atributos do MVP (Força/Resistência/Constância) — função
/// pura e determinística, sem acesso a banco/IO.
///
/// Equações exatas (todas as constantes vêm de [PlayerAttributesValues];
/// `min`/`max` abaixo operam sobre inteiros, com `volumeTotal / kg` truncado
/// pra baixo antes do teto):
///
/// ```text
/// FORÇA =
///   clamp(
///     min(totalPRs × 3, 60)                       // pontos de PR, até 60
///       + min(floor(volumeTotal / 2000), 40),      // pontos de volume, até 40
///     0, 100
///   )
///
/// RESISTÊNCIA =
///   clamp(
///     min(floor(volumeTotal / 1600), 50)           // pontos de volume, até 50
///       + min(floor(totalRepeticoes / 40), 50),    // pontos de reps, até 50
///     0, 100
///   )
///
/// CONSTÂNCIA =
///   clamp(
///     min(treinosRealizados × 2, 60)               // pontos de treinos, até 60
///       + min(maiorSequenciaDias × 4, 40),         // pontos de sequência, até 40
///     0, 100
///   )
/// ```
///
/// `clamp(x, 0, 100)` é a função [_clamp] abaixo; `min(valor, teto)` (com
/// piso em 0) é a função [_capped] abaixo. Cada termo já nasce limitado ao
/// seu próprio teto parcial antes da soma, então o `clamp` final só entra
/// em jogo pra garantir o limite superior de 100 quando as duas parcelas
/// somadas o ultrapassarem (ex.: Força com PR no teto + volume no teto).
class PlayerAttributesCalculator {
  const PlayerAttributesCalculator();

  PlayerAttributes calcular(GlobalStatistics stats) {
    return PlayerAttributes(
      forca: _forca(stats),
      resistencia: _resistencia(stats),
      constancia: _constancia(stats),
    );
  }

  int _forca(GlobalStatistics s) {
    final pontosPR = _capped(
      s.totalPRs * PlayerAttributesValues.pontosPorPR,
      PlayerAttributesValues.tetoPontosPRForca,
    );
    final pontosVolume = _capped(
      (s.volumeTotal / PlayerAttributesValues.kgPorPontoVolumeForca).floor(),
      PlayerAttributesValues.tetoPontosVolumeForca,
    );
    return _clamp(pontosPR + pontosVolume);
  }

  int _resistencia(GlobalStatistics s) {
    final pontosVolume = _capped(
      (s.volumeTotal / PlayerAttributesValues.kgPorPontoVolumeResistencia)
          .floor(),
      PlayerAttributesValues.tetoPontosVolumeResistencia,
    );
    final pontosReps = _capped(
      (s.totalRepeticoes / PlayerAttributesValues.repsPorPontoResistencia)
          .floor(),
      PlayerAttributesValues.tetoPontosRepsResistencia,
    );
    return _clamp(pontosVolume + pontosReps);
  }

  int _constancia(GlobalStatistics s) {
    final pontosTreinos = _capped(
      s.treinosRealizados * PlayerAttributesValues.pontosPorTreino,
      PlayerAttributesValues.tetoPontosTreino,
    );
    final pontosSequencia = _capped(
      s.maiorSequenciaDias * PlayerAttributesValues.pontosPorDiaDeSequencia,
      PlayerAttributesValues.tetoPontosSequencia,
    );
    return _clamp(pontosTreinos + pontosSequencia);
  }

  int _capped(int valor, int teto) {
    if (valor < 0) return 0;
    return valor > teto ? teto : valor;
  }

  int _clamp(int valor) {
    if (valor < 0) return 0;
    return valor > 100 ? 100 : valor;
  }
}

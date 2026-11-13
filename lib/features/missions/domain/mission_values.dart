/// Valores do sistema de missões (seção 11), num só lugar para serem fáceis
/// de ajustar.
class MissionValues {
  const MissionValues._();

  /// XP da missão semanal conforme a quantidade de treinos programados
  /// (1 a 7). Tudo ou nada: concluir todos os treinos programados da semana.
  static const xpSemanalPorTreinos = <int, int>{
    1: 50,
    2: 100,
    3: 150,
    4: 250,
    5: 300,
    6: 350,
    7: 400,
  };

  static int xpSemanal(int treinosProgramados) =>
      xpSemanalPorTreinos[treinosProgramados.clamp(1, 7)]!;

  static const xpDesafio = 150;

  /// Quanto o próximo desafio de carga pede acima do recorde atual.
  static const incrementoDesafioCarga = 2.0;
}

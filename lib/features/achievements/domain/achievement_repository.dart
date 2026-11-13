import 'achievement.dart';

abstract class AchievementRepository {
  Stream<List<Achievement>> watchAll();

  /// Garante que o catálogo fixo de conquistas existe no banco (idempotente).
  Future<void> ensureCatalog();

  /// Chamado quando um treino é finalizado: reavalia as conquistas baseadas
  /// em quantidade de treinos concluídos. Retorna as desbloqueadas agora.
  Future<List<Achievement>> verificarPorTreinoConcluido();

  /// Chamado quando um recorde pessoal é batido: reavalia "Evolução" e
  /// "Superação". Retorna as desbloqueadas agora.
  Future<List<Achievement>> verificarPorNovoRecorde();

  /// Reavalia as conquistas de rank (chamado quando o rank muda, ou seja,
  /// ao passar num exame de rank).
  Future<List<Achievement>> verificarRank();
}

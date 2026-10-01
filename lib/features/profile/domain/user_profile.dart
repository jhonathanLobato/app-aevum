import 'app_theme.dart';
import 'player_class.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.nome,
    required this.avatar,
    required this.classe,
    required this.titulo,
    required this.tema,
    required this.xp,
    required this.nivel,
    required this.rank,
  });

  final int id;
  final String nome;
  final String? avatar;
  final PlayerClass classe;
  final String? titulo;
  final AppTheme tema;
  final int xp;
  final int nivel;
  final String rank;
}

class XpGainResult {
  const XpGainResult({
    required this.xpGanho,
    required this.nivelAnterior,
    required this.novoNivel,
  });

  final int xpGanho;
  final int nivelAnterior;
  final int novoNivel;

  bool get subiuDeNivel => novoNivel > nivelAnterior;
}

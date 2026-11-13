import 'app_theme.dart';
import 'player_class.dart';
import 'units.dart';

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
    this.alturaCm,
    this.nascimento,
    this.sexo,
    this.unidades = const Units(),
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

  /// Corpo (opcionais; altura em cm) e unidades de exibição.
  final double? alturaCm;
  final DateTime? nascimento;
  final Sexo? sexo;
  final Units unidades;
}

class XpGainResult {
  const XpGainResult({
    required this.xpGanho,
    required this.nivelAnterior,
    required this.novoNivel,
    required this.rankAnterior,
    required this.novoRank,
  });

  final int xpGanho;
  final int nivelAnterior;
  final int novoNivel;

  /// Rank real (mesma função `rankParaNivel` já usada por
  /// [DriftProfileRepository.addXp] para persistir `user.rank`) — não é
  /// recalculado pela UI, só exposto aqui pra o Level Up poder mostrá-lo
  /// quando realmente mudar (Fase 10).
  final String rankAnterior;
  final String novoRank;

  bool get subiuDeNivel => novoNivel > nivelAnterior;
  bool get subiuDeRank => novoRank != rankAnterior;
}

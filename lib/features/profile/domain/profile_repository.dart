import 'app_theme.dart';
import 'player_class.dart';
import 'user_profile.dart';

abstract class ProfileRepository {
  /// `null` enquanto nenhum XP foi concedido ainda (o perfil é criado na
  /// primeira vez que [addXp] ou [updateProfile] forem chamados).
  Stream<UserProfile?> watchCurrentUser();

  /// Adiciona XP ao usuário atual, recalculando nível e rank.
  Future<XpGainResult> addXp(int quantidade);

  /// Atualiza os campos de personalização informados; campos nulos mantêm
  /// o valor atual. Cria o perfil se ele ainda não existir.
  Future<void> updateProfile({
    String? nome,
    String? avatar,
    PlayerClass? classe,
    String? titulo,
    AppTheme? tema,
  });
}

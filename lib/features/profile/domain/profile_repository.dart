import 'app_theme.dart';
import 'player_class.dart';
import 'units.dart';
import 'user_profile.dart';

abstract class ProfileRepository {
  /// `null` enquanto nenhum XP foi concedido ainda (o perfil é criado na
  /// primeira vez que [addXp] ou [updateProfile] forem chamados).
  Stream<UserProfile?> watchCurrentUser();

  /// Adiciona XP ao usuário atual, recalculando nível e rank.
  /// Soma XP e recalcula o nível. O RANK não muda aqui: ele só sobe ao
  /// passar no exame de rank (ver [setRank]).
  Future<XpGainResult> addXp(int quantidade);

  /// Tira até [quantidade] de XP, sem nunca ficar abaixo do início do nível
  /// atual (não cai de nível; o rank nunca cai). Retorna o XP realmente
  /// perdido.
  ///
  /// Com [respeitarPisoDoNivel] `false` (ajuste de um XP concedido por
  /// engano, ex.: registro de atividade excluído) o XP pode descer abaixo do
  /// início do nível e o nível é recalculado; o rank nunca muda.
  Future<int> removeXp(int quantidade, {bool respeitarPisoDoNivel = true});

  /// Define o rank (usado só pelo exame de rank aprovado).
  Future<void> setRank(String rank);

  /// Atualiza os campos de personalização informados; campos nulos mantêm
  /// o valor atual. Cria o perfil se ele ainda não existir.
  /// Data do Despertar: criação do usuário ou o primeiro registro (treino,
  /// atividade ou medida corporal), o que for mais antigo.
  Stream<DateTime?> watchDespertar();

  /// Grava a Ficha do Caçador inteira de uma vez (tela de Perfil). Ao
  /// contrário de [updateProfile], valores nulos de altura/nascimento/sexo
  /// LIMPAM o campo.
  Future<void> salvarFicha({
    required String nome,
    required String? avatar,
    required PlayerClass classe,
    required String titulo,
    required AppTheme tema,
    required Units unidades,
    double? alturaCm,
    DateTime? nascimento,
    Sexo? sexo,
  });

  Future<void> updateProfile({
    String? nome,
    String? avatar,
    PlayerClass? classe,
    String? titulo,
    AppTheme? tema,
  });
}

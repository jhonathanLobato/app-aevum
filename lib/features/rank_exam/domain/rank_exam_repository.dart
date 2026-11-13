import '../../activities/domain/sport_activity.dart';
import 'rank_exam.dart';

abstract class RankExamRepository {
  /// Situação do jogador diante do próximo rank (bloqueado, exame disponível
  /// ou em andamento). `null` se ainda não existe usuário.
  Stream<RankStatus?> watchStatus();

  /// Inicia o exame disponível com as [modalidades] extras escolhidas. O
  /// prazo conta a partir de agora. Exige 2+ dias de treino programados.
  Future<IniciarExameResultado> iniciarExame(List<SportType> modalidades);

  /// Libera o exame (nível e tempo mínimo no rank atingidos), inicia sozinho
  /// o exame cuja janela de 7 dias acabou, aprova (requisitos cumpridos) ou
  /// reinicia (prazo vencido / metas impossíveis; abre nova janela de 7
  /// dias). Também devolve RANK UPs ainda não exibidos. Retorna o que
  /// aconteceu, para o app avisar.
  Future<List<RankExamEvent>> sincronizar();

  /// Marca o RANK UP para [rankAlvo] como exibido (para não repetir).
  Future<void> confirmarRankUp(String rankAlvo);
}

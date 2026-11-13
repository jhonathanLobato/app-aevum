import '../../activities/domain/sport_activity.dart';
import 'rank_exam.dart';

abstract class RankExamRepository {
  /// Exame ativo com o progresso de cada requisito (`null` se não há).
  Stream<RankExamState?> watchAtivo();

  /// Define as modalidades do exame (entre as de Atividades).
  Future<void> escolherModalidades(List<SportType> modalidades);

  /// Libera o exame (nível mínimo atingido), aprova (requisitos cumpridos) ou
  /// reinicia (prazo vencido / 75% das missões diárias impossível). Retorna o
  /// que aconteceu, para o app avisar o usuário.
  Future<List<RankExamEvent>> sincronizar();
}

import 'daily_models.dart';
import 'daily_values.dart';

abstract class DailyRepository {
  /// Progresso da missão diária de hoje.
  Stream<DailyProgress> watchHoje();

  /// Soma [valor] à [parte] de hoje. Se isto completar a missão (e hoje não
  /// for folga), concede o XP uma única vez.
  Future<DailyAddResult> adicionar(DailyPart parte, double valor);

  /// Desfaz o último registro da [parte] de hoje. Não desfaz depois que a
  /// missão foi concluída (o XP já foi dado). Retorna se desfez algo.
  Future<bool> desfazerUltimo(DailyPart parte);

  /// Os 7 dias da semana atual (segunda a domingo).
  Stream<List<WeekDayInfo>> watchSemana();

  /// Folgas usadas no mês de hoje.
  Stream<FolgasInfo> watchFolgas();

  /// Marca/desmarca folga em [dia] (hoje ou futuro, dentro do limite do mês).
  Future<FolgaResult> alternarFolga(DateTime dia);

  /// Avalia os dias que já passaram: dia anterior sem missão e sem folga
  /// perde XP (ver [DailyValues]). Chame ao abrir o app.
  Future<List<PenaltyApplied>> processarVirada();

  /// Soma do XP perdido em penalidades que o usuário ainda não viu.
  Stream<int> watchPenalidadePendente();

  Future<void> confirmarPenalidades();

  /// Dias da semana (1..7) com treino programado.
  Stream<Set<int>> watchProgramacao();

  Future<void> alternarDiaDeTreino(int weekday);
}

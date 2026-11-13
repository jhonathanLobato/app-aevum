import 'personal_record.dart';

abstract class PersonalRecordRepository {
  Stream<List<PersonalRecord>> watchForExercise(int exerciseId);

  /// Avalia uma série recém-registrada (já gravada como [serieId]) contra o
  /// melhor resultado de treinos CONCLUÍDOS anteriores à sessão [sessionId].
  ///
  /// Regras:
  /// - Se o exercício nunca foi feito em outro treino concluído, a série só
  ///   estabelece a referência: nenhum PR é gerado.
  /// - Cada tipo (carga, repetições, volume) gera no máximo um PR por
  ///   exercício por treino. Melhorias seguintes no mesmo treino só
  ///   atualizam o valor do PR já gravado (o tipo não volta em
  ///   [PrCheckResult.breaks]).
  Future<PrCheckResult> checkAndRecord({
    required int sessionId,
    required int serieId,
    required int exerciseId,
    required int repeticoes,
    required double carga,
    required double volume,
  });
}

class PrCheckResult {
  const PrCheckResult({
    this.breaks = const [],
    this.superouCargaDeReferencia = false,
  });

  /// PRs novos desta série (geram XP e diálogo).
  final List<PersonalRecordBreak> breaks;

  /// A carga desta série supera o melhor de treinos anteriores (mesmo que o
  /// PR de carga deste treino já tenha sido contado numa série anterior).
  final bool superouCargaDeReferencia;
}

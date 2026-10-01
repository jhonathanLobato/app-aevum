import 'personal_record.dart';

abstract class PersonalRecordRepository {
  Stream<List<PersonalRecord>> watchForExercise(int exerciseId);

  /// Compara os valores de uma série recém-registrada com os recordes atuais
  /// do exercício e grava um novo [PersonalRecord] para cada tipo superado.
  /// Retorna os recordes batidos nesta chamada (pode ser vazio).
  Future<List<PersonalRecordBreak>> checkAndRecord({
    required int exerciseId,
    required int repeticoes,
    required double carga,
    required double volume,
  });
}

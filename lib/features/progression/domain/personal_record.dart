enum PersonalRecordType { carga, repeticoes, volume }

class PersonalRecord {
  const PersonalRecord({
    required this.id,
    required this.exerciseId,
    required this.tipo,
    required this.valor,
    required this.data,
  });

  final int id;
  final int exerciseId;
  final PersonalRecordType tipo;
  final double valor;
  final DateTime data;
}

/// Um recorde pessoal batido no momento em que uma série é registrada.
class PersonalRecordBreak {
  const PersonalRecordBreak({
    required this.tipo,
    required this.valorNovo,
    this.valorAnterior,
  });

  final PersonalRecordType tipo;
  final double valorNovo;
  final double? valorAnterior;
}

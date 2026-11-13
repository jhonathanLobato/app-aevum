/// Relatório de uma semana (segunda a domingo): treinos de academia,
/// atividades esportivas e recordes quebrados. Calculado dos dados reais
/// (nada é gravado).
class WeeklyReport {
  const WeeklyReport({
    required this.inicio,
    required this.treinos,
    required this.atividades,
    required this.recordes,
  });

  /// Segunda-feira (00:00) da semana.
  final DateTime inicio;
  final int treinos;
  final int atividades;
  final int recordes;

  DateTime get fim => DateTime(inicio.year, inicio.month, inicio.day + 6);

  bool get vazio => treinos == 0 && atividades == 0 && recordes == 0;
}

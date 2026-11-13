/// Partes da missão diária.
enum DailyPart { flexoes, abdominais, km }

/// Valores da missão diária, folgas e penalidade (fáceis de ajustar).
class DailyValues {
  const DailyValues._();

  static const metaFlexoes = 50;
  static const metaAbdominais = 50;
  static const metaKm = 2.0;

  /// XP da missão diária (só quando as 3 partes são completadas).
  static const xpMissao = 50;

  /// Perda de XP por dia de missão não cumprida (sem folga).
  static const penalidadeXp = 100;

  /// Perda máxima de XP por semana (segunda a domingo).
  static const penalidadeSemanalMax = 300;

  /// Dias de folga por mês (não acumulam).
  static const folgasPorMes = 4;

  static double meta(DailyPart parte) => switch (parte) {
        DailyPart.flexoes => metaFlexoes.toDouble(),
        DailyPart.abdominais => metaAbdominais.toDouble(),
        DailyPart.km => metaKm,
      };
}

/// "2026-10-04" — chave do dia no fuso local.
String chaveDoDia(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime apenasData(DateTime d) => DateTime(d.year, d.month, d.day);

/// Segunda-feira (00:00 local) da semana de [d].
DateTime inicioDaSemana(DateTime d) {
  final dia = apenasData(d);
  return DateTime(
      dia.year, dia.month, dia.day - (dia.weekday - DateTime.monday));
}

/// Soma [dias] dias de calendário (seguro contra horário de verão).
DateTime somarDias(DateTime d, int dias) =>
    DateTime(d.year, d.month, d.day + dias);

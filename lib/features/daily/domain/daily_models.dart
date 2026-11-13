import '../../profile/domain/user_profile.dart';
import 'daily_values.dart';

/// Progresso da missão diária de um dia.
class DailyProgress {
  const DailyProgress({
    required this.dia,
    required this.flexoes,
    required this.abdominais,
    required this.km,
    required this.folga,
    required this.concluida,
  });

  final DateTime dia;
  final int flexoes;
  final int abdominais;
  final double km;
  final bool folga;
  final bool concluida;

  double valor(DailyPart parte) => switch (parte) {
        DailyPart.flexoes => flexoes.toDouble(),
        DailyPart.abdominais => abdominais.toDouble(),
        DailyPart.km => km,
      };

  /// 0..1 de cada parte (limitado a 1).
  double fracao(DailyPart parte) =>
      (valor(parte) / DailyValues.meta(parte)).clamp(0, 1).toDouble();

  bool get metasAtingidas =>
      flexoes >= DailyValues.metaFlexoes &&
      abdominais >= DailyValues.metaAbdominais &&
      km >= DailyValues.metaKm;
}

/// Resultado de registrar uma parte da missão diária.
class DailyAddResult {
  const DailyAddResult({required this.progresso, this.xpGanho});

  final DailyProgress progresso;

  /// Preenchido quando este registro completou a missão e deu XP.
  final XpGainResult? xpGanho;

  bool get completouAgora => xpGanho != null;
}

enum DayStatus { cumprida, folga, falhou, hoje, futuro }

class WeekDayInfo {
  const WeekDayInfo({
    required this.dia,
    required this.status,
    required this.treinoProgramado,
    required this.ehHoje,
  });

  final DateTime dia;
  final DayStatus status;
  final bool treinoProgramado;
  final bool ehHoje;
}

class FolgasInfo {
  const FolgasInfo({required this.usadas, required this.total});

  final int usadas;
  final int total;

  int get restantes => total - usadas;
}

enum FolgaResult { marcada, desmarcada, limiteAtingido, indisponivel }

/// Penalidade aplicada na virada do dia.
class PenaltyApplied {
  const PenaltyApplied({required this.dia, required this.xpPerdido});

  final DateTime dia;
  final int xpPerdido;
}

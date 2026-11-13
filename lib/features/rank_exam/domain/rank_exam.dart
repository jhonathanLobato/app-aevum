import '../../activities/domain/sport_activity.dart';

/// Requisitos do exame que leva ao rank [rankAlvo].
class RankExamSpec {
  const RankExamSpec({
    required this.rankAlvo,
    required this.treinos,
    required this.prazoDias,
    required this.modalidades,
    required this.registrosPorModalidade,
  });

  final String rankAlvo;

  /// Treinos de academia concluídos dentro do período.
  final int treinos;
  final int prazoDias;

  /// Quantas modalidades diferentes de Atividades o usuário escolhe...
  final int modalidades;

  /// ...e quantos registros (30+ min) de cada uma são necessários.
  final int registrosPorModalidade;
}

class RankExamValues {
  const RankExamValues._();

  /// Fração mínima de dias do período com a missão diária cumprida (dias de
  /// folga ficam fora do cálculo).
  static const fracaoMissaoDiaria = 0.75;

  /// Duração mínima (min) de um registro de atividade para contar no exame.
  static const minutosMinimos = 30;

  static const specs = <String, RankExamSpec>{
    'E': RankExamSpec(
        rankAlvo: 'E',
        treinos: 12,
        prazoDias: 21,
        modalidades: 3,
        registrosPorModalidade: 1),
    'D': RankExamSpec(
        rankAlvo: 'D',
        treinos: 18,
        prazoDias: 30,
        modalidades: 3,
        registrosPorModalidade: 2),
    'C': RankExamSpec(
        rankAlvo: 'C',
        treinos: 26,
        prazoDias: 45,
        modalidades: 3,
        registrosPorModalidade: 2),
    'B': RankExamSpec(
        rankAlvo: 'B',
        treinos: 36,
        prazoDias: 60,
        modalidades: 4,
        registrosPorModalidade: 2),
    'A': RankExamSpec(
        rankAlvo: 'A',
        treinos: 48,
        prazoDias: 75,
        modalidades: 4,
        registrosPorModalidade: 3),
    'S': RankExamSpec(
        rankAlvo: 'S',
        treinos: 64,
        prazoDias: 90,
        modalidades: 4,
        registrosPorModalidade: 3),
  };
}

class ModalityProgress {
  const ModalityProgress({
    required this.tipo,
    required this.registros,
    required this.necessarios,
  });

  final SportType tipo;
  final int registros;
  final int necessarios;

  bool get cumprida => registros >= necessarios;
}

/// Situação do exame ativo, com o progresso de cada requisito.
class RankExamState {
  const RankExamState({
    required this.rankAtual,
    required this.rankAlvo,
    required this.inicio,
    required this.fim,
    required this.diasRestantes,
    required this.treinosFeitos,
    required this.treinosNecessarios,
    required this.modalidadesNecessarias,
    required this.registrosPorModalidade,
    required this.modalidades,
    required this.missoesCumpridas,
    required this.missoesNecessarias,
    required this.diasValidos,
    required this.diasAbertos,
    required this.reinicios,
  });

  final String rankAtual;
  final String rankAlvo;
  final DateTime inicio;
  final DateTime fim;
  final int diasRestantes;

  final int treinosFeitos;
  final int treinosNecessarios;

  /// Quantas modalidades o usuário deve escolher (e cumprir).
  final int modalidadesNecessarias;
  final int registrosPorModalidade;

  /// Modalidades já escolhidas, com o progresso de cada uma.
  final List<ModalityProgress> modalidades;

  final int missoesCumpridas;
  final int missoesNecessarias;

  /// Dias do período sem contar folgas.
  final int diasValidos;

  /// Dias (hoje e futuros) em que a missão diária ainda pode ser cumprida.
  final int diasAbertos;
  final int reinicios;

  /// Os 75% de missões diárias já não podem mais ser atingidos.
  bool get missoesImpossiveis =>
      missoesCumpridas + diasAbertos < missoesNecessarias;

  bool get modalidadesEscolhidas =>
      modalidades.length >= modalidadesNecessarias;

  int get modalidadesCumpridas => modalidades.where((m) => m.cumprida).length;

  bool get treinosOk => treinosFeitos >= treinosNecessarios;
  bool get extrasOk =>
      modalidadesEscolhidas && modalidadesCumpridas >= modalidadesNecessarias;
  bool get missoesOk => missoesCumpridas >= missoesNecessarias;
  bool get aprovado => treinosOk && extrasOk && missoesOk;
}

enum RankExamEventType { liberado, aprovado, reiniciado }

enum RankExamResetReason { prazo, missaoDiariaImpossivel }

class RankExamEvent {
  const RankExamEvent(this.tipo,
      {required this.rankAlvo, this.rankAnterior, this.motivo});

  final RankExamEventType tipo;
  final String rankAlvo;
  final String? rankAnterior;
  final RankExamResetReason? motivo;
}

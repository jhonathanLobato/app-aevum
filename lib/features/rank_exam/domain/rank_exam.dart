import '../../activities/domain/sport_activity.dart';

/// Requisitos do exame que leva ao rank [rankAlvo].
class RankExamSpec {
  const RankExamSpec({
    required this.rankAlvo,
    required this.prazoDias,
    required this.fracaoTreinos,
    required this.fracaoMissaoDiaria,
    required this.modalidades,
    required this.registrosPorModalidade,
  });

  final String rankAlvo;
  final int prazoDias;

  /// Fração dos treinos PROGRAMADOS no período que precisam ser cumpridos
  /// (meta = arredondar para cima; folga em dia de treino tira o treino).
  final double fracaoTreinos;

  /// Fração dos dias do período (sem folgas) com a missão diária cumprida.
  final double fracaoMissaoDiaria;

  /// Quantas modalidades de Atividades o usuário escolhe...
  final int modalidades;

  /// ...e quantos registros (30+ min) de cada uma são necessários.
  final int registrosPorModalidade;
}

class RankExamValues {
  const RankExamValues._();

  /// Mínimo de dias de treino programados por semana para o exame começar.
  static const minDiasProgramados = 2;

  /// Dias que o usuário tem para iniciar o exame depois de liberado; no dia
  /// seguinte ele começa sozinho.
  static const janelaParaIniciarDias = 7;

  /// Meses mínimos no rank ATUAL antes de o próximo exame poder ser liberado
  /// (vale junto com o nível mínimo do próximo rank).
  static const mesesMinimosNoRank = <String, int>{
    'F': 2,
    'E': 3,
    'D': 5,
    'C': 7,
    'B': 9,
    'A': 10,
  };

  /// Duração mínima (min) de um registro de atividade para contar no exame.
  static const minutosMinimos = 30;

  static const specs = <String, RankExamSpec>{
    'E': RankExamSpec(
        rankAlvo: 'E',
        prazoDias: 35,
        fracaoTreinos: 0.80,
        fracaoMissaoDiaria: 0.75,
        modalidades: 3,
        registrosPorModalidade: 1),
    'D': RankExamSpec(
        rankAlvo: 'D',
        prazoDias: 50,
        fracaoTreinos: 0.80,
        fracaoMissaoDiaria: 0.75,
        modalidades: 3,
        registrosPorModalidade: 2),
    'C': RankExamSpec(
        rankAlvo: 'C',
        prazoDias: 70,
        fracaoTreinos: 0.85,
        fracaoMissaoDiaria: 0.80,
        modalidades: 3,
        registrosPorModalidade: 2),
    'B': RankExamSpec(
        rankAlvo: 'B',
        prazoDias: 90,
        fracaoTreinos: 0.85,
        fracaoMissaoDiaria: 0.80,
        modalidades: 4,
        registrosPorModalidade: 2),
    'A': RankExamSpec(
        rankAlvo: 'A',
        prazoDias: 110,
        fracaoTreinos: 0.90,
        fracaoMissaoDiaria: 0.85,
        modalidades: 4,
        registrosPorModalidade: 3),
    'S': RankExamSpec(
        rankAlvo: 'S',
        prazoDias: 140,
        fracaoTreinos: 0.95,
        fracaoMissaoDiaria: 0.90,
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

/// Situação do exame (ativo ou aguardando), com o progresso de cada
/// requisito.
class RankExamState {
  const RankExamState({
    required this.rankAtual,
    required this.rankAlvo,
    required this.inicio,
    required this.fim,
    required this.diasRestantes,
    required this.fracaoTreinos,
    required this.treinosProgramadosNoPeriodo,
    required this.treinosFeitos,
    required this.treinosNecessarios,
    required this.diasAbertosTreino,
    required this.modalidadesNecessarias,
    required this.registrosPorModalidade,
    required this.modalidades,
    required this.fracaoMissaoDiaria,
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

  /// Treinos: meta = ⌈fração × treinos programados no período⌉ (sem os dias
  /// de folga).
  final double fracaoTreinos;
  final int treinosProgramadosNoPeriodo;
  final int treinosFeitos;
  final int treinosNecessarios;

  /// Dias (hoje e futuros, sem folga, sem treino já feito hoje) em que ainda
  /// dá para treinar.
  final int diasAbertosTreino;

  /// Quantas modalidades o usuário deve escolher (e cumprir).
  final int modalidadesNecessarias;
  final int registrosPorModalidade;

  /// Modalidades já escolhidas, com o progresso de cada uma.
  final List<ModalityProgress> modalidades;

  final double fracaoMissaoDiaria;
  final int missoesCumpridas;
  final int missoesNecessarias;

  /// Dias do período sem contar folgas.
  final int diasValidos;

  /// Dias (hoje e futuros) em que a missão diária ainda pode ser cumprida.
  final int diasAbertos;
  final int reinicios;

  /// A meta de treinos já não pode mais ser atingida.
  bool get treinosImpossiveis =>
      treinosFeitos + diasAbertosTreino < treinosNecessarios;

  /// A fração de missões diárias já não pode mais ser atingida.
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

enum RankExamEventType {
  /// Exame liberado: o usuário tem 7 dias para iniciá-lo.
  liberado,

  /// A janela de 7 dias acabou e o exame começou sozinho.
  iniciadoAutomaticamente,
  aprovado,

  /// Reiniciou por falha: abre uma nova janela de 7 dias para iniciar.
  reiniciado,
}

enum RankExamResetReason { prazo, treinosImpossivel, missaoDiariaImpossivel }

class RankExamEvent {
  const RankExamEvent(this.tipo,
      {required this.rankAlvo,
      this.rankAnterior,
      this.motivo,
      this.modalidades = const []});

  final RankExamEventType tipo;
  final String rankAlvo;
  final String? rankAnterior;
  final RankExamResetReason? motivo;

  /// Modalidades escolhidas automaticamente ([iniciadoAutomaticamente]).
  final List<SportType> modalidades;
}

enum RankExamPhase { maximo, bloqueado, disponivel, emAndamento }

/// Onde o jogador está no caminho do próximo rank (tela de Rank).
class RankStatus {
  const RankStatus({
    required this.rankAtual,
    required this.nivel,
    required this.proximoRank,
    required this.fase,
    required this.nivelMinimo,
    required this.mesesMinimos,
    required this.desde,
    required this.liberaPorTempoEm,
    required this.diasProgramadosPorSemana,
    this.liberadoEm,
    this.exame,
  });

  final String rankAtual;
  final int nivel;
  final String? proximoRank;
  final RankExamPhase fase;

  /// Nível mínimo e tempo mínimo no rank atual para liberar o próximo exame.
  final int nivelMinimo;
  final int mesesMinimos;
  final DateTime desde;
  final DateTime liberaPorTempoEm;

  final int diasProgramadosPorSemana;

  /// Quando o exame foi liberado (fase `disponivel`).
  final DateTime? liberadoEm;

  /// Exame em andamento, com o progresso de cada requisito.
  final RankExamState? exame;

  int get niveisFaltando => nivelMinimo > nivel ? nivelMinimo - nivel : 0;

  RankExamSpec? get spec =>
      proximoRank == null ? null : RankExamValues.specs[proximoRank];

  /// Dias que faltam para completar o tempo mínimo no rank (0 se já passou).
  int diasParaLiberarPorTempo(DateTime agora) {
    final dias = apenasDataLocal(liberaPorTempoEm)
        .difference(apenasDataLocal(agora))
        .inDays;
    return dias < 0 ? 0 : dias;
  }

  /// Dia em que o exame disponível começa sozinho.
  DateTime? get inicioAutomaticoEm => liberadoEm == null
      ? null
      : DateTime(liberadoEm!.year, liberadoEm!.month,
          liberadoEm!.day + RankExamValues.janelaParaIniciarDias);

  bool get precisaProgramar =>
      diasProgramadosPorSemana < RankExamValues.minDiasProgramados;
}

DateTime apenasDataLocal(DateTime d) => DateTime(d.year, d.month, d.day);

enum IniciarExameResultado {
  iniciado,
  precisaProgramar,
  modalidadesInvalidas,
  indisponivel,
}

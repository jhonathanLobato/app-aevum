import 'package:drift/drift.dart';

import '../../../database/app_database.dart';
import '../../../database/watch_tables.dart';
import '../../activities/domain/sport_activity.dart';
import '../../daily/domain/daily_values.dart';
import '../../profile/domain/level_curve.dart';
import '../../profile/domain/profile_repository.dart';
import '../../workouts/domain/workout_session.dart';
import '../domain/rank_exam.dart';
import '../domain/rank_exam_repository.dart';
import 'tables/rank_exam_table.dart';

class DriftRankExamRepository implements RankExamRepository {
  DriftRankExamRepository(this._db, this._profile, {DateTime Function()? agora})
      : _agora = agora ?? DateTime.now;

  final AppDatabase _db;
  final ProfileRepository _profile;
  final DateTime Function() _agora;

  /// Último exame ainda em andamento (disponível ou ativo).
  Future<RankExam?> _exameEmAndamento() {
    return (_db.select(_db.rankExams)
          ..where((e) =>
              e.status.equalsValue(RankExamStatus.ativo) |
              e.status.equalsValue(RankExamStatus.disponivel))
          ..orderBy(
              [(e) => OrderingTerm(expression: e.id, mode: OrderingMode.desc)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<Set<int>> _programacao() async => {
        for (final s in await _db.select(_db.scheduleDays).get()) s.weekday,
      };

  List<SportType> _decodificar(String csv) => [
        for (final nome in csv.split(',').where((n) => n.isNotEmpty))
          if (SportType.fromName(nome) != null) SportType.fromName(nome)!,
      ];

  /// Experiência de Caçador acumulada no rank atual, calculada dos dados
  /// reais desde [desde] (por isso editar/excluir registros ajusta os
  /// pontos e subir de rank, que reinicia [desde], zera tudo): 1 ponto por
  /// dia com treino de academia concluído + 0,5 por atividade extra de 30+
  /// min, no máximo 4 por semana (segunda a domingo). Missão diária não conta.
  Future<double> _experiencia(DateTime desde) async {
    final sessoes = await (_db.select(_db.workoutSessions)
          ..where((s) =>
              s.status.equalsValue(WorkoutSessionStatus.concluido) &
              s.data.isBiggerOrEqualValue(desde)))
        .get();
    final diasComTreino = {for (final s in sessoes) chaveDoDia(s.data)};

    final atividades = await (_db.select(_db.sportActivities)
          ..where((a) =>
              a.data.isBiggerOrEqualValue(apenasData(desde)) &
              a.duracaoMinutos
                  .isBiggerOrEqualValue(RankExamValues.minutosMinimos)))
        .get();
    final porSemana = <DateTime, int>{};
    for (final a in atividades) {
      final semana = inicioDaSemana(a.data);
      porSemana[semana] = (porSemana[semana] ?? 0) + 1;
    }
    final contadas = porSemana.values
        .map((n) => n > RankExamValues.maxAtividadesPorSemana
            ? RankExamValues.maxAtividadesPorSemana
            : n)
        .fold<int>(0, (a, b) => a + b);

    return diasComTreino.length * RankExamValues.pontosPorTreino +
        contadas * RankExamValues.pontosPorAtividade;
  }

  /// Quando o jogador entrou no rank atual (grava hoje se não há registro).
  Future<DateTime> _rankDesde(User usuario) async {
    final desde = usuario.rankDesde;
    if (desde != null) return desde;
    final agora = _agora();
    await (_db.update(_db.users)..where((u) => u.id.equals(usuario.id)))
        .write(UsersCompanion(rankDesde: Value(agora)));
    return agora;
  }

  @override
  Stream<RankStatus?> watchStatus() {
    return _db.observar([
      _db.rankExams,
      _db.users,
      _db.workoutSessions,
      _db.sportActivities,
      _db.dailyDays,
      _db.scheduleDays,
    ], () async {
      final usuario = await (_db.select(_db.users)..limit(1)).getSingleOrNull();
      if (usuario == null) return null;
      final programados = (await _programacao()).length;
      final desde = usuario.rankDesde ?? _agora();
      final alvo = proximoRank(usuario.rank);
      final exame = alvo == null ? null : await _exameEmAndamento();

      RankExamPhase fase;
      RankExamState? estado;
      if (alvo == null) {
        fase = RankExamPhase.maximo;
      } else if (exame != null && exame.status == RankExamStatus.ativo) {
        fase = RankExamPhase.emAndamento;
        estado = await _calcular(exame, usuario.rank);
      } else if (exame != null) {
        fase = RankExamPhase.disponivel;
      } else {
        fase = RankExamPhase.bloqueado;
      }

      return RankStatus(
        rankAtual: usuario.rank,
        nivel: usuario.nivel,
        proximoRank: alvo,
        fase: fase,
        nivelMinimo: alvo == null ? 0 : nivelMinimoDoRank(alvo),
        experienciaMinima:
            RankExamValues.experienciaMinimaNoRank[usuario.rank] ?? 0,
        experiencia: await _experiencia(desde),
        desde: desde,
        diasProgramadosPorSemana: programados,
        liberadoEm: fase == RankExamPhase.disponivel ? exame!.inicio : null,
        exame: estado,
      );
    });
  }

  @override
  Future<IniciarExameResultado> iniciarExame(List<SportType> modalidades) {
    return _db.transaction(() async {
      final exame = await _exameEmAndamento();
      if (exame == null || exame.status != RankExamStatus.disponivel) {
        return IniciarExameResultado.indisponivel;
      }
      final spec = RankExamValues.specs[exame.rankAlvo]!;
      final escolhidas = modalidades.toSet().toList();
      if (escolhidas.length != spec.modalidades) {
        return IniciarExameResultado.modalidadesInvalidas;
      }
      if ((await _programacao()).length < RankExamValues.minDiasProgramados) {
        return IniciarExameResultado.precisaProgramar;
      }
      await _iniciar(exame, escolhidas);
      return IniciarExameResultado.iniciado;
    });
  }

  Future<void> _iniciar(RankExam exame, List<SportType> modalidades) {
    return (_db.update(_db.rankExams)..where((e) => e.id.equals(exame.id)))
        .write(RankExamsCompanion(
      status: const Value(RankExamStatus.ativo),
      inicio: Value(_agora()),
      modalidades: Value(modalidades.map((m) => m.name).join(',')),
    ));
  }

  /// As [quantidade] modalidades mais registradas pelo usuário (empate e
  /// falta de registros: ordem do catálogo).
  Future<List<SportType>> _modalidadesMaisRegistradas(int quantidade) async {
    final registros = await _db.select(_db.sportActivities).get();
    final contagem = {for (final t in SportType.values) t: 0};
    for (final r in registros) {
      contagem[r.tipo] = contagem[r.tipo]! + 1;
    }
    final ordenadas = SportType.values.toList()
      ..sort((a, b) {
        final porRegistros = contagem[b]!.compareTo(contagem[a]!);
        return porRegistros != 0 ? porRegistros : a.index.compareTo(b.index);
      });
    return ordenadas.take(quantidade).toList();
  }

  Future<RankExamState> _calcular(RankExam exame, String rankAtual) async {
    final spec = RankExamValues.specs[exame.rankAlvo]!;
    final agora = _agora();
    final hoje = apenasData(agora);
    final inicioDia = apenasData(exame.inicio);
    final fim = somarDias(inicioDia, exame.prazoDias); // exclusivo
    final programacao = await _programacao();

    final linhas = {
      for (final d in await _db.select(_db.dailyDays).get()) d.dia: d,
    };

    // Treinos: meta = ⌈% × treinos programados no período⌉; folga em dia de
    // treino tira aquele treino da meta.
    var programadosNoPeriodo = 0;
    var folgas = 0;
    var cumpridas = 0;
    var abertosMissao = 0;
    for (var i = 0; i < exame.prazoDias; i++) {
      final dia = somarDias(inicioDia, i);
      final linha = linhas[chaveDoDia(dia)];
      final folga = linha?.folga ?? false;
      if (folga) {
        folgas++;
      } else {
        if (programacao.contains(dia.weekday)) programadosNoPeriodo++;
        if (linha?.concluida ?? false) {
          cumpridas++;
        } else if (!dia.isBefore(hoje)) {
          abertosMissao++;
        }
      }
    }
    final metaTreinos =
        (spec.fracaoTreinos * programadosNoPeriodo - 1e-9).ceil();

    // Treinos de academia concluídos no período (conta dias distintos).
    final sessoes = await (_db.select(_db.workoutSessions)
          ..where((s) =>
              s.status.equalsValue(WorkoutSessionStatus.concluido) &
              s.data.isBiggerOrEqualValue(inicioDia)))
        .get();
    final diasComTreino = {
      for (final s in sessoes)
        if (s.data.isBefore(fim)) chaveDoDia(s.data),
    };
    final treinouHoje = diasComTreino.contains(chaveDoDia(hoje));
    var abertosTreino = 0;
    for (var i = 0; i < exame.prazoDias; i++) {
      final dia = somarDias(inicioDia, i);
      if (dia.isBefore(hoje)) continue;
      if (linhas[chaveDoDia(dia)]?.folga ?? false) continue;
      if (dia == hoje && treinouHoje) continue;
      abertosTreino++;
    }

    // Atividades extras (30+ min) por modalidade escolhida.
    final escolhidas = _decodificar(exame.modalidades);
    final atividades = await (_db.select(_db.sportActivities)
          ..where((a) =>
              a.data.isBiggerOrEqualValue(inicioDia) &
              a.duracaoMinutos
                  .isBiggerOrEqualValue(RankExamValues.minutosMinimos)))
        .get();
    final modalidades = [
      for (final tipo in escolhidas)
        ModalityProgress(
          tipo: tipo,
          registros: atividades.where((a) => a.tipo == tipo).length,
          necessarios: spec.registrosPorModalidade,
        ),
    ];

    final validos = exame.prazoDias - folgas;
    final necessariasMissao = (spec.fracaoMissaoDiaria * validos - 1e-9).ceil();

    final restantes = fim.difference(hoje).inDays;
    return RankExamState(
      rankAtual: rankAtual,
      rankAlvo: exame.rankAlvo,
      inicio: exame.inicio,
      fim: fim,
      diasRestantes: restantes < 0 ? 0 : restantes,
      fracaoTreinos: spec.fracaoTreinos,
      treinosProgramadosNoPeriodo: programadosNoPeriodo,
      treinosFeitos: diasComTreino.length,
      treinosNecessarios: metaTreinos,
      diasAbertosTreino: abertosTreino,
      modalidadesNecessarias: spec.modalidades,
      registrosPorModalidade: spec.registrosPorModalidade,
      modalidades: modalidades,
      fracaoMissaoDiaria: spec.fracaoMissaoDiaria,
      missoesCumpridas: cumpridas,
      missoesNecessarias: necessariasMissao,
      diasValidos: validos,
      diasAbertos: abertosMissao,
      reinicios: exame.reinicios,
    );
  }

  String? _rankAnterior(String alvo) {
    const ordem = ['F', 'E', 'D', 'C', 'B', 'A', 'S'];
    final i = ordem.indexOf(alvo.toUpperCase());
    return i > 0 ? ordem[i - 1] : null;
  }

  @override
  Future<void> confirmarRankUp(String rankAlvo) {
    return (_db.update(_db.rankExams)
          ..where((e) =>
              e.rankAlvo.equals(rankAlvo) &
              e.status.equalsValue(RankExamStatus.aprovado)))
        .write(const RankExamsCompanion(visto: Value(true)));
  }

  @override
  Future<List<RankExamEvent>> sincronizar() {
    return _db.transaction(() async {
      final usuario = await (_db.select(_db.users)..limit(1)).getSingleOrNull();
      if (usuario == null) return const <RankExamEvent>[];

      final eventos = <RankExamEvent>[];
      final agora = _agora();

      // RANK UPs aprovados que o usuário ainda não viu (app fechado).
      final pendentes = await (_db.select(_db.rankExams)
            ..where((e) =>
                e.status.equalsValue(RankExamStatus.aprovado) &
                e.visto.equals(false))
            ..orderBy([(e) => OrderingTerm(expression: e.id)]))
          .get();
      for (final p in pendentes) {
        eventos.add(RankExamEvent(RankExamEventType.aprovado,
            rankAlvo: p.rankAlvo, rankAnterior: _rankAnterior(p.rankAlvo)));
      }

      final desde = await _rankDesde(usuario);
      final alvo = proximoRank(usuario.rank);
      if (alvo == null) return eventos;

      var exame = await _exameEmAndamento();

      // Exame de um rank que já não é o próximo (ex.: dados antigos).
      if (exame != null && exame.rankAlvo != alvo) {
        await (_db.delete(_db.rankExams)..where((e) => e.id.equals(exame!.id)))
            .go();
        exame = null;
      }

      // Libera: nível mínimo E experiência mínima no rank atual.
      if (exame == null) {
        final minima =
            RankExamValues.experienciaMinimaNoRank[usuario.rank] ?? 0;
        final experienciaOk = await _experiencia(desde) >= minima;
        if (usuario.nivel < nivelMinimoDoRank(alvo) || !experienciaOk) {
          return eventos;
        }
        final spec = RankExamValues.specs[alvo]!;
        await _db.into(_db.rankExams).insert(RankExamsCompanion.insert(
              rankAlvo: alvo,
              inicio: agora,
              prazoDias: spec.prazoDias,
              status: const Value(RankExamStatus.disponivel),
            ));
        eventos.add(RankExamEvent(RankExamEventType.liberado, rankAlvo: alvo));
        return eventos;
      }

      // Disponível: no 8º dia sem iniciar, começa sozinho (se já houver 2+
      // dias de treino programados), com as modalidades mais registradas.
      if (exame.status == RankExamStatus.disponivel) {
        final limite = somarDias(
            apenasData(exame.inicio), RankExamValues.janelaParaIniciarDias);
        final venceu = !apenasData(agora).isBefore(limite);
        final programados = (await _programacao()).length;
        if (venceu && programados >= RankExamValues.minDiasProgramados) {
          final spec = RankExamValues.specs[alvo]!;
          final escolhidas =
              await _modalidadesMaisRegistradas(spec.modalidades);
          await _iniciar(exame, escolhidas);
          eventos.add(RankExamEvent(RankExamEventType.iniciadoAutomaticamente,
              rankAlvo: alvo, modalidades: escolhidas));
        }
        return eventos;
      }

      final estado = await _calcular(exame, usuario.rank);

      if (estado.aprovado) {
        await (_db.update(_db.rankExams)..where((e) => e.id.equals(exame!.id)))
            .write(const RankExamsCompanion(
          status: Value(RankExamStatus.aprovado),
          visto: Value(false),
        ));
        await _profile.setRank(alvo);
        eventos.add(RankExamEvent(RankExamEventType.aprovado,
            rankAlvo: alvo, rankAnterior: usuario.rank));
        return eventos;
      }

      RankExamResetReason? motivo;
      if (estado.missoesImpossiveis) {
        motivo = RankExamResetReason.missaoDiariaImpossivel;
      } else if (estado.treinosImpossiveis) {
        motivo = RankExamResetReason.treinosImpossivel;
      } else if (!agora.isBefore(estado.fim)) {
        motivo = RankExamResetReason.prazo;
      }
      if (motivo == null) return eventos;

      // Falhou: zera o progresso e abre uma nova janela de 7 dias para
      // iniciar (as atividades extras são escolhidas de novo).
      await (_db.update(_db.rankExams)..where((e) => e.id.equals(exame!.id)))
          .write(RankExamsCompanion(
        status: const Value(RankExamStatus.disponivel),
        inicio: Value(agora),
        modalidades: const Value(''),
        reinicios: Value(exame.reinicios + 1),
      ));
      eventos.add(RankExamEvent(RankExamEventType.reiniciado,
          rankAlvo: alvo, motivo: motivo));
      return eventos;
    });
  }
}

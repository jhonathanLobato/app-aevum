import 'package:drift/drift.dart';

import '../../../database/app_database.dart';
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

  Future<RankExam?> _exameAtivo() {
    return (_db.select(_db.rankExams)
          ..where((e) => e.status.equalsValue(RankExamStatus.ativo))
          ..orderBy(
              [(e) => OrderingTerm(expression: e.id, mode: OrderingMode.desc)])
          ..limit(1))
        .getSingleOrNull();
  }

  List<SportType> _decodificar(String csv) => [
        for (final nome in csv.split(',').where((n) => n.isNotEmpty))
          if (SportType.fromName(nome) != null) SportType.fromName(nome)!,
      ];

  @override
  Stream<RankExamState?> watchAtivo() async* {
    Future<RankExamState?> carregar() async {
      final exame = await _exameAtivo();
      final usuario = await (_db.select(_db.users)..limit(1)).getSingleOrNull();
      if (exame == null || usuario == null) return null;
      return _calcular(exame, usuario.rank);
    }

    yield await carregar();
    yield* _db
        .tableUpdates(TableUpdateQuery.onAllTables([
          _db.rankExams,
          _db.users,
          _db.workoutSessions,
          _db.sportActivities,
          _db.dailyDays,
        ]))
        .asyncMap((_) => carregar());
  }

  @override
  Future<void> escolherModalidades(List<SportType> modalidades) async {
    final exame = await _exameAtivo();
    if (exame == null) return;
    final spec = RankExamValues.specs[exame.rankAlvo]!;
    final escolhidas = modalidades.toSet().take(spec.modalidades).toList();
    await (_db.update(_db.rankExams)..where((e) => e.id.equals(exame.id)))
        .write(RankExamsCompanion(
            modalidades: Value(escolhidas.map((m) => m.name).join(','))));
  }

  Future<RankExamState> _calcular(RankExam exame, String rankAtual) async {
    final spec = RankExamValues.specs[exame.rankAlvo]!;
    final agora = _agora();
    final hoje = apenasData(agora);
    final inicioDia = apenasData(exame.inicio);
    final fim = somarDias(inicioDia, exame.prazoDias); // exclusivo

    // Treinos de academia concluídos no período.
    final treinos = await (_db.select(_db.workoutSessions)
          ..where((s) =>
              s.status.equalsValue(WorkoutSessionStatus.concluido) &
              s.data.isBiggerOrEqualValue(inicioDia)))
        .get();

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

    // Missão diária no período (folgas fora do cálculo).
    final linhas = {
      for (final d in await _db.select(_db.dailyDays).get()) d.dia: d,
    };
    var cumpridas = 0;
    var folgas = 0;
    var abertos = 0;
    for (var i = 0; i < exame.prazoDias; i++) {
      final dia = somarDias(inicioDia, i);
      final linha = linhas[chaveDoDia(dia)];
      if (linha?.folga ?? false) {
        folgas++;
      } else if (linha?.concluida ?? false) {
        cumpridas++;
      } else if (!dia.isBefore(hoje)) {
        abertos++;
      }
    }
    final validos = exame.prazoDias - folgas;
    final necessarias = (RankExamValues.fracaoMissaoDiaria * validos).ceil();

    final restantes = fim.difference(hoje).inDays;
    return RankExamState(
      rankAtual: rankAtual,
      rankAlvo: exame.rankAlvo,
      inicio: exame.inicio,
      fim: fim,
      diasRestantes: restantes < 0 ? 0 : restantes,
      treinosFeitos: treinos.length,
      treinosNecessarios: spec.treinos,
      modalidadesNecessarias: spec.modalidades,
      registrosPorModalidade: spec.registrosPorModalidade,
      modalidades: modalidades,
      missoesCumpridas: cumpridas,
      missoesNecessarias: necessarias,
      diasValidos: validos,
      diasAbertos: abertos,
      reinicios: exame.reinicios,
    );
  }

  @override
  Future<List<RankExamEvent>> sincronizar() {
    return _db.transaction(() async {
      final usuario = await (_db.select(_db.users)..limit(1)).getSingleOrNull();
      if (usuario == null) return const <RankExamEvent>[];

      final alvo = proximoRank(usuario.rank);
      if (alvo == null) return const <RankExamEvent>[];

      var exame = await _exameAtivo();

      // Exame de um rank que já não é o próximo (ex.: dados antigos).
      if (exame != null && exame.rankAlvo != alvo) {
        await (_db.delete(_db.rankExams)..where((e) => e.id.equals(exame!.id)))
            .go();
        exame = null;
      }

      if (exame == null) {
        if (usuario.nivel < nivelMinimoDoRank(alvo)) return const [];
        final spec = RankExamValues.specs[alvo]!;
        await _db.into(_db.rankExams).insert(RankExamsCompanion.insert(
              rankAlvo: alvo,
              inicio: _agora(),
              prazoDias: spec.prazoDias,
            ));
        return [RankExamEvent(RankExamEventType.liberado, rankAlvo: alvo)];
      }

      final estado = await _calcular(exame, usuario.rank);

      if (estado.aprovado) {
        await (_db.update(_db.rankExams)..where((e) => e.id.equals(exame!.id)))
            .write(const RankExamsCompanion(
                status: Value(RankExamStatus.aprovado)));
        await _profile.setRank(alvo);
        return [
          RankExamEvent(RankExamEventType.aprovado,
              rankAlvo: alvo, rankAnterior: usuario.rank),
        ];
      }

      RankExamResetReason? motivo;
      if (estado.missoesImpossiveis) {
        motivo = RankExamResetReason.missaoDiariaImpossivel;
      } else if (!_agora().isBefore(estado.fim)) {
        motivo = RankExamResetReason.prazo;
      }
      if (motivo == null) return const [];

      await (_db.update(_db.rankExams)..where((e) => e.id.equals(exame!.id)))
          .write(RankExamsCompanion(
        inicio: Value(_agora()),
        reinicios: Value(exame.reinicios + 1),
      ));
      return [
        RankExamEvent(RankExamEventType.reiniciado,
            rankAlvo: alvo, motivo: motivo),
      ];
    });
  }
}

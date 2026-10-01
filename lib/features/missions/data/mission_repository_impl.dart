import 'package:drift/drift.dart';

import '../../../database/app_database.dart' hide Mission;
import '../../../database/app_database.dart' as db;
import '../domain/mission.dart';
import '../domain/mission_repository.dart';
import '../domain/mission_values.dart';

class DriftMissionRepository implements MissionRepository {
  DriftMissionRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Mission>> watchActive() {
    final query = _db.select(_db.missions)
      ..where((m) => m.status.equalsValue(MissionStatus.ativa))
      ..orderBy([(m) => OrderingTerm(expression: m.criadoEm)]);

    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<void> ensureRecurringMissions() {
    return _db.transaction(() async {
      await _garantirMissaoDiaria();
      await _garantirMissaoSemanal();
    });
  }

  @override
  Future<List<Mission>> registrarTreinoConcluido() {
    return _db.transaction(() async {
      final diaria = await _garantirMissaoDiaria();
      final semanal = await _garantirMissaoSemanal();

      final concluidas = <Mission>[];
      for (final mission in [diaria, semanal]) {
        final atualizada = await _avancarMissao(mission);
        if (atualizada.status == MissionStatus.concluida) {
          concluidas.add(atualizada);
        }
      }
      return concluidas;
    });
  }

  @override
  Future<Mission?> registrarNovoRecordeDeCarga({
    required int exerciseId,
    required String exerciseNome,
    required double novoRecorde,
  }) {
    return _db.transaction(() async {
      final desafioAtivo = await (_db.select(_db.missions)
            ..where((m) =>
                m.tipo.equalsValue(MissionType.desafio) &
                m.exerciseId.equals(exerciseId) &
                m.status.equalsValue(MissionStatus.ativa)))
          .getSingleOrNull();

      Mission? concluido;
      if (desafioAtivo != null && novoRecorde >= desafioAtivo.objetivo) {
        await (_db.update(_db.missions)
              ..where((m) => m.id.equals(desafioAtivo.id)))
            .write(const MissionsCompanion(
                status: Value(MissionStatus.concluida)));
        concluido =
            _toDomain(desafioAtivo).progressoAtualizado(desafioAtivo.objetivo);
      }

      final continuaEmAndamento = concluido == null && desafioAtivo != null;
      if (!continuaEmAndamento) {
        final objetivo =
            (novoRecorde + MissionValues.incrementoDesafioCarga).round();
        await _db.into(_db.missions).insert(
              MissionsCompanion.insert(
                tipo: MissionType.desafio,
                nome: 'Supere seu recorde: $exerciseNome',
                descricao:
                    'Aumente seu recorde de carga em $exerciseNome para ${objetivo}kg.',
                recompensaXp: MissionValues.xpDesafio,
                objetivo: objetivo,
                exerciseId: Value(exerciseId),
              ),
            );
      }

      return concluido;
    });
  }

  Future<db.Mission> _garantirMissaoDiaria() async {
    final hoje = _apenasData(DateTime.now());
    final ativa = await (_db.select(_db.missions)
          ..where((m) =>
              m.tipo.equalsValue(MissionType.diaria) &
              m.status.equalsValue(MissionStatus.ativa)))
        .getSingleOrNull();

    if (ativa != null && _apenasData(ativa.criadoEm) == hoje) {
      return ativa;
    }
    if (ativa != null) {
      await _expirar(ativa.id);
    }

    final id = await _db.into(_db.missions).insert(
          MissionsCompanion.insert(
            tipo: MissionType.diaria,
            nome: 'Missão diária',
            descricao: 'Complete seu treino.',
            recompensaXp: MissionValues.xpMissaoDiaria,
            objetivo: 1,
          ),
        );
    return (_db.select(_db.missions)..where((m) => m.id.equals(id)))
        .getSingle();
  }

  Future<db.Mission> _garantirMissaoSemanal() async {
    final inicioSemana = _inicioDaSemana(DateTime.now());
    final ativa = await (_db.select(_db.missions)
          ..where((m) =>
              m.tipo.equalsValue(MissionType.semanal) &
              m.status.equalsValue(MissionStatus.ativa)))
        .getSingleOrNull();

    if (ativa != null &&
        !_inicioDaSemana(ativa.criadoEm).isBefore(inicioSemana)) {
      return ativa;
    }
    if (ativa != null) {
      await _expirar(ativa.id);
    }

    const objetivo = MissionValues.treinosPorMissaoSemanal;
    final id = await _db.into(_db.missions).insert(
          MissionsCompanion.insert(
            tipo: MissionType.semanal,
            nome: 'Missão semanal',
            descricao: 'Complete $objetivo treinos.',
            recompensaXp: MissionValues.xpMissaoSemanal,
            objetivo: objetivo,
          ),
        );
    return (_db.select(_db.missions)..where((m) => m.id.equals(id)))
        .getSingle();
  }

  Future<Mission> _avancarMissao(db.Mission mission) async {
    final novoProgresso = mission.progresso + 1;
    final concluida = novoProgresso >= mission.objetivo;

    await (_db.update(_db.missions)..where((m) => m.id.equals(mission.id)))
        .write(
      MissionsCompanion(
        progresso: Value(novoProgresso),
        status:
            Value(concluida ? MissionStatus.concluida : MissionStatus.ativa),
      ),
    );

    return _toDomain(mission)
        .progressoAtualizado(novoProgresso, concluida: concluida);
  }

  Future<void> _expirar(int missionId) {
    return (_db.update(_db.missions)..where((m) => m.id.equals(missionId)))
        .write(const MissionsCompanion(status: Value(MissionStatus.expirada)));
  }

  DateTime _apenasData(DateTime data) =>
      DateTime(data.year, data.month, data.day);

  DateTime _inicioDaSemana(DateTime data) {
    final dia = _apenasData(data);
    return dia.subtract(Duration(days: dia.weekday - DateTime.monday));
  }

  Mission _toDomain(db.Mission row) {
    return Mission(
      id: row.id,
      tipo: row.tipo,
      nome: row.nome,
      descricao: row.descricao,
      recompensaXp: row.recompensaXp,
      progresso: row.progresso,
      objetivo: row.objetivo,
      status: row.status,
      criadoEm: row.criadoEm,
      exerciseId: row.exerciseId,
    );
  }
}

extension on Mission {
  Mission progressoAtualizado(int progresso, {bool concluida = true}) {
    return Mission(
      id: id,
      tipo: tipo,
      nome: nome,
      descricao: descricao,
      recompensaXp: recompensaXp,
      progresso: progresso,
      objetivo: objetivo,
      status: concluida ? MissionStatus.concluida : status,
      criadoEm: criadoEm,
      exerciseId: exerciseId,
    );
  }
}

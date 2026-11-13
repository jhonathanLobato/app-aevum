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
  Stream<List<Mission>> watchRecentHistory() {
    final inicioSemana = _inicioDaSemana(DateTime.now());
    final query = _db.select(_db.missions)
      ..where((m) => m.status.equalsValue(MissionStatus.concluida))
      ..orderBy([
        (m) => OrderingTerm(expression: m.criadoEm, mode: OrderingMode.desc)
      ]);

    return query.watch().map((rows) => rows
        .where((row) => !_inicioDaSemana(row.criadoEm).isBefore(inicioSemana))
        .map(_toDomain)
        .toList());
  }

  @override
  Future<void> ensureRecurringMissions() {
    return _db.transaction(() async {
      await _sincronizarMissaoSemanal();
    });
  }

  @override
  Future<List<Mission>> registrarTreinoConcluido() {
    return _db.transaction(() async {
      final semanal = await _sincronizarMissaoSemanal();
      if (semanal == null) return const <Mission>[];
      final atualizada = await _avancarMissao(semanal);
      if (atualizada != null && atualizada.status == MissionStatus.concluida) {
        return [atualizada];
      }
      return const <Mission>[];
    });
  }

  @override
  Future<Mission?> registrarNovoRecordeDeCarga({
    required int exerciseId,
    required String exerciseNome,
    required double novoRecorde,
    bool criarProximo = true,
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
      if (criarProximo && !continuaEmAndamento) {
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

  /// Garante a missão semanal desta semana, alinhada à programação:
  /// objetivo = nº de dias de treino programados, XP conforme a tabela.
  /// Sem treinos programados não há missão semanal (`null`). Se a
  /// programação mudar no meio da semana, objetivo e XP acompanham.
  Future<db.Mission?> _sincronizarMissaoSemanal() async {
    final programados = (await _db.select(_db.scheduleDays).get()).length;
    final inicioSemana = _inicioDaSemana(DateTime.now());

    final maisRecente = await (_db.select(_db.missions)
          ..where((m) => m.tipo.equalsValue(MissionType.semanal))
          ..orderBy([
            (m) => OrderingTerm(expression: m.criadoEm, mode: OrderingMode.desc)
          ])
          ..limit(1))
        .getSingleOrNull();

    final dessaSemana = maisRecente != null &&
        !_inicioDaSemana(maisRecente.criadoEm).isBefore(inicioSemana);

    if (!dessaSemana) {
      if (maisRecente != null && maisRecente.status == MissionStatus.ativa) {
        await _expirar(maisRecente.id);
      }
      if (programados == 0) return null;
      return _criarSemanal(programados);
    }

    if (maisRecente.status == MissionStatus.ativa) {
      if (programados == 0) {
        await _expirar(maisRecente.id);
        return null;
      }
      if (maisRecente.objetivo != programados) {
        await (_db.update(_db.missions)
              ..where((m) => m.id.equals(maisRecente.id)))
            .write(MissionsCompanion(
          objetivo: Value(programados),
          recompensaXp: Value(MissionValues.xpSemanal(programados)),
          descricao: Value(_descricaoSemanal(programados)),
        ));
        return (_db.select(_db.missions)
              ..where((m) => m.id.equals(maisRecente.id)))
            .getSingle();
      }
    }
    return maisRecente;
  }

  String _descricaoSemanal(int n) => n == 1
      ? 'Conclua o treino programado da semana.'
      : 'Conclua os $n treinos programados da semana.';

  Future<db.Mission> _criarSemanal(int programados) async {
    final id = await _db.into(_db.missions).insert(
          MissionsCompanion.insert(
            tipo: MissionType.semanal,
            nome: 'Missão semanal',
            descricao: _descricaoSemanal(programados),
            recompensaXp: MissionValues.xpSemanal(programados),
            objetivo: programados,
          ),
        );
    return (_db.select(_db.missions)..where((m) => m.id.equals(id)))
        .getSingle();
  }

  Future<Mission?> _avancarMissao(db.Mission mission) async {
    // Segunda camada de proteção: mesmo que algum chamador futuro passe
    // uma missão já concluída pra cá, não soma progresso nem reporta de
    // novo como "recém concluída" (evita XP duplicado). `null` sinaliza
    // pro chamador que nada mudou nesta chamada (diferente de "concluída
    // agora"), pra não contar a mesma conclusão duas vezes.
    if (mission.status == MissionStatus.concluida) {
      return null;
    }

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
      // A tabela `Missions` ainda não tem coluna pra isso (Fase 7, seção 8)
      // — quando a migration for feita, passa a ler `row.minimumRank` aqui.
      minimumRank: null,
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
      minimumRank: minimumRank,
    );
  }
}

import 'package:drift/drift.dart';

import '../../../database/app_database.dart' hide Achievement;
import '../../../database/app_database.dart' as db;
import '../../profile/domain/level_curve.dart';
import '../../workouts/domain/workout_session.dart';
import '../domain/achievement.dart';
import '../domain/achievement_repository.dart';

class DriftAchievementRepository implements AchievementRepository {
  DriftAchievementRepository(this._db);

  final AppDatabase _db;

  static const _metasPorTreinosConcluidos = {
    'primeiros_passos': 1,
    'disciplina': 10,
    'constancia': 25,
    'veterano': 100,
  };

  static const _metaQuebraDeRecordePRs = 5;
  static const _metaPrimeiroMilharKg = 1000.0;
  static const _ranksMinimosPorChave = {'rank_e': 'E'};

  @override
  Stream<List<Achievement>> watchAll() {
    final query = _db.select(_db.achievements)
      ..orderBy([(a) => OrderingTerm(expression: a.id)]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<void> ensureCatalog() async {
    for (final definicao in kAchievementCatalog) {
      final existente = await (_db.select(_db.achievements)
            ..where((a) => a.chave.equals(definicao.chave)))
          .getSingleOrNull();
      if (existente != null) {
        await (_db.update(_db.achievements)
              ..where((a) => a.chave.equals(definicao.chave)))
            .write(AchievementsCompanion(
          nome: Value(definicao.nome),
          descricao: Value(definicao.descricao),
          requisito: Value(definicao.requisito),
        ));
      } else {
        await _db.into(_db.achievements).insert(
              AchievementsCompanion.insert(
                chave: definicao.chave,
                nome: definicao.nome,
                descricao: definicao.descricao,
                icone: Value(definicao.icone),
                requisito: definicao.requisito,
              ),
            );
      }
    }
  }

  @override
  Future<List<Achievement>> verificarRank() {
    return _db.transaction(() async {
      await ensureCatalog();
      return _verificarRanks();
    });
  }

  @override
  Future<List<Achievement>> verificarPorTreinoConcluido() {
    return _db.transaction(() async {
      await ensureCatalog();
      final totalConcluidos = await _contarTreinosConcluidos();

      final desbloqueadas = <Achievement>[];
      for (final entry in _metasPorTreinosConcluidos.entries) {
        if (totalConcluidos >= entry.value) {
          final desbloqueada = await _desbloquearSeNecessario(entry.key);
          if (desbloqueada != null) desbloqueadas.add(desbloqueada);
        }
      }

      // Volume acumula em toda série registrada (não só quando há PR), então
      // o fim do treino — chamado sempre — é o ponto certo pra conferir.
      if (await _somarVolumeTotal() >= _metaPrimeiroMilharKg) {
        final d = await _desbloquearSeNecessario('primeiro_milhar');
        if (d != null) desbloqueadas.add(d);
      }

      desbloqueadas.addAll(await _verificarRanks());
      return desbloqueadas;
    });
  }

  @override
  Future<List<Achievement>> verificarPorNovoRecorde() {
    return _db.transaction(() async {
      await ensureCatalog();
      final desbloqueadas = <Achievement>[];

      final evolucao = await _desbloquearSeNecessario('evolucao');
      if (evolucao != null) desbloqueadas.add(evolucao);

      if (await _passaramSeteDiasSemTreinar()) {
        final superacao = await _desbloquearSeNecessario('superacao');
        if (superacao != null) desbloqueadas.add(superacao);
      }

      if (await _contarPRs() >= _metaQuebraDeRecordePRs) {
        final d = await _desbloquearSeNecessario('quebra_de_recorde');
        if (d != null) desbloqueadas.add(d);
      }

      // XP de PR pode subir o rank no meio de uma sessão, antes do treino
      // acabar — por isso também confere rank aqui, não só no fim do treino.
      desbloqueadas.addAll(await _verificarRanks());

      return desbloqueadas;
    });
  }

  Future<int> _contarTreinosConcluidos() async {
    final contagem = _db.workoutSessions.id.count();
    return (_db.selectOnly(_db.workoutSessions)
          ..addColumns([contagem])
          ..where(_db.workoutSessions.status
              .equalsValue(WorkoutSessionStatus.concluido)))
        .map((row) => row.read(contagem)!)
        .getSingle();
  }

  Future<double> _somarVolumeTotal() async {
    final soma = _db.setEntries.volume.sum();
    final resultado = await (_db.selectOnly(_db.setEntries).join([
      innerJoin(
        _db.workoutSessions,
        _db.workoutSessions.id.equalsExp(_db.setEntries.sessionId),
      ),
    ])
          ..addColumns([soma])
          ..where(_db.workoutSessions.status
              .equalsValue(WorkoutSessionStatus.concluido)))
        .getSingle();
    return resultado.read(soma) ?? 0;
  }

  Future<int> _contarPRs() async {
    final contagem = _db.personalRecords.id.count();
    return (_db.selectOnly(_db.personalRecords)..addColumns([contagem]))
        .map((row) => row.read(contagem)!)
        .getSingle();
  }

  Future<List<Achievement>> _verificarRanks() async {
    final usuario = await (_db.select(_db.users)..limit(1)).getSingleOrNull();
    if (usuario == null) return [];

    final desbloqueadas = <Achievement>[];
    for (final entry in _ranksMinimosPorChave.entries) {
      if (rankAtende(usuario.rank, entry.value)) {
        final d = await _desbloquearSeNecessario(entry.key);
        if (d != null) desbloqueadas.add(d);
      }
    }
    return desbloqueadas;
  }

  Future<bool> _passaramSeteDiasSemTreinar() async {
    final ultimoTreino = await (_db.select(_db.workoutSessions)
          ..where((s) => s.status.equalsValue(WorkoutSessionStatus.concluido))
          ..orderBy([
            (s) => OrderingTerm(expression: s.data, mode: OrderingMode.desc)
          ])
          ..limit(1))
        .getSingleOrNull();

    if (ultimoTreino == null) return false;
    return DateTime.now().difference(ultimoTreino.data).inDays >= 7;
  }

  Future<Achievement?> _desbloquearSeNecessario(String chave) async {
    final atual = await (_db.select(_db.achievements)
          ..where((a) => a.chave.equals(chave)))
        .getSingleOrNull();
    if (atual == null || atual.status == AchievementStatus.desbloqueada) {
      return null;
    }

    await (_db.update(_db.achievements)..where((a) => a.chave.equals(chave)))
        .write(
      AchievementsCompanion(
        status: const Value(AchievementStatus.desbloqueada),
        dataDesbloqueio: Value(DateTime.now()),
      ),
    );

    final atualizada = await (_db.select(_db.achievements)
          ..where((a) => a.chave.equals(chave)))
        .getSingle();
    return _toDomain(atualizada);
  }

  Achievement _toDomain(db.Achievement row) {
    return Achievement(
      id: row.id,
      chave: row.chave,
      nome: row.nome,
      descricao: row.descricao,
      icone: row.icone ?? 'emoji_events',
      requisito: row.requisito,
      status: row.status,
      dataDesbloqueio: row.dataDesbloqueio,
    );
  }
}

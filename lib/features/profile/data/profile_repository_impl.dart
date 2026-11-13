import 'package:drift/drift.dart';

import '../../../database/app_database.dart';
import '../../../database/watch_tables.dart';
import '../domain/app_theme.dart';
import '../domain/level_curve.dart';
import '../domain/player_class.dart';
import '../domain/profile_repository.dart';
import '../domain/titles.dart';
import '../domain/units.dart';
import '../domain/user_profile.dart';

class DriftProfileRepository implements ProfileRepository {
  DriftProfileRepository(
    this._db, {
    LevelCurve levelCurve = const LevelCurve(),
    DateTime Function()? agora,
  })  : _levelCurve = levelCurve,
        _agora = agora ?? DateTime.now;

  final DateTime Function() _agora;

  final AppDatabase _db;
  final LevelCurve _levelCurve;

  @override
  Stream<UserProfile?> watchCurrentUser() {
    final query = _db.select(_db.users)..limit(1);
    return query.watch().map((rows) {
      if (rows.isEmpty) return null;
      return _toProfile(rows.first);
    });
  }

  @override
  Future<XpGainResult> addXp(int quantidade) {
    return _db.transaction(() async {
      final userId = await _ensureCurrentUserId();
      final atual = await (_db.select(_db.users)
            ..where((u) => u.id.equals(userId)))
          .getSingle();

      final novoXpTotal = atual.xp + quantidade;
      final infoAnterior = _levelCurve.calcularNivel(atual.xp);
      final infoNova = _levelCurve.calcularNivel(novoXpTotal);

      await (_db.update(_db.users)..where((u) => u.id.equals(userId))).write(
        UsersCompanion(
          xp: Value(novoXpTotal),
          nivel: Value(infoNova.nivel),
        ),
      );

      // O rank não acompanha o nível: só muda pelo exame de rank.
      return XpGainResult(
        xpGanho: quantidade,
        nivelAnterior: infoAnterior.nivel,
        novoNivel: infoNova.nivel,
        rankAnterior: atual.rank,
        novoRank: atual.rank,
      );
    });
  }

  @override
  Future<int> removeXp(int quantidade, {bool respeitarPisoDoNivel = true}) {
    return _db.transaction(() async {
      final userId = await _ensureCurrentUserId();
      final atual = await (_db.select(_db.users)
            ..where((u) => u.id.equals(userId)))
          .getSingle();

      final piso =
          respeitarPisoDoNivel ? _levelCurve.xpNoInicioDoNivel(atual.nivel) : 0;
      final novoXp =
          (atual.xp - quantidade) < piso ? piso : atual.xp - quantidade;
      final perdido = atual.xp - novoXp;
      if (perdido > 0) {
        await (_db.update(_db.users)..where((u) => u.id.equals(userId)))
            .write(UsersCompanion(
          xp: Value(novoXp),
          nivel: Value(_levelCurve.calcularNivel(novoXp).nivel),
        ));
      }
      return perdido < 0 ? 0 : perdido;
    });
  }

  @override
  Future<void> setRank(String rank) async {
    final userId = await _ensureCurrentUserId();
    await (_db.update(_db.users)..where((u) => u.id.equals(userId)))
        .write(UsersCompanion(
      rank: Value(rank),
      rankDesde: Value(_agora()),
    ));
  }

  @override
  Stream<DateTime?> watchDespertar() {
    return _db.observar([
      _db.users,
      _db.workoutSessions,
      _db.sportActivities,
      _db.bodyRecords,
    ], () async {
      final candidatas = <DateTime>[];
      final u = await (_db.select(_db.users)..limit(1)).getSingleOrNull();
      if (u?.criadoEm != null) candidatas.add(u!.criadoEm!);
      final s = await (_db.select(_db.workoutSessions)
            ..orderBy([(t) => OrderingTerm(expression: t.data)])
            ..limit(1))
          .getSingleOrNull();
      if (s != null) candidatas.add(s.data);
      final a = await (_db.select(_db.sportActivities)
            ..orderBy([(t) => OrderingTerm(expression: t.data)])
            ..limit(1))
          .getSingleOrNull();
      if (a != null) candidatas.add(a.data);
      final b = await (_db.select(_db.bodyRecords)
            ..orderBy([(t) => OrderingTerm(expression: t.data)])
            ..limit(1))
          .getSingleOrNull();
      if (b != null) candidatas.add(b.data);
      if (candidatas.isEmpty) return null;
      return candidatas.reduce((x, y) => x.isBefore(y) ? x : y);
    });
  }

  @override
  Future<void> salvarFicha({
    required String nome,
    required String? avatar,
    required PlayerClass classe,
    required String titulo,
    required AppTheme tema,
    required Units unidades,
    double? alturaCm,
    DateTime? nascimento,
    Sexo? sexo,
  }) async {
    final userId = await _ensureCurrentUserId();
    await (_db.update(_db.users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(
        nome: Value(nome),
        avatar: Value(avatar),
        classe: Value(classe),
        titulo: Value(titulo),
        tema: Value(tema),
        unidadePeso: Value(unidades.peso),
        unidadeComprimento: Value(unidades.comprimento),
        alturaCm: Value(alturaCm),
        nascimento: Value(nascimento),
        sexo: Value(sexo),
      ),
    );
  }

  @override
  Future<void> updateProfile({
    String? nome,
    String? avatar,
    PlayerClass? classe,
    String? titulo,
    AppTheme? tema,
  }) async {
    final userId = await _ensureCurrentUserId();
    await (_db.update(_db.users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(
        nome: nome == null ? const Value.absent() : Value(nome),
        avatar: avatar == null ? const Value.absent() : Value(avatar),
        classe: classe == null ? const Value.absent() : Value(classe),
        titulo: titulo == null ? const Value.absent() : Value(titulo),
        tema: tema == null ? const Value.absent() : Value(tema),
      ),
    );
  }

  Future<int> _ensureCurrentUserId() async {
    final existente = await (_db.select(_db.users)..limit(1)).getSingleOrNull();
    if (existente != null) return existente.id;
    return _db.into(_db.users).insert(
          UsersCompanion.insert(
            nome: 'Jogador',
            classe: PlayerClass.guerreiro,
            titulo: const Value(tituloPadrao),
            rankDesde: Value(_agora()),
            criadoEm: Value(_agora()),
          ),
        );
  }

  UserProfile _toProfile(User row) {
    return UserProfile(
      id: row.id,
      nome: row.nome,
      avatar: row.avatar,
      classe: row.classe,
      titulo: row.titulo,
      tema: row.tema,
      xp: row.xp,
      nivel: row.nivel,
      rank: row.rank,
      alturaCm: row.alturaCm,
      nascimento: row.nascimento,
      sexo: row.sexo,
      unidades:
          Units(peso: row.unidadePeso, comprimento: row.unidadeComprimento),
    );
  }
}

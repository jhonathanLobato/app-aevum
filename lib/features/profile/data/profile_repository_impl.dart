import 'package:drift/drift.dart';

import '../../../database/app_database.dart';
import '../domain/app_theme.dart';
import '../domain/level_curve.dart';
import '../domain/player_class.dart';
import '../domain/profile_repository.dart';
import '../domain/user_profile.dart';

class DriftProfileRepository implements ProfileRepository {
  DriftProfileRepository(this._db, {LevelCurve levelCurve = const LevelCurve()})
      : _levelCurve = levelCurve;

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
          rank: Value(rankParaNivel(infoNova.nivel)),
        ),
      );

      return XpGainResult(
        xpGanho: quantidade,
        nivelAnterior: infoAnterior.nivel,
        novoNivel: infoNova.nivel,
      );
    });
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
          UsersCompanion.insert(nome: 'Jogador', classe: PlayerClass.guerreiro),
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
    );
  }
}

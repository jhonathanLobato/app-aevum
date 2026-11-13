import 'package:drift/drift.dart';

import '../../../database/app_database.dart';
import '../domain/sport_activity.dart';
import '../domain/sport_activity_repository.dart';

/// Só conhece o [AppDatabase] — de propósito não recebe nenhum repositório
/// de XP/missões/conquistas: registrar atividade esportiva vale 0 XP.
class DriftSportActivityRepository implements SportActivityRepository {
  DriftSportActivityRepository(this._db);

  final AppDatabase _db;

  SimpleSelectStatement<$SportActivitiesTable, SportActivityRow> _ordenado() {
    return _db.select(_db.sportActivities)
      ..orderBy([
        (a) => OrderingTerm(expression: a.data, mode: OrderingMode.desc),
        (a) => OrderingTerm(expression: a.id, mode: OrderingMode.desc),
      ]);
  }

  @override
  Stream<List<SportActivity>> watchAll() {
    return _ordenado().watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Stream<List<SportActivity>> watchByType(SportType tipo, {int? limite}) {
    final query = _ordenado()..where((a) => a.tipo.equalsValue(tipo));
    if (limite != null) query.limit(limite);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Stream<SportActivity?> watchById(int id) {
    return (_db.select(_db.sportActivities)..where((a) => a.id.equals(id)))
        .watchSingleOrNull()
        .map((row) => row == null ? null : _toDomain(row));
  }

  @override
  Future<int> create(SportActivityInput input) {
    _validar(input);
    return _db.into(_db.sportActivities).insert(
          SportActivitiesCompanion.insert(
            tipo: input.tipo,
            data: _soDia(input.data),
            duracaoMinutos: input.duracaoMinutos,
            distanciaKm: Value(_distancia(input)),
            rounds: Value(_rounds(input)),
            observacoes: Value(_observacoes(input)),
          ),
        );
  }

  @override
  Future<void> update(int id, SportActivityInput input) async {
    _validar(input);
    await (_db.update(_db.sportActivities)..where((a) => a.id.equals(id)))
        .write(
      SportActivitiesCompanion(
        tipo: Value(input.tipo),
        data: Value(_soDia(input.data)),
        duracaoMinutos: Value(input.duracaoMinutos),
        distanciaKm: Value(_distancia(input)),
        rounds: Value(_rounds(input)),
        observacoes: Value(_observacoes(input)),
      ),
    );
  }

  @override
  Future<void> delete(int id) async {
    await (_db.delete(_db.sportActivities)..where((a) => a.id.equals(id))).go();
  }

  void _validar(SportActivityInput input) {
    final erros = input.validar();
    if (erros.isNotEmpty) throw SportActivityValidationException(erros);
  }

  /// Campos que não fazem sentido pra modalidade nunca são gravados.
  double? _distancia(SportActivityInput input) =>
      input.tipo.usaDistancia ? input.distanciaKm : null;

  int? _rounds(SportActivityInput input) =>
      input.tipo.usaRounds ? input.rounds : null;

  String? _observacoes(SportActivityInput input) {
    final texto = input.observacoes?.trim();
    return (texto == null || texto.isEmpty) ? null : texto;
  }

  DateTime _soDia(DateTime data) => DateTime(data.year, data.month, data.day);

  SportActivity _toDomain(SportActivityRow row) {
    return SportActivity(
      id: row.id,
      tipo: row.tipo,
      data: row.data,
      duracaoMinutos: row.duracaoMinutos,
      distanciaKm: row.distanciaKm,
      rounds: row.rounds,
      observacoes: row.observacoes,
      criadoEm: row.criadoEm,
    );
  }
}

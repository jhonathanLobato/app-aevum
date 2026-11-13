import 'package:drift/drift.dart';

import '../../../database/app_database.dart';
import '../../daily/domain/daily_values.dart';
import '../../profile/data/profile_repository_impl.dart';
import '../../profile/domain/profile_repository.dart';
import '../domain/sport_activity.dart';
import '../domain/sport_activity_repository.dart';

/// Registrar atividade esportiva vale [ActivityXp.porRegistro] XP por registro
/// de [ActivityXp.minutosMinimos]+ min, no máximo [ActivityXp.maxPorSemana]
/// por semana (segunda a domingo). O XP concedido fica gravado em cada
/// registro; criar, editar (data/duração) ou excluir reconcilia a semana e
/// ajusta o XP do jogador.
class ActivityXp {
  const ActivityXp._();

  static const porRegistro = 30;
  static const maxPorSemana = 3;
  static const minutosMinimos = 30;
}

class DriftSportActivityRepository implements SportActivityRepository {
  DriftSportActivityRepository(this._db, {ProfileRepository? perfil})
      : _perfil = perfil ?? DriftProfileRepository(_db);

  final AppDatabase _db;
  final ProfileRepository _perfil;

  /// Reconcilia o XP das [semanas] (segundas-feiras): os 3 primeiros
  /// registros elegíveis de cada semana valem 30 XP, o resto 0. Soma/tira a
  /// diferença do XP do jogador. [deltaExtra] é o XP de um registro excluído.
  Future<void> _reconciliar(Set<DateTime> semanas, {int deltaExtra = 0}) async {
    var delta = deltaExtra;
    for (final inicio in semanas) {
      final linhas = await (_db.select(_db.sportActivities)
            ..where((a) =>
                a.data.isBiggerOrEqualValue(inicio) &
                a.data.isSmallerThanValue(somarDias(inicio, 7)))
            ..orderBy([
              (a) => OrderingTerm(expression: a.data),
              (a) => OrderingTerm(expression: a.id),
            ]))
          .get();
      var concedidos = 0;
      for (final l in linhas) {
        final elegivel = l.duracaoMinutos >= ActivityXp.minutosMinimos &&
            concedidos < ActivityXp.maxPorSemana;
        if (elegivel) concedidos++;
        final desejado = elegivel ? ActivityXp.porRegistro : 0;
        if (l.xpConcedido != desejado) {
          await (_db.update(_db.sportActivities)
                ..where((a) => a.id.equals(l.id)))
              .write(SportActivitiesCompanion(xpConcedido: Value(desejado)));
          delta += desejado - l.xpConcedido;
        }
      }
    }
    if (delta > 0) {
      await _perfil.addXp(delta);
    } else if (delta < 0) {
      await _perfil.removeXp(-delta, respeitarPisoDoNivel: false);
    }
  }

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
    return _db.transaction(() async {
      final id = await _db.into(_db.sportActivities).insert(
            SportActivitiesCompanion.insert(
              tipo: input.tipo,
              data: _soDia(input.data),
              duracaoMinutos: input.duracaoMinutos,
              distanciaKm: Value(_distancia(input)),
              rounds: Value(_rounds(input)),
              observacoes: Value(_observacoes(input)),
            ),
          );
      await _reconciliar({inicioDaSemana(input.data)});
      return id;
    });
  }

  @override
  Future<void> update(int id, SportActivityInput input) async {
    _validar(input);
    await _db.transaction(() async {
      final antigo = await (_db.select(_db.sportActivities)
            ..where((a) => a.id.equals(id)))
          .getSingleOrNull();
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
      await _reconciliar({
        inicioDaSemana(input.data),
        if (antigo != null) inicioDaSemana(antigo.data),
      });
    });
  }

  @override
  Future<void> delete(int id) async {
    await _db.transaction(() async {
      final antigo = await (_db.select(_db.sportActivities)
            ..where((a) => a.id.equals(id)))
          .getSingleOrNull();
      if (antigo == null) return;
      await (_db.delete(_db.sportActivities)..where((a) => a.id.equals(id)))
          .go();
      await _reconciliar({inicioDaSemana(antigo.data)},
          deltaExtra: -antigo.xpConcedido);
    });
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

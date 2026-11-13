import 'package:drift/drift.dart';

import '../../../database/app_database.dart';
import '../domain/body.dart';

/// Registros corporais (peso, % de gordura, medidas). Valores em kg/cm.
class DriftBodyRepository {
  DriftBodyRepository(this._db);

  final AppDatabase _db;

  BodyRecord _toDomain(BodyRecordRow r) => BodyRecord(
        id: r.id,
        data: r.data,
        pesoKg: r.pesoKg,
        gorduraPct: r.gorduraPct,
        bracoCm: r.bracoCm,
        peitoCm: r.peitoCm,
        cinturaCm: r.cinturaCm,
        quadrilCm: r.quadrilCm,
        coxaCm: r.coxaCm,
        panturrilhaCm: r.panturrilhaCm,
      );

  BodyRecordsCompanion _toCompanion(BodyRecordInput i) => BodyRecordsCompanion(
        data: Value(DateTime(i.data.year, i.data.month, i.data.day)),
        pesoKg: Value(i.pesoKg),
        gorduraPct: Value(i.gorduraPct),
        bracoCm: Value(i.bracoCm),
        peitoCm: Value(i.peitoCm),
        cinturaCm: Value(i.cinturaCm),
        quadrilCm: Value(i.quadrilCm),
        coxaCm: Value(i.coxaCm),
        panturrilhaCm: Value(i.panturrilhaCm),
      );

  /// Todos os registros, do mais antigo ao mais recente.
  Stream<List<BodyRecord>> watchAll() {
    final q = _db.select(_db.bodyRecords)
      ..orderBy([
        (t) => OrderingTerm(expression: t.data),
        (t) => OrderingTerm(expression: t.id),
      ]);
    return q.watch().map((rows) => rows.map(_toDomain).toList());
  }

  Future<BodyRecord?> get(int id) async {
    final r = await (_db.select(_db.bodyRecords)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return r == null ? null : _toDomain(r);
  }

  /// Cria (id nulo) ou atualiza. Devolve `false` (sem gravar) se nenhum
  /// valor foi informado.
  Future<bool> salvar(BodyRecordInput input, {int? id}) async {
    if (!input.temValor) return false;
    if (id == null) {
      await _db.into(_db.bodyRecords).insert(_toCompanion(input));
    } else {
      await (_db.update(_db.bodyRecords)..where((t) => t.id.equals(id)))
          .write(_toCompanion(input));
    }
    return true;
  }

  Future<void> excluir(int id) =>
      (_db.delete(_db.bodyRecords)..where((t) => t.id.equals(id))).go();
}

import 'package:drift/drift.dart';

/// Observa [tabelas] e reexecuta [carregar] a cada escrita (e uma vez no
/// início). Reemite sempre que uma das tabelas é alterada, mesmo que o
/// resultado seja igual ao anterior.
extension ObservarTabelas on GeneratedDatabase {
  Stream<T> observar<T>(
    Iterable<TableInfo> tabelas,
    Future<T> Function() carregar,
  ) async* {
    yield await carregar();
    yield* tableUpdates(TableUpdateQuery.onAllTables(tabelas))
        .asyncMap((_) => carregar());
  }
}

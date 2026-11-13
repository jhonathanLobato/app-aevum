import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../activities/domain/sport_activity.dart';
import '../../activities/presentation/activity_providers.dart';
import '../domain/workout_session.dart';
import 'workout_session_providers.dart';

/// Um item da linha do tempo do histórico geral. Só compõe, na camada de
/// apresentação, os dados que já existem (treinos finalizados e registros
/// esportivos) — nada é copiado nem gravado em outro lugar.
sealed class HistoryEntry {
  const HistoryEntry();

  DateTime get data;
}

class WorkoutHistoryEntry extends HistoryEntry {
  const WorkoutHistoryEntry(this.sessao);

  final WorkoutSessionSummary sessao;

  @override
  DateTime get data => sessao.data;
}

class SportHistoryEntry extends HistoryEntry {
  const SportHistoryEntry(this.atividade);

  final SportActivity atividade;

  @override
  DateTime get data => atividade.data;
}

/// Registros de um mês/ano, do mais recente pro mais antigo.
class HistoryMonth {
  const HistoryMonth({
    required this.ano,
    required this.mes,
    required this.registros,
  });

  final int ano;
  final int mes;
  final List<HistoryEntry> registros;

  /// Chave estável do mês (usada pra lembrar o que está recolhido).
  String get chave => '$ano-${mes.toString().padLeft(2, '0')}';

  int get total => registros.length;
}

/// Junta musculação + atividades, mais recente primeiro.
List<HistoryEntry> montarLinhaDoTempo(
  List<WorkoutSessionSummary> treinos,
  List<SportActivity> atividades,
) {
  final entradas = <HistoryEntry>[
    for (final t in treinos) WorkoutHistoryEntry(t),
    for (final a in atividades) SportHistoryEntry(a),
  ];
  // `sort` do Dart não é estável; o desempate por tipo/id deixa a ordem
  // determinística entre registros do mesmo instante.
  entradas.sort((a, b) {
    final porData = b.data.compareTo(a.data);
    if (porData != 0) return porData;
    return _desempate(b).compareTo(_desempate(a));
  });
  return entradas;
}

int _desempate(HistoryEntry e) => switch (e) {
      WorkoutHistoryEntry(:final sessao) => sessao.id,
      SportHistoryEntry(:final atividade) => atividade.id,
    };

/// Agrupa uma lista já ordenada em meses (mais recente primeiro).
List<HistoryMonth> agruparPorMes(List<HistoryEntry> ordenadas) {
  final meses = <HistoryMonth>[];
  for (final entrada in ordenadas) {
    final d = entrada.data;
    if (meses.isEmpty ||
        meses.last.ano != d.year ||
        meses.last.mes != d.month) {
      meses.add(HistoryMonth(ano: d.year, mes: d.month, registros: []));
    }
    meses.last.registros.add(entrada);
  }
  return meses;
}

/// Histórico geral = musculação + atividades esportivas, agrupado por mês.
/// Reaproveita os dois providers que já existem (sem consulta nova ao banco).
final generalHistoryProvider = Provider<AsyncValue<List<HistoryMonth>>>((ref) {
  final treinos = ref.watch(workoutHistoryProvider);
  final atividades = ref.watch(allSportActivitiesProvider);

  if (treinos.hasError) {
    return AsyncValue.error(
        treinos.error!, treinos.stackTrace ?? StackTrace.empty);
  }
  if (atividades.hasError) {
    return AsyncValue.error(
        atividades.error!, atividades.stackTrace ?? StackTrace.empty);
  }
  final listaTreinos = treinos.valueOrNull;
  final listaAtividades = atividades.valueOrNull;
  if (listaTreinos == null || listaAtividades == null) {
    return const AsyncValue.loading();
  }
  return AsyncValue.data(
    agruparPorMes(montarLinhaDoTempo(listaTreinos, listaAtividades)),
  );
});

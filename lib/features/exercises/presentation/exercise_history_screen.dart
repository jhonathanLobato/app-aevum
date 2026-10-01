import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../workouts/domain/workout_session.dart';
import '../../workouts/presentation/workout_session_providers.dart';

class ExerciseHistoryScreen extends ConsumerWidget {
  const ExerciseHistoryScreen({
    required this.exerciseId,
    required this.exerciseNome,
    super.key,
  });

  final int exerciseId;
  final String exerciseNome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(exerciseHistoryProvider(exerciseId));

    return Scaffold(
      appBar: AppBar(title: Text(exerciseNome)),
      body: historyAsync.when(
        data: (series) {
          if (series.isEmpty) {
            return const Center(
              child:
                  Text('Nenhuma série registrada para este exercício ainda.'),
            );
          }
          return ListView.builder(
            itemCount: series.length,
            itemBuilder: (context, index) {
              final serie = series[index];
              final anterior = index > 0 ? series[index - 1] : null;

              return ListTile(
                leading: _buildTendencia(context, serie, anterior),
                title: Text('${serie.repeticoes} × ${serie.carga}kg'),
                subtitle: Text(_formatarData(serie.data)),
                trailing: Text('${serie.volume.toStringAsFixed(0)}kg vol.'),
              );
            },
          );
        },
        error: (error, stackTrace) => Center(child: Text('Erro: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget? _buildTendencia(
    BuildContext context,
    SetEntryRecord atual,
    SetEntryRecord? anterior,
  ) {
    if (anterior == null) return null;
    if (atual.carga > anterior.carga) {
      return const Icon(Icons.trending_up, color: Colors.green);
    }
    if (atual.carga < anterior.carga) {
      return const Icon(Icons.trending_down, color: Colors.red);
    }
    return const Icon(Icons.trending_flat);
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/${data.year}';
  }
}

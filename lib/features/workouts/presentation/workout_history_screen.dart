import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'workout_session_providers.dart';

class WorkoutHistoryScreen extends ConsumerWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(workoutHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de treinos')),
      body: historyAsync.when(
        data: (sessoes) {
          if (sessoes.isEmpty) {
            return const Center(child: Text('Nenhum treino finalizado ainda.'));
          }
          return ListView.builder(
            itemCount: sessoes.length,
            itemBuilder: (context, index) {
              final sessao = sessoes[index];
              return ListTile(
                title: Text(sessao.nome),
                subtitle: Text(
                  '${_formatarData(sessao.data)} · ${sessao.totalSeries} séries · '
                  '${sessao.volumeTotal.toStringAsFixed(0)}kg de volume',
                ),
                trailing: sessao.duracaoSegundos == null
                    ? null
                    : Text(_formatarDuracao(sessao.duracaoSegundos!)),
                onTap: () => context.push('/sessions/${sessao.id}'),
              );
            },
          );
        },
        error: (error, stackTrace) => Center(child: Text('Erro: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  String _formatarDuracao(int segundosTotais) {
    final minutos = (segundosTotais ~/ 60).toString().padLeft(2, '0');
    final segundos = (segundosTotais % 60).toString().padLeft(2, '0');
    return '$minutos:$segundos';
  }
}

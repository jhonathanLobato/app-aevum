import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/statistics.dart';
import 'statistics_providers.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final globalAsync = ref.watch(globalStatisticsProvider);
    final porExercicioAsync = ref.watch(exerciseStatisticsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Estatísticas')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          globalAsync.when(
            data: (stats) => _GlobalStatsCard(stats: stats),
            error: (error, stackTrace) => Text('Erro: $error'),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
          const SizedBox(height: 24),
          Text('Por exercício', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          porExercicioAsync.when(
            data: (lista) {
              if (lista.isEmpty) {
                return const Text('Nenhum exercício registrado ainda.');
              }
              return Column(
                children: [
                  for (final stats in lista) _ExerciseStatsCard(stats: stats),
                ],
              );
            },
            error: (error, stackTrace) => Text('Erro: $error'),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }
}

class _GlobalStatsCard extends StatelessWidget {
  const _GlobalStatsCard({required this.stats});

  final GlobalStatistics stats;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatRow('Treinos realizados', '${stats.treinosRealizados}'),
            _StatRow('Tempo total treinando',
                _formatarDuracao(stats.tempoTotalTreinando)),
            _StatRow('Exercícios realizados', '${stats.exerciciosRealizados}'),
            _StatRow('PRs', '${stats.totalPRs}'),
            _StatRow(
                'Volume total', '${stats.volumeTotal.toStringAsFixed(0)}kg'),
            _StatRow('XP acumulado', '${stats.xpAcumulado}'),
            _StatRow('Nível atual', '${stats.nivelAtual}'),
            _StatRow('Maior sequência', '${stats.maiorSequenciaDias} dias'),
          ],
        ),
      ),
    );
  }

  String _formatarDuracao(Duration d) {
    final horas = d.inHours;
    final minutos = d.inMinutes.remainder(60);
    return horas > 0 ? '${horas}h ${minutos}min' : '${minutos}min';
  }
}

class _ExerciseStatsCard extends StatelessWidget {
  const _ExerciseStatsCard({required this.stats});

  final ExerciseStatistics stats;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(stats.exerciseNome,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _StatRow('Maior carga', '${stats.maiorCarga}kg'),
            _StatRow('Maior repetição', '${stats.maiorRepeticao}'),
            _StatRow(
                'Maior volume', '${stats.maiorVolume.toStringAsFixed(0)}kg'),
            _StatRow('Treinos realizados', '${stats.treinosRealizados}'),
            _StatRow(
                'Primeiro registro', _formatarData(stats.primeiroRegistro)),
            _StatRow('Último registro', _formatarData(stats.ultimoRegistro)),
          ],
        ),
      ),
    );
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/${data.year}';
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow(this.label, this.valor);

  final String label;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

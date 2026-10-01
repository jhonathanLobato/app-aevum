import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/mission.dart';
import 'mission_providers.dart';

class MissionsScreen extends ConsumerWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionsAsync = ref.watch(activeMissionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Missões')),
      body: missionsAsync.when(
        data: (missoes) {
          if (missoes.isEmpty) {
            return const Center(child: Text('Nenhuma missão ativa agora.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: missoes.length,
            itemBuilder: (context, index) =>
                _MissionCard(missao: missoes[index]),
          );
        },
        error: (error, stackTrace) => Center(child: Text('Erro: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.missao});

  final Mission missao;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_rotuloTipo(missao.tipo).toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 4),
            Text(missao.nome, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(missao.descricao),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: missao.progressoFracao),
            const SizedBox(height: 4),
            Text('${missao.progresso} / ${missao.objetivo}'),
            const SizedBox(height: 8),
            Text('Recompensa: +${missao.recompensaXp} XP'),
          ],
        ),
      ),
    );
  }

  String _rotuloTipo(MissionType tipo) {
    switch (tipo) {
      case MissionType.diaria:
        return 'Missão diária';
      case MissionType.semanal:
        return 'Missão semanal';
      case MissionType.desafio:
        return 'Desafio';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/achievement.dart';
import 'achievement_providers.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Conquistas')),
      body: achievementsAsync.when(
        data: (conquistas) {
          return ListView.builder(
            itemCount: conquistas.length,
            itemBuilder: (context, index) {
              final conquista = conquistas[index];
              final desbloqueada =
                  conquista.status == AchievementStatus.desbloqueada;

              return ListTile(
                leading: Icon(
                  desbloqueada ? _iconeDe(conquista.icone) : Icons.lock_outline,
                  color: desbloqueada ? null : Theme.of(context).disabledColor,
                ),
                title: Text(conquista.nome),
                subtitle: Text(
                  desbloqueada
                      ? conquista.descricao
                      : '${conquista.descricao} (${conquista.requisito})',
                ),
                trailing: desbloqueada && conquista.dataDesbloqueio != null
                    ? Text(_formatarData(conquista.dataDesbloqueio!))
                    : null,
              );
            },
          );
        },
        error: (error, stackTrace) => Center(child: Text('Erro: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  IconData _iconeDe(String nome) {
    switch (nome) {
      case 'flag':
        return Icons.flag;
      case 'trending_up':
        return Icons.trending_up;
      case 'military_tech':
        return Icons.military_tech;
      case 'bolt':
        return Icons.bolt;
      default:
        return Icons.emoji_events;
    }
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/${data.year}';
  }
}

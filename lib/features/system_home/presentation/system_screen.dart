import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../profile/domain/level_curve.dart';
import '../../profile/domain/player_class.dart';
import '../../profile/presentation/profile_providers.dart';

class SystemScreen extends ConsumerWidget {
  const SystemScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'SISTEMA ONLINE',
              style: TextStyle(letterSpacing: 4, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            userAsync.when(
              data: (user) {
                if (user == null) {
                  return const Text('Nível 1 · Rank F · 0 XP');
                }
                final info = const LevelCurve().calcularNivel(user.xp);
                return Column(
                  children: [
                    Text(
                      '${user.nome} · ${nomeDaClasse(user.classe)}'
                      '${user.titulo != null ? ' · ${user.titulo}' : ''}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                        'Nível ${user.nivel} · Rank ${user.rank} · ${user.xp} XP'),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 200,
                      child: LinearProgressIndicator(value: info.progresso),
                    ),
                  ],
                );
              },
              error: (error, stackTrace) => const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => context.push('/exercises'),
              child: const Text('Gerenciar exercícios'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.push('/workouts'),
              child: const Text('Gerenciar treinos'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.push('/history'),
              child: const Text('Ver histórico'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.push('/missions'),
              child: const Text('Ver missões'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.push('/achievements'),
              child: const Text('Ver conquistas'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.push('/statistics'),
              child: const Text('Ver estatísticas'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.push('/profile'),
              child: const Text('Editar perfil'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'workout_name_dialog.dart';
import 'workout_template_providers.dart';

class WorkoutsScreen extends ConsumerWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(workoutTemplatesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Treinos')),
      body: templatesAsync.when(
        data: (templates) {
          if (templates.isEmpty) {
            return const Center(child: Text('Nenhum treino cadastrado ainda.'));
          }
          return ListView.builder(
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              final subtitulo = template.exercicios.isEmpty
                  ? 'Sem exercícios'
                  : template.exercicios.map((e) => e.exerciseNome).join(', ');

              return ListTile(
                title: Text(template.nome),
                subtitle: Text(subtitulo),
                onTap: () => context.push('/workouts/${template.id}'),
              );
            },
          );
        },
        error: (error, stackTrace) => Center(child: Text('Erro: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final nome = await showWorkoutNameDialog(context);
          if (nome == null) return;
          final id =
              await ref.read(workoutTemplateRepositoryProvider).create(nome);
          if (context.mounted) context.push('/workouts/$id');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

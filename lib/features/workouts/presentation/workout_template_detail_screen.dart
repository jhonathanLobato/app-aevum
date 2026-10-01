import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/workout_template.dart';
import 'exercise_picker_sheet.dart';
import 'workout_name_dialog.dart';
import 'workout_session_providers.dart';
import 'workout_template_providers.dart';

class WorkoutTemplateDetailScreen extends ConsumerWidget {
  const WorkoutTemplateDetailScreen({required this.templateId, super.key});

  final int templateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(workoutTemplatesProvider);
    final repo = ref.read(workoutTemplateRepositoryProvider);

    return templatesAsync.when(
      data: (templates) {
        final match = _findTemplate(templates, templateId);
        if (match == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Treino')),
            body: const Center(child: Text('Este treino não existe mais.')),
          );
        }
        final template = match;

        return Scaffold(
          appBar: AppBar(
            title: Text(template.nome),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  final nome = await showWorkoutNameDialog(
                    context,
                    title: 'Renomear treino',
                    nomeInicial: template.nome,
                  );
                  if (nome != null) await repo.rename(template.id, nome);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  await repo.delete(template.id);
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
            ],
          ),
          body: template.exercicios.isEmpty
              ? const Center(child: Text('Adicione exercícios a este treino.'))
              : ReorderableListView.builder(
                  itemCount: template.exercicios.length,
                  itemBuilder: (context, index) {
                    final item = template.exercicios[index];
                    return ListTile(
                      key: ValueKey(item.templateExerciseId),
                      leading: ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_handle),
                      ),
                      title: Text(item.exerciseNome),
                      subtitle: Text(item.grupoMuscular),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () =>
                            repo.removeExercise(item.templateExerciseId),
                      ),
                    );
                  },
                  onReorderItem: (oldIndex, newIndex) {
                    final ids = template.exercicios
                        .map((e) => e.templateExerciseId)
                        .toList();
                    final movedId = ids.removeAt(oldIndex);
                    ids.insert(newIndex, movedId);
                    repo.reorderExercises(template.id, ids);
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final exercise = await showExercisePickerSheet(context, ref);
              if (exercise != null) {
                await repo.addExercise(template.id, exercise.id);
              }
            },
            child: const Icon(Icons.add),
          ),
          bottomNavigationBar: template.exercicios.isEmpty
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Iniciar treino'),
                      onPressed: () async {
                        final sessionId = await ref
                            .read(workoutSessionRepositoryProvider)
                            .start(
                                templateId: template.id, nome: template.nome);
                        if (context.mounted) {
                          context.push('/sessions/$sessionId');
                        }
                      },
                    ),
                  ),
                ),
        );
      },
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: const Text('Treino')),
        body: Center(child: Text('Erro: $error')),
      ),
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Treino')),
        body: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  WorkoutTemplate? _findTemplate(List<WorkoutTemplate> templates, int id) {
    for (final template in templates) {
      if (template.id == id) return template;
    }
    return null;
  }
}

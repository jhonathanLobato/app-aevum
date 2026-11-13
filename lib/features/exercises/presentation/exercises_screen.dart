import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/system_back_button.dart';
import '../../../design_system/system_button.dart';
import '../../../design_system/system_choice_dialog.dart';
import '../../../design_system/system_colors.dart';
import '../../../design_system/system_confirm_dialog.dart';
import '../../../design_system/system_empty_state.dart';
import '../../../design_system/system_entrance.dart';
import '../../../design_system/system_motion.dart';
import '../../../design_system/system_panel.dart';
import '../../../design_system/system_scaffold.dart';
import '../../../design_system/system_spacing.dart';
import '../../../design_system/system_text_styles.dart';
import '../domain/exercise.dart';
import '../domain/exercise_repository.dart';
import 'exercise_form_sheet.dart';
import 'exercise_providers.dart';

/// Biblioteca de exercícios (CRUD), redesenhada na Fase 11 com a linguagem
/// visual do Aevum — mesmas ações de antes (criar, editar ao tocar, ver
/// histórico, excluir), só sem `AppBar`/`ListTile`/FAB Material.
class ExercisesScreen extends ConsumerWidget {
  const ExercisesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(exercisesProvider);

    return SystemScaffold(
      title: 'EXERCÍCIOS',
      subtitle: 'BIBLIOTECA DE EXERCÍCIOS',
      leading: const SystemBackButton(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SystemButton(
            label: 'Novo exercício',
            variant: SystemButtonVariant.action,
            icon: const Icon(Icons.add,
                size: 16, color: SystemPalette.foreground),
            onPressed: () => showExerciseFormSheet(context),
          ),
          const SizedBox(height: SystemSpacing.lg),
          exercisesAsync.when(
            data: (exercises) {
              if (exercises.isEmpty) {
                return const SystemEmptyState(
                  icon: Icons.fitness_center_outlined,
                  message: 'NENHUM EXERCÍCIO CADASTRADO',
                  detail: 'Cadastre seu primeiro exercício para começar.',
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < exercises.length; i++) ...[
                    if (i > 0) const SizedBox(height: SystemSpacing.md),
                    SystemEntrance(
                      key: ValueKey('exercicio-${exercises[i].id}'),
                      delay: SystemDurations.staggerStep * (i < 6 ? i : 6),
                      child: _ExerciseCard(exercise: exercises[i]),
                    ),
                  ],
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: SystemSpacing.lg),
                child: CircularProgressIndicator(color: SystemPalette.primary),
              ),
            ),
            error: (error, stackTrace) => const SystemEmptyState(
              icon: Icons.error_outline,
              message: 'ERRO AO CARREGAR EXERCÍCIOS',
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends ConsumerWidget {
  const _ExerciseCard({required this.exercise});

  final Exercise exercise;

  Future<void> _excluir(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(exerciseRepositoryProvider);

    if (await repo.isInUse(exercise.id)) {
      if (context.mounted) await _avisarEmUso(context);
      return;
    }
    if (!context.mounted) return;

    final confirmar = await showSystemConfirmDialog(
      context,
      titulo: 'Excluir exercício?',
      mensagem:
          'Isso remove "${exercise.nome}" da biblioteca. Esta ação não pode ser desfeita.',
      confirmar: 'Excluir',
      icone: Icons.delete_outline,
      destrutivo: true,
    );
    if (!confirmar) return;

    try {
      await repo.delete(exercise.id);
    } on ExerciseInUseException {
      if (context.mounted) await _avisarEmUso(context);
    }
  }

  Future<void> _avisarEmUso(BuildContext context) {
    return showSystemChoiceDialog<bool>(
      context,
      titulo: 'Exercício em uso',
      mensagem:
          '"${exercise.nome}" não pode ser excluído porque já faz parte de treinos ou tem séries e recordes registrados. Remova-o dos treinos antes, ou mantenha-o na biblioteca para preservar seu histórico.',
      icone: Icons.lock_outline,
      opcoes: const [
        SystemChoice(
            label: 'Entendi', valor: true, variant: SystemButtonVariant.action),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SystemPanel(
      padding: const EdgeInsets.fromLTRB(
        SystemSpacing.lg,
        SystemSpacing.md,
        SystemSpacing.sm,
        SystemSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => showExerciseFormSheet(context, exercise: exercise),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.nome.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: SystemTextStyles.displaySmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    exercise.grupoMuscular.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SystemTextStyles.label.copyWith(
                      fontSize: 9.6,
                      color: SystemPalette.violet,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.show_chart),
            color: SystemPalette.primary,
            tooltip: 'Histórico',
            onPressed: () => context.push(
              '/exercises/${exercise.id}/history',
              extra: exercise.nome,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: SystemPalette.destructive,
            tooltip: 'Excluir exercício',
            onPressed: () => _excluir(context, ref),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/system_button.dart';
import '../../../design_system/system_colors.dart';
import '../../../design_system/system_empty_state.dart';
import '../../../design_system/system_spacing.dart';
import '../../../design_system/system_text_styles.dart';
import '../../exercises/domain/exercise.dart';
import '../../exercises/presentation/exercise_providers.dart';

/// Selecionar um exercício real já cadastrado pra adicionar ao treino —
/// mesmo fluxo de antes (escolhe um [Exercise] existente ou vai cadastrar
/// um novo em `/exercises`), só com a estética do Aevum em vez de um
/// `ListTile`/`BottomSheet` Material padrão.
Future<Exercise?> showExercisePickerSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<Exercise>(
    context: context,
    isScrollControlled: true,
    // Sem `useSafeArea`/altura máxima, uma lista longa fazia o painel
    // crescer até a tela inteira e o conteúdo vazava por baixo da barra de
    // status.
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.85,
    ),
    builder: (context) => const _ExercisePickerSheet(),
  );
}

class _ExercisePickerSheet extends ConsumerWidget {
  const _ExercisePickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(exercisesProvider);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: SystemPalette.background,
        border: Border(
          top: BorderSide(
            color:
                SystemPalette.primary.withValues(alpha: SystemOpacities.border),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            SystemSpacing.xl,
            SystemSpacing.lg,
            SystemSpacing.xl,
            SystemSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(width: 2, height: 12, color: SystemPalette.primary),
                  const SizedBox(width: SystemSpacing.sm),
                  const Text('ADICIONAR EXERCÍCIO',
                      style: SystemTextStyles.label),
                ],
              ),
              const SizedBox(height: SystemSpacing.lg),
              Flexible(
                child: exercisesAsync.when(
                  data: (exercises) {
                    if (exercises.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: SystemSpacing.md),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SystemEmptyState(
                              icon: Icons.fitness_center_outlined,
                              message: 'NENHUM EXERCÍCIO CADASTRADO',
                            ),
                            const SizedBox(height: SystemSpacing.md),
                            SystemButton(
                              label: 'Cadastrar exercícios',
                              onPressed: () {
                                Navigator.of(context).pop();
                                context.push('/exercises');
                              },
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: exercises.length,
                      itemBuilder: (context, index) {
                        final exercise = exercises[index];
                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: SystemSpacing.sm),
                          child: _ExerciseOption(
                            exercise: exercise,
                            onTap: () => Navigator.of(context).pop(exercise),
                          ),
                        );
                      },
                    );
                  },
                  error: (error, stackTrace) => const SystemEmptyState(
                    icon: Icons.error_outline,
                    message: 'ERRO AO CARREGAR EXERCÍCIOS',
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: SystemSpacing.lg),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: SystemPalette.primary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseOption extends StatelessWidget {
  const _ExerciseOption({required this.exercise, required this.onTap});

  final Exercise exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: SystemSpacing.md, vertical: SystemSpacing.sm),
        decoration: BoxDecoration(
          color: SystemPalette.surface2
              .withValues(alpha: SystemOpacities.surface2),
          border: Border.all(
            color:
                SystemPalette.primary.withValues(alpha: SystemOpacities.border),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.nome.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SystemTextStyles.displaySmall.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    exercise.grupoMuscular.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SystemTextStyles.label.copyWith(fontSize: 8.8),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: SystemPalette.mutedForeground),
          ],
        ),
      ),
    );
  }
}

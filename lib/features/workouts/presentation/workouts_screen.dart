import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/system_button.dart';
import '../../../design_system/system_colors.dart';
import '../../../design_system/system_empty_state.dart';
import '../../../design_system/system_entrance.dart';
import '../../../design_system/system_motion.dart';
import '../../../design_system/system_panel.dart';
import '../../../design_system/system_scaffold.dart';
import '../../../design_system/system_spacing.dart';
import '../../../design_system/system_text_styles.dart';
import '../domain/workout_template.dart';
import 'widgets/active_workout_card.dart';
import 'workout_template_providers.dart';

/// Lista de treinos ("Protocolos de Treinamento"), redesenhada na Fase 11 a
/// partir da tela Material simples original — o Lovable não tem uma
/// referência pronta pra esta tela, então a estética reaproveita só os
/// componentes/tokens já consolidados no resto do Aevum (nenhum design
/// novo foi inventado).
class WorkoutsScreen extends ConsumerWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(workoutTemplatesProvider);

    return SystemScaffold(
      title: 'TREINOS',
      subtitle: 'PROTOCOLOS DE TREINAMENTO',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ActiveWorkoutCard(),
          SystemButton(
            label: 'Novo treino',
            variant: SystemButtonVariant.action,
            icon: const Icon(Icons.add,
                size: 16, color: SystemPalette.foreground),
            onPressed: () => context.push('/workouts/new'),
          ),
          const SizedBox(height: SystemSpacing.sm),
          SystemButton(
            label: 'Exercícios',
            variant: SystemButtonVariant.ghost,
            icon: const Icon(Icons.list_alt_rounded,
                size: 16, color: SystemPalette.foreground),
            onPressed: () => context.push('/exercises'),
          ),
          const SizedBox(height: SystemSpacing.lg),
          templatesAsync.when(
            data: (templates) {
              if (templates.isEmpty) {
                return const SystemEmptyState(
                  icon: Icons.fitness_center_outlined,
                  message: 'NENHUM TREINO CADASTRADO',
                  detail: 'Crie seu primeiro treino para começar.',
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < templates.length; i++) ...[
                    if (i > 0) const SizedBox(height: SystemSpacing.md),
                    SystemEntrance(
                      delay: SystemDurations.staggerStep * i,
                      child: _WorkoutCard(template: templates[i]),
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
              message: 'ERRO AO CARREGAR TREINOS',
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({required this.template});

  final WorkoutTemplate template;

  @override
  Widget build(BuildContext context) {
    final gruposMusculares = {
      for (final e in template.exercicios) e.grupoMuscular,
    }.toList();

    return SystemPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            template.nome.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SystemTextStyles.displayMedium,
          ),
          if (gruposMusculares.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              gruposMusculares.join(' + ').toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SystemTextStyles.label.copyWith(
                fontSize: 9.6,
                color: SystemPalette.violet,
              ),
            ),
          ],
          const SizedBox(height: SystemSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${template.exercicios.length} EXERCÍCIOS',
                style: SystemTextStyles.label.copyWith(
                  fontSize: 8.8,
                  color: SystemPalette.primary,
                ),
              ),
              SystemButton(
                label: 'Abrir',
                icon: const Icon(Icons.chevron_right,
                    size: 16, color: SystemPalette.foreground),
                onPressed: () => context.push('/workouts/${template.id}'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

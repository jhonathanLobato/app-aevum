import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/system_colors.dart';
import '../../../design_system/system_empty_state.dart';
import '../../../design_system/system_entrance.dart';
import '../../../design_system/system_motion.dart';
import '../../../design_system/system_panel.dart';
import '../../../design_system/system_scaffold.dart';
import '../../../design_system/system_spacing.dart';
import '../../../design_system/system_stat_box.dart';
import '../../../design_system/system_text_styles.dart';
import '../domain/statistics.dart';
import 'statistics_providers.dart';
import 'widgets/player_attributes_panel.dart';
import 'widgets/status_identity_panel.dart';

/// Tela STATUS ("ficha de evolução"): identidade real (nome/classe/rank/
/// nível/XP), os 3 atributos derivados do MVP, as estatísticas globais e o
/// detalhe por exercício. É a aba STATUS (rota `/statistics`).
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final globalAsync = ref.watch(globalStatisticsProvider);
    final porExercicioAsync = ref.watch(exerciseStatisticsProvider);

    return SystemScaffold(
      title: 'STATUS',
      subtitle: 'FICHA DO CAÇADOR',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SystemEntrance(child: StatusIdentityPanel()),
          const SizedBox(height: SystemSpacing.lg),
          SystemEntrance(
            delay: SystemDurations.staggerStep,
            child: globalAsync.when(
              data: (stats) => _GlobalStatsGrid(stats: stats),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: SystemSpacing.lg),
                  child:
                      CircularProgressIndicator(color: SystemPalette.primary),
                ),
              ),
              error: (error, stackTrace) => const SystemEmptyState(
                icon: Icons.error_outline,
                message: 'ERRO AO CARREGAR ESTATÍSTICAS',
              ),
            ),
          ),
          const SizedBox(height: SystemSpacing.lg),
          SystemEntrance(
            delay: SystemDurations.staggerStep * 2,
            child: const PlayerAttributesPanel(),
          ),
          const SizedBox(height: SystemSpacing.lg),
          SystemEntrance(
            delay: SystemDurations.staggerStep * 3,
            child: SystemPanel(
              title: 'DETALHES POR EXERCÍCIO',
              child: porExercicioAsync.when(
                data: (lista) {
                  if (lista.isEmpty) {
                    return const SystemEmptyState(
                      message: 'NENHUM EXERCÍCIO REGISTRADO AINDA',
                    );
                  }
                  return Column(
                    children: [
                      for (var i = 0; i < lista.length; i++) ...[
                        if (i > 0) const SizedBox(height: SystemSpacing.md),
                        _ExerciseStatsRow(stats: lista[i]),
                      ],
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: SystemSpacing.md),
                    child:
                        CircularProgressIndicator(color: SystemPalette.primary),
                  ),
                ),
                error: (error, stackTrace) => const SystemEmptyState(
                  icon: Icons.error_outline,
                  message: 'ERRO AO CARREGAR DETALHES',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlobalStatsGrid extends StatelessWidget {
  const _GlobalStatsGrid({required this.stats});

  final GlobalStatistics stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SystemStatBox(
                label: 'TREINOS',
                value: '${stats.treinosRealizados}',
                icon: Icons.fitness_center,
              ),
            ),
            const SizedBox(width: SystemSpacing.sm),
            Expanded(
              child: SystemStatBox(
                label: 'HORAS',
                value: _formatarDuracao(stats.tempoTotalTreinando),
                icon: Icons.schedule,
              ),
            ),
          ],
        ),
        const SizedBox(height: SystemSpacing.sm),
        Row(
          children: [
            Expanded(
              child: SystemStatBox(
                label: 'PRs',
                value: '${stats.totalPRs}',
                icon: Icons.emoji_events_outlined,
                iconColor: SystemPalette.gold,
              ),
            ),
            const SizedBox(width: SystemSpacing.sm),
            Expanded(
              child: SystemStatBox(
                label: 'VOLUME',
                value: '${stats.volumeTotal.toStringAsFixed(0)} KG',
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatarDuracao(Duration d) {
    final horas = d.inHours;
    final minutos = d.inMinutes.remainder(60);
    return horas > 0 ? '${horas}h${minutos}min' : '${minutos}min';
  }
}

class _ExerciseStatsRow extends StatelessWidget {
  const _ExerciseStatsRow({required this.stats});

  final ExerciseStatistics stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: SystemSpacing.md, vertical: SystemSpacing.sm),
      decoration: BoxDecoration(
        color:
            SystemPalette.surface2.withValues(alpha: SystemOpacities.surface2),
        border: Border(
          left: BorderSide(
              color: SystemPalette.primary.withValues(alpha: 0.5), width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stats.exerciseNome,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SystemTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            '${stats.maiorCarga.toStringAsFixed(1)} KG · ${stats.maiorRepeticao} reps · '
            '${stats.treinosRealizados} treinos',
            style: SystemTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../profile/presentation/profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/system_back_button.dart';
import '../../../design_system/system_colors.dart';
import '../../../design_system/system_empty_state.dart';
import '../../../design_system/system_panel.dart';
import '../../../design_system/system_scaffold.dart';
import '../../../design_system/system_spacing.dart';
import '../../../design_system/system_text_styles.dart';
import '../../workouts/domain/workout_session.dart';
import '../../workouts/presentation/workout_session_providers.dart';

/// Histórico de séries de um exercício, com indicador de tendência de carga.
class ExerciseHistoryScreen extends ConsumerWidget {
  const ExerciseHistoryScreen({
    required this.exerciseId,
    required this.exerciseNome,
    super.key,
  });

  final int exerciseId;
  final String exerciseNome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(exerciseHistoryProvider(exerciseId));

    return SystemScaffold(
      title: exerciseNome.toUpperCase(),
      subtitle: 'HISTÓRICO DO EXERCÍCIO',
      leading: const SystemBackButton(),
      body: historyAsync.when(
        data: (series) {
          if (series.isEmpty) {
            return const SystemEmptyState(
              icon: Icons.show_chart,
              message: 'NENHUMA SÉRIE REGISTRADA',
              detail: 'Nenhuma série registrada para este exercício ainda.',
            );
          }
          return SystemPanel(
            title: '${series.length} SÉRIES REGISTRADAS',
            child: Column(
              children: [
                for (var i = 0; i < series.length; i++) ...[
                  if (i > 0) const SizedBox(height: SystemSpacing.sm),
                  _SerieRow(
                    serie: series[i],
                    anterior: i > 0 ? series[i - 1] : null,
                  ),
                ],
              ],
            ),
          );
        },
        error: (error, stackTrace) => const SystemEmptyState(
          icon: Icons.error_outline,
          message: 'ERRO AO CARREGAR HISTÓRICO',
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: SystemPalette.primary),
        ),
      ),
    );
  }
}

class _SerieRow extends ConsumerWidget {
  const _SerieRow({required this.serie, required this.anterior});

  final SetEntryRecord serie;
  final SetEntryRecord? anterior;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(unitsProvider);
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
      child: Row(
        children: [
          SizedBox(width: 24, child: _tendencia()),
          const SizedBox(width: SystemSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${serie.repeticoes} × ${units.formatarPeso(serie.carga)}',
                  style: SystemTextStyles.displaySmall.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatarData(serie.data),
                  style: SystemTextStyles.label.copyWith(fontSize: 8.8),
                ),
              ],
            ),
          ),
          Text(
            '${units.formatarPeso(serie.volume, casas: 0)} vol.',
            style: SystemTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget? _tendencia() {
    final anterior = this.anterior;
    if (anterior == null) return null;
    if (serie.carga > anterior.carga) {
      return const Icon(Icons.trending_up,
          size: 20, color: SystemPalette.success);
    }
    if (serie.carga < anterior.carga) {
      return const Icon(Icons.trending_down,
          size: 20, color: SystemPalette.destructive);
    }
    return const Icon(Icons.trending_flat,
        size: 20, color: SystemPalette.mutedForeground);
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/${data.year}';
  }
}

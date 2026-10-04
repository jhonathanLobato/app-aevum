import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/system_back_button.dart';
import '../../../design_system/system_colors.dart';
import '../../../design_system/system_empty_state.dart';
import '../../../design_system/system_entrance.dart';
import '../../../design_system/system_motion.dart';
import '../../../design_system/system_panel.dart';
import '../../../design_system/system_scaffold.dart';
import '../../../design_system/system_spacing.dart';
import '../../../design_system/system_stat_box.dart';
import '../../../design_system/system_text_styles.dart';
import '../domain/workout_session.dart';
import 'workout_session_providers.dart';

/// Histórico de treinos finalizados, redesenhado na Fase 11 (antes
/// `AppBar` + `ListTile` Material).
class WorkoutHistoryScreen extends ConsumerWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(workoutHistoryProvider);

    return SystemScaffold(
      title: 'HISTÓRICO',
      subtitle: 'TREINOS FINALIZADOS',
      leading: const SystemBackButton(),
      body: historyAsync.when(
        data: (sessoes) {
          if (sessoes.isEmpty) {
            return const SystemEmptyState(
              icon: Icons.history,
              message: 'NENHUM TREINO FINALIZADO',
              detail: 'Nenhum treino finalizado ainda.',
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < sessoes.length; i++) ...[
                if (i > 0) const SizedBox(height: SystemSpacing.md),
                SystemEntrance(
                  key: ValueKey('sessao-${sessoes[i].id}'),
                  delay: SystemDurations.staggerStep * (i < 6 ? i : 6),
                  child: _SessionCard(sessao: sessoes[i]),
                ),
              ],
            ],
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

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.sessao});

  final WorkoutSessionSummary sessao;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/sessions/${sessao.id}'),
      child: SystemPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    sessao.nome.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SystemTextStyles.displaySmall,
                  ),
                ),
                const Icon(Icons.chevron_right,
                    size: 18, color: SystemPalette.mutedForeground),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              _formatarData(sessao.data),
              style: SystemTextStyles.label.copyWith(
                fontSize: 9.6,
                color: SystemPalette.violet,
              ),
            ),
            const SizedBox(height: SystemSpacing.md),
            Row(
              children: [
                Expanded(
                  child: SystemStatBox(
                    label: 'SÉRIES',
                    value: '${sessao.totalSeries}',
                  ),
                ),
                const SizedBox(width: SystemSpacing.sm),
                Expanded(
                  child: SystemStatBox(
                    label: 'VOLUME',
                    value: '${sessao.volumeTotal.toStringAsFixed(0)} KG',
                  ),
                ),
                const SizedBox(width: SystemSpacing.sm),
                Expanded(
                  child: SystemStatBox(
                    label: 'DURAÇÃO',
                    value: sessao.duracaoSegundos == null
                        ? '—'
                        : _formatarDuracao(sessao.duracaoSegundos!),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  String _formatarDuracao(int segundosTotais) {
    final minutos = (segundosTotais ~/ 60).toString().padLeft(2, '0');
    final segundos = (segundosTotais % 60).toString().padLeft(2, '0');
    return '$minutos:$segundos';
  }
}

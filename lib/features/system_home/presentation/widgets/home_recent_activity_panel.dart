import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/system_colors.dart';
import '../../../../design_system/system_empty_state.dart';
import '../../../../design_system/system_panel.dart';
import '../../../../design_system/system_spacing.dart';
import '../../../../design_system/system_text_styles.dart';
import '../../../workouts/domain/workout_session.dart';
import '../../../workouts/presentation/workout_session_providers.dart';

/// "PROGRESSO RECENTE", direto de `index.tsx` ("RECENT PROGRESS" no
/// Lovable) — mas sem copiar a lista mockada de lá. O Lovable mistura PR,
/// volume semanal e missão concluída numa lista fixa; o app ainda não tem
/// uma consulta que agregue "PRs recentes" entre exercícios (só por
/// exercício, via `exercisePersonalRecordsProvider(exerciseId)`), então em
/// vez de montar uma agregação cara/nova só pra preencher este card, uso
/// [workoutHistoryProvider] (treinos finalizados, mais recente primeiro) —
/// um indicador de evolução real e já disponível.
class HomeRecentActivityPanel extends ConsumerWidget {
  const HomeRecentActivityPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(workoutHistoryProvider);

    return historyAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return const SystemPanel(
            title: 'PROGRESSO RECENTE',
            child: SystemEmptyState(
              icon: Icons.trending_up,
              message: 'COMECE SUA EVOLUÇÃO',
              detail:
                  'Finalize seu primeiro treino para ver seu progresso aqui.',
            ),
          );
        }

        final recent = sessions.take(3).toList();
        return SystemPanel(
          title: 'PROGRESSO RECENTE',
          child: Column(
            children: [
              for (var i = 0; i < recent.length; i++) ...[
                if (i > 0) const SizedBox(height: SystemSpacing.sm),
                _RecentSessionRow(session: recent[i]),
              ],
            ],
          ),
        );
      },
      loading: () => const SystemPanel(
        title: 'PROGRESSO RECENTE',
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: SystemSpacing.md),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: SystemPalette.primary),
            ),
          ),
        ),
      ),
      error: (error, stackTrace) => const SystemPanel(
        title: 'PROGRESSO RECENTE',
        child: SystemEmptyState(
          icon: Icons.error_outline,
          message: 'ERRO AO CARREGAR PROGRESSO',
        ),
      ),
    );
  }
}

class _RecentSessionRow extends StatelessWidget {
  const _RecentSessionRow({required this.session});

  final WorkoutSessionSummary session;

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
      child: Row(
        children: [
          const Icon(Icons.fitness_center,
              size: 16, color: SystemPalette.primary),
          const SizedBox(width: SystemSpacing.sm),
          Expanded(
            child: Text(
              session.nome,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SystemTextStyles.body,
            ),
          ),
          const SizedBox(width: SystemSpacing.sm),
          Text(
            '${session.volumeTotal.round()} KG',
            style: SystemTextStyles.label
                .copyWith(fontSize: 9.6, color: SystemPalette.gold),
          ),
        ],
      ),
    );
  }
}

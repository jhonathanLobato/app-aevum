import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/system_back_button.dart';
import '../../../design_system/system_colors.dart';
import '../../../design_system/system_empty_state.dart';
import '../../../design_system/system_entrance.dart';
import '../../../design_system/system_motion.dart';
import '../../../design_system/system_panel.dart';
import '../../../design_system/system_scaffold.dart';
import '../../../design_system/system_spacing.dart';
import '../../../design_system/system_text_styles.dart';
import '../../statistics/domain/statistics.dart';
import '../../statistics/presentation/statistics_providers.dart';
import '../domain/achievement.dart';
import 'achievement_progress.dart';
import 'achievement_providers.dart';
import 'widgets/achievement_card.dart';

/// Tela de Conquistas ("galeria de troféus"): resumo de progresso + grade
/// de 2 colunas de [AchievementCard].
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);
    final statsAsync = ref.watch(globalStatisticsProvider);

    return SystemScaffold(
      title: 'CONQUISTAS',
      subtitle: 'TROFÉUS DO SISTEMA',
      leading: const SystemBackButton(),
      body: achievementsAsync.when(
        data: (conquistas) {
          if (conquistas.isEmpty) {
            return const SystemEmptyState(
              icon: Icons.emoji_events_outlined,
              message: 'NENHUMA CONQUISTA DISPONÍVEL',
            );
          }
          final stats = statsAsync.valueOrNull;
          return _AchievementsGrid(conquistas: conquistas, stats: stats);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: SystemPalette.primary),
        ),
        error: (error, stackTrace) => const SystemEmptyState(
          icon: Icons.error_outline,
          message: 'ERRO AO CARREGAR CONQUISTAS',
        ),
      ),
    );
  }
}

class _AchievementsGrid extends StatelessWidget {
  const _AchievementsGrid({required this.conquistas, required this.stats});

  final List<Achievement> conquistas;
  final GlobalStatistics? stats;

  @override
  Widget build(BuildContext context) {
    final desbloqueadas = conquistas
        .where((a) => a.status == AchievementStatus.desbloqueada)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SystemEntrance(
          child: SystemPanel(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text('DESBLOQUEADAS', style: SystemTextStyles.label),
                ),
                Text(
                  '$desbloqueadas / ${conquistas.length}',
                  style: const TextStyle(
                    fontFamily: SystemFonts.display,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: SystemPalette.primary,
                    shadows: SystemTextStyles.glowPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: SystemSpacing.lg),
        SystemEntrance(
          delay: SystemDurations.staggerStep,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < conquistas.length; i += 2) ...[
                if (i > 0) const SizedBox(height: SystemSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _card(conquistas[i])),
                    const SizedBox(width: SystemSpacing.md),
                    Expanded(
                      child: i + 1 < conquistas.length
                          ? _card(conquistas[i + 1])
                          : const SizedBox(),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _card(Achievement a) {
    final progresso =
        stats == null ? null : progressoDaConquista(a.chave, stats!);
    return AchievementCard(achievement: a, progresso: progresso);
  }
}

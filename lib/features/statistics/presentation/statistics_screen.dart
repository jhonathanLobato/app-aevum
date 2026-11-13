import 'package:flutter/material.dart';
import '../../profile/presentation/profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/system_colors.dart';
import '../../../design_system/system_empty_state.dart';
import '../../../design_system/system_entrance.dart';
import '../../../design_system/system_motion.dart';
import '../../../design_system/system_panel.dart';
import '../../../design_system/system_scaffold.dart';
import '../../../design_system/system_spacing.dart';
import '../../../design_system/system_stat_box.dart';
import '../../../design_system/system_text_styles.dart';
import '../../rank_exam/presentation/widgets/rank_summary_card.dart';
import '../domain/statistics.dart';
import 'statistics_providers.dart';
// Atributos escondidos por enquanto (serão usados depois):
// import 'widgets/player_attributes_panel.dart';
import 'widgets/weekly_report_card.dart';

/// Tela STATUS ("ficha de evolução"), em quadros, nesta ordem: Rank (abre a
/// tela de Rank), Relatório semanal, Histórico/Conquistas e as estatísticas
/// globais. A identidade fica na tela Sistema.
///
/// Os atributos (Força/Resistência/Constância) estão comentados abaixo — o
/// código e o `PlayerAttributesPanel` continuam no projeto para uso futuro.
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final globalAsync = ref.watch(globalStatisticsProvider);

    return SystemScaffold(
      title: 'STATUS',
      subtitle: 'FICHA DO CAÇADOR',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SystemEntrance(child: RankSummaryCard()),
          const SizedBox(height: SystemSpacing.lg),
          const SystemEntrance(
            delay: SystemDurations.staggerStep,
            child: WeeklyReportCard(),
          ),
          const SizedBox(height: SystemSpacing.lg),
          SystemEntrance(
            delay: SystemDurations.staggerStep * 2,
            child: SystemPanel(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _Entrada(
                    chave: const Key('entrada_historico'),
                    icone: Icons.history_rounded,
                    titulo: 'HISTÓRICO',
                    detalhe: 'Treinos e atividades por mês',
                    onTap: () => context.push('/history'),
                  ),
                  Divider(
                      height: 1,
                      color: SystemPalette.primary.withValues(alpha: 0.15)),
                  _Entrada(
                    chave: const Key('entrada_conquistas'),
                    icone: Icons.emoji_events_rounded,
                    iconeCor: SystemPalette.gold,
                    titulo: 'CONQUISTAS',
                    detalhe: 'Troféus do Sistema',
                    onTap: () => context.push('/achievements'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: SystemSpacing.lg),
          SystemEntrance(
            delay: SystemDurations.staggerStep * 3,
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
          // Atributos (escondido por enquanto; será usado depois):
          // const SizedBox(height: SystemSpacing.lg),
          // SystemEntrance(
          //   delay: SystemDurations.staggerStep * 4,
          //   child: const PlayerAttributesPanel(),
          // ),
        ],
      ),
    );
  }
}

/// Uma entrada do quadro Histórico/Conquistas.
class _Entrada extends StatelessWidget {
  const _Entrada({
    required this.chave,
    required this.icone,
    required this.titulo,
    required this.detalhe,
    required this.onTap,
    this.iconeCor = SystemPalette.primary,
  });

  final Key chave;
  final IconData icone;
  final Color iconeCor;
  final String titulo;
  final String detalhe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: chave,
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(SystemSpacing.lg),
        child: Row(
          children: [
            Icon(icone, size: 22, color: iconeCor),
            const SizedBox(width: SystemSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: SystemTextStyles.displaySmall),
                  Text(detalhe,
                      style: SystemTextStyles.body
                          .copyWith(color: SystemPalette.mutedForeground)),
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
              child: Consumer(
                builder: (context, ref, _) => SystemStatBox(
                  label: 'VOLUME',
                  value: ref
                      .watch(unitsProvider)
                      .formatarPeso(stats.volumeTotal, casas: 0),
                ),
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

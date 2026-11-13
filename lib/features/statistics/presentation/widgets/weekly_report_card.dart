import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/system_button.dart';
import '../../../../design_system/system_colors.dart';
import '../../../../design_system/system_panel.dart';
import '../../../../design_system/system_spacing.dart';
import '../../../../design_system/system_stat_box.dart';
import '../../../../design_system/system_text_styles.dart';
import '../../domain/weekly_report.dart';
import '../statistics_providers.dart';

String periodoDaSemana(WeeklyReport r) {
  String d(DateTime x) =>
      '${x.day.toString().padLeft(2, '0')}/${x.month.toString().padLeft(2, '0')}';
  return '${d(r.inicio)} – ${d(r.fim)}';
}

/// Treinos, atividades e recordes de uma semana.
class WeeklyReportStats extends StatelessWidget {
  const WeeklyReportStats({super.key, required this.relatorio});

  final WeeklyReport relatorio;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SystemStatBox(
            label: 'TREINOS',
            value: '${relatorio.treinos}',
            icon: Icons.fitness_center,
          ),
        ),
        const SizedBox(width: SystemSpacing.sm),
        Expanded(
          child: SystemStatBox(
            label: 'ATIVIDADES',
            value: '${relatorio.atividades}',
            icon: Icons.directions_run,
          ),
        ),
        const SizedBox(width: SystemSpacing.sm),
        Expanded(
          child: SystemStatBox(
            label: 'RECORDES',
            value: '${relatorio.recordes}',
            icon: Icons.emoji_events_outlined,
            iconColor: SystemPalette.gold,
          ),
        ),
      ],
    );
  }
}

/// Cartão do relatório da semana atual (Status), com acesso aos anteriores.
class WeeklyReportCard extends ConsumerWidget {
  const WeeklyReportCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relatorios = ref.watch(weeklyReportsProvider).valueOrNull;
    final atual = relatorios?.first;

    return SystemPanel(
      title: 'RELATÓRIO SEMANAL',
      action: atual == null
          ? null
          : Text(periodoDaSemana(atual),
              style: SystemTextStyles.label
                  .copyWith(fontSize: 8.5, color: SystemPalette.violet)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (atual != null) WeeklyReportStats(relatorio: atual),
          const SizedBox(height: SystemSpacing.md),
          SystemButton(
            label: 'Relatórios anteriores',
            icon: const Icon(Icons.history,
                size: 16, color: SystemPalette.foreground),
            onPressed: () => context.push('/reports'),
          ),
        ],
      ),
    );
  }
}

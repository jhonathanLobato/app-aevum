import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/system_back_button.dart';
import '../../../design_system/system_colors.dart';
import '../../../design_system/system_empty_state.dart';
import '../../../design_system/system_panel.dart';
import '../../../design_system/system_scaffold.dart';
import '../../../design_system/system_spacing.dart';
import 'statistics_providers.dart';
import 'widgets/weekly_report_card.dart';

/// Lista de relatórios semanais (da semana atual para trás).
class WeeklyReportsScreen extends ConsumerWidget {
  const WeeklyReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relatoriosAsync = ref.watch(weeklyReportsProvider);

    return SystemScaffold(
      title: 'RELATÓRIOS',
      subtitle: 'SEMANA A SEMANA',
      leading: const SystemBackButton(),
      body: relatoriosAsync.when(
        data: (lista) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < lista.length; i++) ...[
              if (i > 0) const SizedBox(height: SystemSpacing.md),
              SystemPanel(
                title: i == 0 ? 'SEMANA ATUAL' : 'SEMANA',
                action: Text(periodoDaSemana(lista[i])),
                child: WeeklyReportStats(relatorio: lista[i]),
              ),
            ],
          ],
        ),
        loading: () => const Center(
            child: CircularProgressIndicator(color: SystemPalette.primary)),
        error: (error, stackTrace) => const SystemEmptyState(
            icon: Icons.error_outline, message: 'ERRO AO CARREGAR RELATÓRIOS'),
      ),
    );
  }
}

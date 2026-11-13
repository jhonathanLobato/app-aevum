import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/system_colors.dart';
import '../../../../design_system/system_panel.dart';
import '../../../../design_system/system_spacing.dart';
import '../../../../design_system/system_text_styles.dart';
import '../../../daily/domain/daily_values.dart';
import '../../../daily/presentation/daily_providers.dart';
import '../../../daily/presentation/widgets/daily_part_bar.dart';

/// Resumo da missão diária (3 barras). Tocar abre a tela da missão.
class HomeDailyPanel extends ConsumerWidget {
  const HomeDailyPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progresso = ref.watch(dailyTodayProvider).valueOrNull;

    final String selo;
    final Color corSelo;
    if (progresso != null && progresso.folga) {
      selo = 'FOLGA';
      corSelo = SystemPalette.primary;
    } else if (progresso != null && progresso.concluida) {
      selo = 'CUMPRIDA';
      corSelo = SystemPalette.success;
    } else {
      selo = '+${DailyValues.xpMissao} XP';
      corSelo = SystemPalette.gold;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/missions/daily'),
      child: SystemPanel(
        title: 'MISSÃO DIÁRIA',
        action: Text(selo,
            style:
                SystemTextStyles.label.copyWith(fontSize: 8.8, color: corSelo)),
        child: progresso == null
            ? const SizedBox(height: 120)
            : Column(
                children: [
                  for (var i = 0; i < DailyPart.values.length; i++) ...[
                    if (i > 0) const SizedBox(height: SystemSpacing.md),
                    DailyPartBar(
                        parte: DailyPart.values[i], progresso: progresso),
                  ],
                ],
              ),
      ),
    );
  }
}

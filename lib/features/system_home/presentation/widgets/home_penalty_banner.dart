import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/system_button.dart';
import '../../../../design_system/system_colors.dart';
import '../../../../design_system/system_spacing.dart';
import '../../../../design_system/system_text_styles.dart';
import '../../../daily/presentation/daily_providers.dart';

/// Aviso vermelho (estilo Sistema) com o XP perdido na penalidade da
/// missão diária não cumprida. Fica até o usuário confirmar.
class HomePenaltyBanner extends ConsumerWidget {
  const HomePenaltyBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perdido = ref.watch(pendingPenaltyProvider).valueOrNull ?? 0;
    if (perdido <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: SystemSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(SystemSpacing.lg),
        decoration: BoxDecoration(
          color: SystemPalette.destructive.withValues(alpha: 0.12),
          border: Border.all(color: SystemPalette.destructive),
          boxShadow: [
            BoxShadow(
                color: SystemPalette.destructive.withValues(alpha: 0.35),
                blurRadius: 18),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: SystemPalette.destructive, size: 22),
                const SizedBox(width: SystemSpacing.sm),
                Text('PENALIDADE APLICADA',
                    style: SystemTextStyles.label
                        .copyWith(color: SystemPalette.destructive)),
              ],
            ),
            const SizedBox(height: SystemSpacing.sm),
            Text('-$perdido XP',
                style: SystemTextStyles.displayMedium
                    .copyWith(color: SystemPalette.destructive)),
            const SizedBox(height: 2),
            Text(
              'A missão diária não foi cumprida. O nível e o rank não são afetados.',
              style: SystemTextStyles.body
                  .copyWith(color: SystemPalette.mutedForeground),
            ),
            const SizedBox(height: SystemSpacing.md),
            SystemButton(
              label: 'Entendi',
              variant: SystemButtonVariant.danger,
              onPressed: () =>
                  ref.read(dailyRepositoryProvider).confirmarPenalidades(),
            ),
          ],
        ),
      ),
    );
  }
}

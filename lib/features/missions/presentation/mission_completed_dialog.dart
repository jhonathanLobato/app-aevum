import 'package:flutter/material.dart';

import '../../../design_system/system_colors.dart';
import '../../../design_system/system_feedback_dialog.dart';
import '../../../design_system/system_spacing.dart';
import '../../../design_system/system_text_styles.dart';
import '../domain/mission.dart';

/// Missão concluída: feedback médio (Fase 9, seção 14/16). O XP mostrado é
/// sempre `missao.recompensaXp` — o valor real já persistido pela missão,
/// nunca recalculado aqui.
Future<void> showMissionsCompletedDialog(
  BuildContext context,
  List<Mission> missoes,
) {
  return showDialog(
    context: context,
    builder: (context) => SystemFeedbackDialog(
      icon: Icons.flag_circle,
      title: 'Missão Concluída',
      accentColor: SystemPalette.primary,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final missao in missoes) ...[
            Text(
              missao.nome.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: SystemFonts.display,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: SystemPalette.foreground,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '+${missao.recompensaXp} XP',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: SystemFonts.display,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: SystemPalette.primary,
              ),
            ),
            if (missao != missoes.last)
              const SizedBox(height: SystemSpacing.md),
          ],
        ],
      ),
    ),
  );
}

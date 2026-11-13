import 'package:flutter/material.dart';

import '../../../design_system/system_colors.dart';
import '../../../design_system/system_feedback_dialog.dart';
import '../../../design_system/system_spacing.dart';
import '../../../design_system/system_text_styles.dart';
import '../domain/achievement.dart';

/// Conquista desbloqueada: o feedback mais forte depois do LEVEL UP.
/// Conquistas não concedem XP — nenhum "+XP" é mostrado aqui.
Future<void> showAchievementsUnlockedDialog(
  BuildContext context,
  List<Achievement> conquistas,
) {
  return showDialog(
    context: context,
    builder: (context) => SystemFeedbackDialog(
      icon: Icons.military_tech,
      title: 'Conquista Desbloqueada',
      accentColor: SystemPalette.gold,
      intensity: SystemFeedbackIntensity.strong,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final conquista in conquistas) ...[
            Text(
              conquista.nome.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: SystemFonts.display,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: SystemPalette.gold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              conquista.descricao,
              textAlign: TextAlign.center,
              style: SystemTextStyles.bodySmall,
            ),
            if (conquista != conquistas.last)
              const SizedBox(height: SystemSpacing.md),
          ],
        ],
      ),
    ),
  );
}

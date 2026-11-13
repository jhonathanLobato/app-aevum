import 'package:flutter/material.dart';

import 'system_colors.dart';
import 'system_feedback_dialog.dart';
import 'system_spacing.dart';
import 'system_text_styles.dart';

/// Aviso de um evento do jogo no estilo do Sistema (ícone, brilho e botão OK),
/// no lugar de um SnackBar simples: missão diária cumprida, exame iniciado...
///
/// [linhas] são os detalhes (uma por linha) e [destaque] o valor grande
/// embaixo, como "+50 XP".
Future<void> showSystemNoticeDialog(
  BuildContext context, {
  required String titulo,
  required IconData icone,
  Color cor = SystemPalette.primary,
  String? mensagem,
  List<String> linhas = const [],
  String? destaque,
  SystemFeedbackIntensity intensidade = SystemFeedbackIntensity.medium,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => SystemFeedbackDialog(
      icon: icone,
      title: titulo,
      accentColor: cor,
      intensity: intensidade,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (mensagem != null)
            Text(mensagem,
                textAlign: TextAlign.center, style: SystemTextStyles.body),
          for (final l in linhas) ...[
            const SizedBox(height: SystemSpacing.xs),
            Text(l,
                textAlign: TextAlign.center,
                style: SystemTextStyles.bodySmall
                    .copyWith(color: SystemPalette.mutedForeground)),
          ],
          if (destaque != null) ...[
            const SizedBox(height: SystemSpacing.md),
            Text(
              destaque,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: SystemFonts.display,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: cor,
                shadows: [
                  Shadow(color: cor.withValues(alpha: 0.7), blurRadius: 12)
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

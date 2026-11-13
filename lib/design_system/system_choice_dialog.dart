import 'package:flutter/material.dart';

import 'system_button.dart';
import 'system_clippers.dart';
import 'system_colors.dart';
import 'system_effects.dart';
import 'system_feedback_dialog.dart';
import 'system_geometry.dart';
import 'system_spacing.dart';
import 'system_text_styles.dart';

/// Uma opção de [showSystemChoiceDialog].
class SystemChoice<T> {
  const SystemChoice({
    required this.label,
    required this.valor,
    this.variant = SystemButtonVariant.ghost,
  });

  final String label;
  final T valor;
  final SystemButtonVariant variant;
}

/// Diálogo do Aevum com 3+ saídas (ex.: continuar / descartar / voltar).
/// Devolve o `valor` da opção tocada, ou `null` se for fechado por fora.
Future<T?> showSystemChoiceDialog<T>(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  required List<SystemChoice<T>> opcoes,
  IconData icone = Icons.help_outline,
}) {
  return showDialog<T>(
    context: context,
    builder: (context) {
      const cor = SystemPalette.primary;
      return Dialog(
        backgroundColor: Colors.transparent,
        child: SystemDialogEntrance(
          child: ClipPath(
            clipper: const DiagonalCutCornersClipper(SystemCutSizes.panel),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: SystemGradients.panel,
                border: Border.all(
                  color: cor.withValues(alpha: 0.6),
                  width: SystemBorders.hairline,
                ),
                boxShadow: SystemShadows.coloredGlow(
                    cor.withValues(alpha: 0.35),
                    blurRadius: 24),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(SystemSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cor.withValues(alpha: 0.15),
                          border: Border.all(color: cor.withValues(alpha: 0.6)),
                        ),
                        child: Icon(icone, color: cor, size: 24),
                      ),
                    ),
                    const SizedBox(height: SystemSpacing.md),
                    Text(
                      titulo.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: SystemFonts.display,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.4,
                        color: cor,
                      ),
                    ),
                    const SizedBox(height: SystemSpacing.md),
                    Text(
                      mensagem,
                      textAlign: TextAlign.center,
                      style: SystemTextStyles.body,
                    ),
                    const SizedBox(height: SystemSpacing.lg),
                    for (var i = 0; i < opcoes.length; i++) ...[
                      if (i > 0) const SizedBox(height: SystemSpacing.sm),
                      SystemButton(
                        label: opcoes[i].label,
                        variant: opcoes[i].variant,
                        onPressed: () =>
                            Navigator.of(context).pop(opcoes[i].valor),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

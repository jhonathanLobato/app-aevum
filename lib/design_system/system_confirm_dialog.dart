import 'package:flutter/material.dart';

import 'system_button.dart';
import 'system_clippers.dart';
import 'system_colors.dart';
import 'system_effects.dart';
import 'system_feedback_dialog.dart';
import 'system_geometry.dart';
import 'system_spacing.dart';
import 'system_text_styles.dart';

/// Confirmação de ação (sim/não) no estilo do Aevum — substitui os
/// `AlertDialog` Material nas telas (encerrar treino, excluir treino...).
/// Retorna `true` se o usuário confirmar, `false` se cancelar ou fechar.
///
/// [destrutivo] pinta o diálogo de vermelho e usa o botão de perigo na
/// confirmação; sem ele, usa o ciano de ação normal.
Future<bool> showSystemConfirmDialog(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  required String confirmar,
  String cancelar = 'Cancelar',
  IconData icone = Icons.help_outline,
  bool destrutivo = false,
}) async {
  final resultado = await showDialog<bool>(
    context: context,
    builder: (context) => SystemConfirmDialog(
      titulo: titulo,
      mensagem: mensagem,
      confirmar: confirmar,
      cancelar: cancelar,
      icone: icone,
      destrutivo: destrutivo,
    ),
  );
  return resultado ?? false;
}

class SystemConfirmDialog extends StatelessWidget {
  const SystemConfirmDialog({
    super.key,
    required this.titulo,
    required this.mensagem,
    required this.confirmar,
    this.cancelar = 'Cancelar',
    this.icone = Icons.help_outline,
    this.destrutivo = false,
  });

  final String titulo;
  final String mensagem;
  final String confirmar;
  final String cancelar;
  final IconData icone;
  final bool destrutivo;

  @override
  Widget build(BuildContext context) {
    final cor = destrutivo ? SystemPalette.destructive : SystemPalette.primary;

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
              boxShadow: SystemShadows.coloredGlow(cor.withValues(alpha: 0.35),
                  blurRadius: 24),
            ),
            child: Padding(
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
                    style: TextStyle(
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
                  SystemButton(
                    label: confirmar,
                    variant: destrutivo
                        ? SystemButtonVariant.danger
                        : SystemButtonVariant.action,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                  const SizedBox(height: SystemSpacing.sm),
                  SystemButton(
                    label: cancelar,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

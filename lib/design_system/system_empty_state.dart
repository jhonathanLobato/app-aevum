import 'package:flutter/material.dart';

import 'system_colors.dart';
import 'system_spacing.dart';
import 'system_text_styles.dart';

/// Estado vazio/erro padrão do sistema — texto curto, maiúsculo, com um
/// ícone discreto opcional. Usado no lugar de `AlertDialog`s ou cards
/// Material genéricos sempre que uma tela ainda não tem dado real pra
/// mostrar (nenhuma missão ativa, nenhum treino, erro ao carregar etc.).
class SystemEmptyState extends StatelessWidget {
  const SystemEmptyState({
    super.key,
    required this.message,
    this.detail,
    this.icon,
  });

  /// Mensagem principal, curta (ex.: "NENHUMA MISSÃO ATIVA"). Sempre exibida
  /// em maiúsculas, como as demais labels do sistema.
  final String message;

  /// Texto auxiliar opcional, mais discreto, abaixo da mensagem principal.
  final String? detail;

  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SystemSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon,
                size: 28,
                color: SystemPalette.mutedForeground.withValues(alpha: 0.6)),
            const SizedBox(height: SystemSpacing.sm),
          ],
          Text(
            message.toUpperCase(),
            textAlign: TextAlign.center,
            style: SystemTextStyles.label,
          ),
          if (detail != null) ...[
            const SizedBox(height: SystemSpacing.xs),
            Text(
              detail!,
              textAlign: TextAlign.center,
              style: SystemTextStyles.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

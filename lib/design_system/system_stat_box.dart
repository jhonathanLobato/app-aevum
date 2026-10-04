import 'package:flutter/material.dart';

import 'system_colors.dart';
import 'system_spacing.dart';
import 'system_text_styles.dart';

/// Caixinha de estatística rotulada — borda fina + fundo `surface-2`, sem
/// corte diagonal (o Lovable usa essa mesma caixa simples em várias telas
/// pra números curtos: sequência, treinos, PR, meta). `value` aceita texto
/// livre (ex.: "65 KG", "3×10", "—" quando o dado ainda não existe).
class SystemStatBox extends StatelessWidget {
  const SystemStatBox({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: SystemSpacing.md, vertical: SystemSpacing.sm),
      decoration: BoxDecoration(
        color:
            SystemPalette.surface2.withValues(alpha: SystemOpacities.surface2),
        border: Border.all(
            color: SystemPalette.primary
                .withValues(alpha: SystemOpacities.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label.toUpperCase(),
              style: SystemTextStyles.label.copyWith(fontSize: 8)),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 16, color: iconColor ?? SystemPalette.foreground),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: SystemFonts.display,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: SystemPalette.foreground,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

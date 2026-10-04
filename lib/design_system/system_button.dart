import 'package:flutter/material.dart';

import 'system_clippers.dart';
import 'system_colors.dart';
import 'system_effects.dart';
import 'system_geometry.dart';
import 'system_motion.dart';
import 'system_spacing.dart';
import 'system_text_styles.dart';

/// Variantes visuais de [SystemButton], direto de `SystemButton.tsx`.
enum SystemButtonVariant { action, ghost, danger }

/// Tamanhos de [SystemButton] (`md`/`lg` no Lovable).
enum SystemButtonSize { md, lg }

/// Botão do sistema, direto de `SystemButton.tsx`.
///
/// Mobile não tem estado de hover real, então o sweep de brilho que o
/// Lovable anima em `hover:` não faz sentido aqui (seria um efeito sem
/// gatilho real, o tipo de animação que a Fase 9 pede pra evitar). O
/// feedback é só o toque: escala curta (`.press`, revisada na Fase 9 para
/// ficar um pouco mais perceptível) e troca de borda/sombra conforme
/// [SystemButtonVariant], usando
/// [SystemDurations.pressTransform]/[SystemDurations.pressDecoration]. A
/// resposta ao toque (`setState`) é sempre síncrona — o callback nunca
/// espera a animação terminar para disparar.
class SystemButton extends StatefulWidget {
  const SystemButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = SystemButtonVariant.ghost,
    this.size = SystemButtonSize.md,
    this.kicker,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final SystemButtonVariant variant;
  final SystemButtonSize size;

  /// Texto pequeno acima do rótulo principal (`kicker` em `SystemButton.tsx`,
  /// ex.: "SYSTEM ACTION").
  final String? kicker;

  final Widget? icon;

  /// Mostra um spinner no lugar do conteúdo e desabilita o toque, para uso
  /// futuro em ações assíncronas (ex.: salvar um treino).
  final bool loading;

  @override
  State<SystemButton> createState() => _SystemButtonState();
}

class _SystemButtonState extends State<SystemButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final isLg = widget.size == SystemButtonSize.lg;
    final padding = isLg
        ? const EdgeInsets.symmetric(
            horizontal: SystemSpacing.xl2, vertical: SystemSpacing.lg)
        : const EdgeInsets.symmetric(
            horizontal: SystemSpacing.lg, vertical: SystemSpacing.md);
    final labelStyle = SystemTextStyles.button.copyWith(
      fontSize: isLg ? 14 : 12,
      letterSpacing: isLg ? 2.52 : 2.16, // tracking-[0.18em]
    );

    return Opacity(
      opacity: _enabled || widget.loading ? 1 : SystemOpacities.disabled,
      child: GestureDetector(
        onTapDown: _enabled ? (_) => _setPressed(true) : null,
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        onTap: _enabled ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1,
          duration: SystemDurations.pressTransform,
          curve: SystemCurves.press,
          child: ClipPath(
            clipper: const DiagonalCutCornersClipper(SystemCutSizes.button),
            child: AnimatedContainer(
              duration: SystemDurations.pressDecoration,
              curve: SystemCurves.press,
              padding: padding,
              decoration: _decorationFor(widget.variant, _pressed),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: widget.loading
                    ? const [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: SystemPalette.foreground,
                          ),
                        ),
                      ]
                    : [
                        if (widget.icon != null) ...[
                          IconTheme(
                            data: const IconThemeData(
                                color: SystemPalette.foreground, size: 16),
                            child: widget.icon!,
                          ),
                          const SizedBox(width: SystemSpacing.sm),
                        ],
                        Flexible(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.kicker != null)
                                Text(
                                  widget.kicker!.toUpperCase(),
                                  style: SystemTextStyles.labelTiny.copyWith(
                                    color: SystemPalette.primary
                                        .withValues(alpha: 0.8),
                                  ),
                                ),
                              Text(
                                widget.label.toUpperCase(),
                                style: labelStyle,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _decorationFor(SystemButtonVariant variant, bool pressed) {
    switch (variant) {
      case SystemButtonVariant.action:
        return BoxDecoration(
          gradient: SystemGradients.action,
          border:
              Border.all(color: SystemPalette.primary.withValues(alpha: 0.6)),
          boxShadow:
              pressed ? SystemShadows.glowStrong : SystemShadows.glowPrimary,
        );
      case SystemButtonVariant.ghost:
        return BoxDecoration(
          color: SystemPalette.surface2
              .withValues(alpha: SystemOpacities.surface2),
          border: Border.all(
            color: pressed
                ? SystemPalette.primary.withValues(alpha: 0.6)
                : SystemPalette.primary
                    .withValues(alpha: SystemOpacities.border),
          ),
          boxShadow: pressed ? SystemShadows.glowPrimary : null,
        );
      case SystemButtonVariant.danger:
        return BoxDecoration(
          color:
              SystemPalette.destructive.withValues(alpha: pressed ? 0.2 : 0.1),
          border: Border.all(
              color: SystemPalette.destructive.withValues(alpha: 0.5)),
        );
    }
  }
}

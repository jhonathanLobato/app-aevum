import 'package:flutter/material.dart';

import 'system_clippers.dart';
import 'system_colors.dart';
import 'system_effects.dart';
import 'system_geometry.dart';
import 'system_spacing.dart';
import 'system_text_styles.dart';

/// Painel holográfico do sistema, direto de `Panel.tsx`.
///
/// Reproduz os cortes diagonais, o `gradient-panel`, a borda ciano
/// translúcida e os corner ticks do protótipo sem `BackdropFilter`: o
/// glassmorphism vem só de gradiente + borda + sombra, para não pesar em
/// telas com vários painéis simultâneos no Android.
///
/// A animação de entrada (`animate-panel-in`) fica para a Fase 9: a API
/// deste widget não precisa mudar para recebê-la, pois quem decidirá
/// animar é o widget pai (ex.: envolvendo em `FadeTransition`/`SlideTransition`
/// usando [SystemDurations.panelIn] e [SystemCurves.panelIn]).
class SystemPanel extends StatelessWidget {
  const SystemPanel({
    super.key,
    required this.child,
    this.title,
    this.action,
    this.glow = false,
    this.padding = const EdgeInsets.all(SystemSpacing.lg),
  });

  /// Conteúdo arbitrário do painel.
  final Widget child;

  /// Título opcional exibido no cabeçalho, com a marca `label-sys` (ciano à
  /// esquerda + texto). Sempre exibido em maiúsculas, como no CSS
  /// (`text-transform: uppercase` do `label-sys`).
  final String? title;

  /// Ação opcional alinhada à direita do cabeçalho (só aparece com [title]).
  final Widget? action;

  /// Troca a sombra externa por `panel-glow` (glow ciano) em vez da sombra
  /// neutra padrão — no CSS as duas são mutuamente exclusivas, não somadas.
  final bool glow;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const DiagonalCutCornersClipper(SystemCutSizes.panel),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: SystemGradients.panel,
          border: Border.all(
            color:
                SystemPalette.primary.withValues(alpha: SystemOpacities.border),
            width: SystemBorders.hairline,
          ),
          boxShadow:
              glow ? SystemShadows.panelGlowOuter : SystemShadows.panelOuter,
        ),
        child: Stack(
          children: [
            Padding(
              padding: padding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (title != null) ...[
                    Row(
                      children: [
                        Container(
                            width: 2, height: 12, color: SystemPalette.primary),
                        const SizedBox(width: SystemSpacing.sm),
                        Expanded(
                          child: Text(
                            title!.toUpperCase(),
                            style: SystemTextStyles.label.copyWith(
                              color: SystemPalette.foreground
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                        if (action != null) action!,
                      ],
                    ),
                    const SizedBox(height: SystemSpacing.md),
                  ],
                  child,
                ],
              ),
            ),
            const Positioned.fill(
              child: IgnorePointer(child: CornerTicks()),
            ),
          ],
        ),
      ),
    );
  }
}

/// Linha divisória tecnológica (`@utility divider-tech`): um hairline em
/// gradiente que esmaece nas pontas, em vez de uma borda sólida comum.
/// Direto do `Divider` exportado junto de `Panel.tsx`; reutilizado também
/// no topo de [SystemNavigationBar].
class SystemDivider extends StatelessWidget {
  const SystemDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: SystemBorders.hairline,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SystemPalette.primary.withValues(alpha: 0),
            SystemPalette.primary.withValues(alpha: SystemOpacities.divider),
            SystemPalette.primary.withValues(alpha: SystemOpacities.divider),
            SystemPalette.primary.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.15, 0.85, 1.0],
        ),
      ),
    );
  }
}

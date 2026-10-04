import 'package:flutter/material.dart';

import 'system_colors.dart';
import 'system_geometry.dart';

/// Fundo tecnológico padrão do app: base escura + glow radial azul/ciano no
/// topo + glow radial violeta na base + grid de 44px + scanlines discretas
/// — a combinação do `body` de `styles.css` com o `<div className="scanline
/// min-h-screen ...">` de `SystemLayout.tsx`.
///
/// Todas as camadas são puramente decorativas e nunca mudam depois do
/// primeiro layout, então cada uma fica isolada num `RepaintBoundary`
/// próprio e fora da árvore de toque/semântica (`IgnorePointer` +
/// `ExcludeSemantics`): elas nunca repintam por causa do [child], e o
/// [child] nunca repinta por causa delas.
class SystemBackground extends StatelessWidget {
  const SystemBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: SystemPalette.background),
        const RepaintBoundary(child: _RadialGlows()),
        const RepaintBoundary(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child:
                  CustomPaint(painter: TechGridPainter(), size: Size.infinite),
            ),
          ),
        ),
        child,
        const RepaintBoundary(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child:
                  CustomPaint(painter: ScanlinePainter(), size: Size.infinite),
            ),
          ),
        ),
      ],
    );
  }
}

/// Os dois glows radiais do fundo. `RadialGradient` do Flutter só desenha
/// círculos (sem suporte nativo a elipse como o `radial-gradient(ellipse ...)`
/// do CSS); em vez de um shader customizado, aproximamos com círculos
/// grandes e bem suaves posicionados na mesma região da tela — o efeito
/// visual (uma mancha de luz discreta no topo e outra na base) fica
/// equivalente sem o custo/complexidade de uma elipse de verdade.
class _RadialGlows extends StatelessWidget {
  const _RadialGlows();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Azul/ciano — aproxima `ellipse 80% 50% at 50% -10%`.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -1.2),
                  radius: 0.85,
                  colors: [
                    SystemPalette.backdropGlowBlue
                        .withValues(alpha: SystemOpacities.backdropGlowBlue),
                    SystemPalette.backdropGlowBlue.withValues(alpha: 0),
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
            // Violeta — aproxima `ellipse 60% 40% at 90% 110%`.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.8, 1.2),
                  radius: 0.7,
                  colors: [
                    SystemPalette.backdropGlowViolet
                        .withValues(alpha: SystemOpacities.backdropGlowViolet),
                    SystemPalette.backdropGlowViolet.withValues(alpha: 0),
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid tecnológico de fundo, espaçamento ~44px (`background-size: 44px
/// 44px` em `styles.css`). Parametrizável e reutilizável fora do
/// [SystemBackground] se alguma tela precisar de um grid isolado.
class TechGridPainter extends CustomPainter {
  const TechGridPainter({
    this.spacing = 44,
    this.color = SystemPalette.primary,
    this.opacity = SystemOpacities.gridLines,
    this.strokeWidth = SystemBorders.hairline,
  });

  final double spacing;
  final Color color;
  final double opacity;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = strokeWidth;
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant TechGridPainter oldDelegate) =>
      oldDelegate.spacing != spacing ||
      oldDelegate.color != color ||
      oldDelegate.opacity != opacity ||
      oldDelegate.strokeWidth != strokeWidth;
}

/// Scanlines discretas de HUD (`@utility scanline` em styles.css): faixas
/// horizontais de 1px repetidas a cada 4px, quase imperceptíveis. Estáticas
/// nesta fase — nenhuma animação de flicker/varredura.
class ScanlinePainter extends CustomPainter {
  const ScanlinePainter({
    this.spacing = 4,
    this.lineHeight = 1,
    this.color = SystemPalette.insetHighlight,
    this.opacity = SystemOpacities.scanline,
  });

  final double spacing;
  final double lineHeight;
  final Color color;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: opacity);
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, lineHeight), paint);
    }
  }

  @override
  bool shouldRepaint(covariant ScanlinePainter oldDelegate) =>
      oldDelegate.spacing != spacing ||
      oldDelegate.lineHeight != lineHeight ||
      oldDelegate.color != color ||
      oldDelegate.opacity != opacity;
}

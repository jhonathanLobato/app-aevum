import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';

import 'system_clippers.dart';
import 'system_colors.dart';
import 'system_effects.dart';
import 'system_geometry.dart';
import 'system_motion.dart';
import 'system_spacing.dart';
import 'system_text_styles.dart';

/// Barra de XP do sistema, direto de `XpBar.tsx`.
///
/// O preenchimento anima para o novo valor (`transition-[width]` do protótipo,
/// via [SystemDurations.xpFill]). Desde a Fase 9, quando [value] realmente
/// AUMENTA em relação ao build anterior, um brilho varre a barra uma única
/// vez (`xp-shine`) e para — nunca fica em loop, e não dispara de novo só
/// porque a tela rebuildou por outro motivo (o `State` compara o valor
/// antigo com o novo em [didUpdateWidget], não repete a cada frame).
class SystemXpBar extends StatefulWidget {
  const SystemXpBar({
    super.key,
    required this.value,
    required this.max,
    this.level,
    this.compact = false,
  }) : assert(max > 0, 'max precisa ser maior que zero');

  /// XP atual.
  final int value;

  /// XP necessário para o próximo nível.
  final int max;

  /// Quando informado, o cabeçalho mostra "LEVEL N" em vez de "EXPERIÊNCIA".
  final int? level;

  /// Modo compacto: esconde o cabeçalho e mostra o percentual abaixo da
  /// barra, em vez de "valor / máximo XP" acima dela.
  final bool compact;

  @override
  State<SystemXpBar> createState() => _SystemXpBarState();
}

class _SystemXpBarState extends State<SystemXpBar>
    with SingleTickerProviderStateMixin {
  late final _shineController = AnimationController(
    vsync: this,
    duration: SystemDurations.xpShine,
  );

  double get _fraction => (widget.value / widget.max).clamp(0, 1).toDouble();

  @override
  void didUpdateWidget(SystemXpBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final aumentou = widget.value > oldWidget.value;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (aumentou && !reduceMotion) {
      _shineController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.compact)
          Padding(
            padding: const EdgeInsets.only(bottom: SystemSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    widget.level != null
                        ? 'LEVEL ${widget.level}'
                        : 'EXPERIÊNCIA',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: SystemFonts.display,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3, // tracking-[0.25em] de 12px
                      color: SystemPalette.primary,
                      shadows: SystemTextStyles.glowPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: SystemSpacing.sm),
                Flexible(
                  child: Text(
                    '${_formatXp(widget.value)} / ${_formatXp(widget.max)} XP',
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: SystemFonts.display,
                      fontSize: 10.4,
                      letterSpacing: 1.04, // tracking-widest (0.1em)
                      color: SystemPalette.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ClipPath(
          clipper: const DiagonalCutCornersClipper(SystemCutSizes.small),
          child: Container(
            height: 12,
            decoration: BoxDecoration(
              color: SystemPalette.background.withValues(alpha: 0.7),
              border: Border.all(
                color: SystemPalette.primary
                    .withValues(alpha: SystemOpacities.border),
                width: SystemBorders.hairline,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const _XpSegments(),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: _fraction),
                      duration: SystemDurations.xpFill,
                      curve: SystemCurves.easeOut,
                      builder: (context, animatedFraction, _) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: constraints.maxWidth * animatedFraction,
                            decoration: BoxDecoration(
                              gradient: SystemGradients.xp,
                              boxShadow: [
                                BoxShadow(
                                  color: SystemPalette.primary.withValues(
                                    alpha: SystemOpacities.xpFillShadow,
                                  ),
                                  blurRadius: 14,
                                ),
                              ],
                            ),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                width: 2,
                                color: SystemPalette.foreground
                                    .withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                _XpShine(controller: _shineController),
              ],
            ),
          ),
        ),
        if (widget.compact)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${(_fraction * 100).round()}%',
                style: const TextStyle(
                  fontFamily: SystemFonts.display,
                  fontSize: 9.6,
                  letterSpacing: 0.96, // tracking-widest (0.1em)
                  color: SystemPalette.mutedForeground,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Varredura única do `xp-shine` (Fase 9): uma faixa de luz atravessa a
/// barra uma vez quando [controller] é disparado por [SystemXpBar], e
/// desaparece — nunca fica em loop. Isolado num `AnimatedBuilder` próprio
/// para não repintar o preenchimento/segmentos da barra a cada frame do
/// brilho; some do layout por completo (`SizedBox.shrink`) enquanto o
/// controller está parado, sem nenhum custo de pintura.
class _XpShine extends StatelessWidget {
  const _XpShine({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    // `Positioned` precisa ser filho direto do `Stack` (via `AnimatedBuilder`,
    // que não tem `RenderObject` próprio e por isso não quebra essa relação)
    // — por isso o `LayoutBuilder` que mede a largura disponível fica DENTRO
    // do `Positioned.fill`, nunca entre ele e o `Stack`.
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final t = controller.value;
          if (t <= 0 || t >= 1) return const SizedBox.shrink();

          // Nasce e morre em opacidade 0, com pico no meio da varredura —
          // sem usar uma curva de opacidade separada só para isso.
          final opacity = sin(pi * t) * SystemOpacities.shineHighlight;

          return LayoutBuilder(
            builder: (context, constraints) {
              final largura = constraints.maxWidth;
              final larguraFaixa = largura * 0.35;
              final x = -larguraFaixa + (largura + larguraFaixa * 2) * t;
              return Transform.translate(
                key: const Key('xp-shine-band'),
                offset: Offset(x, 0),
                child: SizedBox(
                  width: larguraFaixa,
                  height: constraints.maxHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          SystemPalette.foreground.withValues(alpha: 0),
                          SystemPalette.foreground.withValues(alpha: opacity),
                          SystemPalette.foreground.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Formata um inteiro com separador de milhar `.` (equivalente a
/// `toLocaleString("pt-BR")` no protótipo), sem depender do pacote `intl`
/// só para isso.
String _formatXp(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// As ~40 divisões verticais internas da trilha da barra (`border-primary/10`
/// repetido 40x no protótipo). Desenhadas com um único `CustomPainter` estático
/// em vez de 40 widgets, bem mais barato para o Android.
class _XpSegments extends StatelessWidget {
  const _XpSegments();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
        painter: _XpSegmentsPainter(), size: Size.infinite);
  }
}

class _XpSegmentsPainter extends CustomPainter {
  const _XpSegmentsPainter();

  static const _segments = 40;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = SystemPalette.primary
          .withValues(alpha: SystemOpacities.xpSegmentDivider)
      ..strokeWidth = SystemBorders.hairline;
    final step = size.width / _segments;
    for (var i = 1; i < _segments; i++) {
      final x = step * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _XpSegmentsPainter oldDelegate) => false;
}

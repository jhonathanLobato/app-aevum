import 'package:flutter/material.dart';

import 'system_clippers.dart';
import 'system_colors.dart';
import 'system_effects.dart';
import 'system_geometry.dart';
import 'system_motion.dart';

/// Barra de progresso genérica — mesma geometria/trilha do `SystemXpBar`
/// (corte diagonal pequeno, trilha translúcida, preenchimento em
/// gradiente), mas sem nenhum rótulo ou semântica de XP/nível.
///
/// Criada na Fase 7 especificamente pra progresso de missão: "2 de 3
/// treinos" não é XP, e reusar `SystemXpBar` pra isso confundiria os dois
/// conceitos (decisão explícita da Fase 7, seção 12/3). Qualquer progresso
/// que não seja XP deve usar este componente, não `SystemXpBar`.
class SystemProgressBar extends StatelessWidget {
  const SystemProgressBar({super.key, required this.value, required this.max});

  final num value;
  final num max;

  double get _fraction => max <= 0 ? 0 : (value / max).clamp(0, 1).toDouble();

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const DiagonalCutCornersClipper(SystemCutSizes.small),
      child: Container(
        height: 8,
        decoration: BoxDecoration(
          color: SystemPalette.background.withValues(alpha: 0.7),
          border: Border.all(
            color:
                SystemPalette.primary.withValues(alpha: SystemOpacities.border),
            width: SystemBorders.hairline,
          ),
        ),
        child: LayoutBuilder(
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
                    decoration:
                        const BoxDecoration(gradient: SystemGradients.xp),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

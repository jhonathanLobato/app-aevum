import 'package:flutter/material.dart';

import '../../../../design_system/system_colors.dart';
import '../../../../design_system/system_geometry.dart';

/// Trilha de progresso entre exercícios do carrossel — propositalmente
/// *não* é `SystemXpBar`: progresso entre exercícios e XP são conceitos
/// diferentes (o CLAUDE.md e a decisão da Fase 6 são explícitos sobre
/// isso), então não reutilizo o componente de XP só porque a geometria é
/// parecida. Um segmento por exercício: preenchido quando aquele exercício
/// já tem pelo menos uma série registrada, com destaque (borda + glow) no
/// exercício atual.
class WorkoutExerciseProgressTrack extends StatelessWidget {
  const WorkoutExerciseProgressTrack({
    super.key,
    required this.total,
    required this.currentIndex,
    required this.hasSeries,
  });

  final int total;

  final int currentIndex;

  /// `hasSeries[i]` indica se o exercício de índice `i` já tem alguma
  /// série registrada nesta sessão.
  final List<bool> hasSeries;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: _Segment(
              filled: i < hasSeries.length && hasSeries[i],
              current: i == currentIndex,
            ),
          ),
        ],
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.filled, required this.current});

  final bool filled;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final color =
        filled ? SystemPalette.primary : SystemPalette.mutedForeground;
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: color.withValues(alpha: filled ? 0.9 : 0.25),
        border: current
            ? Border.all(
                color: SystemPalette.primary, width: SystemBorders.hairline)
            : null,
        boxShadow: current
            ? [
                BoxShadow(
                    color: SystemPalette.primary.withValues(alpha: 0.7),
                    blurRadius: 6)
              ]
            : null,
      ),
    );
  }
}

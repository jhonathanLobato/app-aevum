import 'package:flutter/material.dart';

import '../../../../design_system/system_colors.dart';
import '../../../../design_system/system_progress_bar.dart';
import '../../../../design_system/system_spacing.dart';
import '../../../../design_system/system_text_styles.dart';
import '../../domain/rank_exam.dart';

/// Experiência de Caçador no rank atual: "atual / necessária" com barra.
/// Não aparece no rank máximo (não há próximo exame).
class HunterExperienceBar extends StatelessWidget {
  const HunterExperienceBar({super.key, required this.status});

  final RankStatus status;

  @override
  Widget build(BuildContext context) {
    if (status.proximoRank == null) return const SizedBox.shrink();
    final atingida = status.experienciaFaltando == 0;
    return Column(
      key: const Key('hunter_experience'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('EXPERIÊNCIA DE CAÇADOR',
                  style: SystemTextStyles.label
                      .copyWith(color: SystemPalette.mutedForeground)),
            ),
            Text(
              '${formatarExperiencia(status.experiencia)} / ${status.experienciaMinima}',
              key: const Key('hunter_experience_value'),
              style: SystemTextStyles.label.copyWith(
                  color: atingida ? SystemPalette.success : SystemPalette.gold),
            ),
          ],
        ),
        const SizedBox(height: SystemSpacing.xs),
        SystemProgressBar(
            value: status.experiencia, max: status.experienciaMinima),
      ],
    );
  }
}

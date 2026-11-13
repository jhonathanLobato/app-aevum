import 'package:flutter/material.dart';

import '../../../../design_system/system_colors.dart';
import '../../../../design_system/system_progress_bar.dart';
import '../../../../design_system/system_spacing.dart';
import '../../../../design_system/system_text_styles.dart';
import '../../domain/daily_models.dart';
import '../../domain/daily_values.dart';

String rotuloDaParte(DailyPart parte) => switch (parte) {
      DailyPart.flexoes => 'FLEXÕES',
      DailyPart.abdominais => 'ABDOMINAIS',
      DailyPart.km => 'CAMINHADA/CORRIDA',
    };

String textoDaParte(DailyPart parte, DailyProgress p) {
  switch (parte) {
    case DailyPart.flexoes:
      return '${p.flexoes} / ${DailyValues.metaFlexoes}';
    case DailyPart.abdominais:
      return '${p.abdominais} / ${DailyValues.metaAbdominais}';
    case DailyPart.km:
      final km =
          p.km.toStringAsFixed(p.km % 1 == 0 ? 0 : 2).replaceAll('.', ',');
      return '$km / ${DailyValues.metaKm.toStringAsFixed(0)} KM';
  }
}

/// Rótulo + valor + barra de uma parte da missão diária.
class DailyPartBar extends StatelessWidget {
  const DailyPartBar({super.key, required this.parte, required this.progresso});

  final DailyPart parte;
  final DailyProgress progresso;

  @override
  Widget build(BuildContext context) {
    final completa = progresso.fracao(parte) >= 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
                child: Text(rotuloDaParte(parte),
                    style: SystemTextStyles.label.copyWith(fontSize: 9))),
            Text(
              textoDaParte(parte, progresso),
              style: SystemTextStyles.label.copyWith(
                fontSize: 9,
                color: completa ? SystemPalette.success : SystemPalette.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: SystemSpacing.xs),
        SystemProgressBar(
            value: progresso.valor(parte), max: DailyValues.meta(parte)),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/system_colors.dart';
import '../../../design_system/system_spacing.dart';
import '../../../design_system/system_text_styles.dart';
import '../domain/sport_activity.dart';
import 'sport_activity_format.dart';

/// Linha de um registro (data, resumo e ritmo/velocidade). Tocar abre o
/// detalhe. Compartilhada entre "atividades recentes" e o histórico.
class SportActivityTile extends StatelessWidget {
  const SportActivityTile({
    super.key,
    required this.atividade,
    this.comAno = false,
  });

  final SportActivity atividade;
  final bool comAno;

  @override
  Widget build(BuildContext context) {
    final metrica = metricaDerivada(atividade);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () =>
          context.push('/activities/${atividade.tipo.name}/${atividade.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: SystemSpacing.md, vertical: SystemSpacing.md),
        decoration: BoxDecoration(
          color: SystemPalette.surface2
              .withValues(alpha: SystemOpacities.surface2),
          border: Border(
            left: BorderSide(
                color: SystemPalette.primary.withValues(alpha: 0.5), width: 2),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatarDataCurta(atividade.data, comAno: comAno),
                    style: SystemTextStyles.label.copyWith(
                      fontSize: 9.6,
                      color: SystemPalette.violet,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    resumoDaAtividade(atividade),
                    style: SystemTextStyles.displaySmall.copyWith(fontSize: 14),
                  ),
                  if (metrica != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      metrica,
                      style: SystemTextStyles.label.copyWith(
                        fontSize: 9.6,
                        color: SystemPalette.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: SystemPalette.mutedForeground),
          ],
        ),
      ),
    );
  }
}

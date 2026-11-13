import 'package:flutter/material.dart';

import '../../../design_system/system_colors.dart';
import '../../../design_system/system_feedback_dialog.dart';
import '../../../design_system/system_spacing.dart';
import '../../../design_system/system_text_styles.dart';
import '../../profile/domain/units.dart';
import '../../progression/domain/personal_record.dart';

/// PR é evento importante (Fase 9, seção 13/16): feedback médio, com ícone,
/// glow e o valor real de cada recorde batido. Quando [xpGanho] é informado
/// (o total real já concedido por este mesmo registro de série — PR e/ou
/// desafio de missão), mostra "+N XP" junto; nunca recalculado aqui, é
/// exatamente o valor que `WorkoutSessionRepository.logSet` retornou.
Future<void> showPrDetectedDialog(
  BuildContext context, {
  required String exerciseNome,
  required List<PersonalRecordBreak> prs,
  int? xpGanho,
  Units units = const Units(),
}) {
  return showDialog(
    context: context,
    builder: (context) => SystemFeedbackDialog(
      icon: Icons.emoji_events,
      title: 'Novo Recorde',
      accentColor: SystemPalette.gold,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            exerciseNome.toUpperCase(),
            textAlign: TextAlign.center,
            style: SystemTextStyles.label.copyWith(fontSize: 11),
          ),
          const SizedBox(height: SystemSpacing.md),
          for (final pr in prs) ...[
            Text(
              '${_labelTipo(pr.tipo)}: ${_formatarValor(pr.tipo, pr.valorNovo, units)}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: SystemFonts.display,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: SystemPalette.foreground,
              ),
            ),
            if (pr.valorAnterior != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Recorde anterior: ${_formatarValor(pr.tipo, pr.valorAnterior!, units)}',
                  textAlign: TextAlign.center,
                  style: SystemTextStyles.bodySmall,
                ),
              ),
            if (pr != prs.last) const SizedBox(height: SystemSpacing.sm),
          ],
          if (xpGanho != null) ...[
            const SizedBox(height: SystemSpacing.md),
            Text(
              '+$xpGanho XP',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: SystemFonts.display,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: SystemPalette.gold,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

String _labelTipo(PersonalRecordType tipo) {
  switch (tipo) {
    case PersonalRecordType.carga:
      return 'Carga';
    case PersonalRecordType.repeticoes:
      return 'Repetições';
    case PersonalRecordType.volume:
      return 'Volume';
  }
}

String _formatarValor(PersonalRecordType tipo, double valor, Units units) {
  switch (tipo) {
    case PersonalRecordType.carga:
      return units.formatarPeso(valor);
    case PersonalRecordType.repeticoes:
      return valor.toStringAsFixed(0);
    case PersonalRecordType.volume:
      return units.formatarPeso(valor, casas: 0);
  }
}

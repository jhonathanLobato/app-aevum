import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/system_colors.dart';
import '../../../../design_system/system_empty_state.dart';
import '../../../../design_system/system_panel.dart';
import '../../../../design_system/system_progress_bar.dart';
import '../../../../design_system/system_spacing.dart';
import '../../../../design_system/system_text_styles.dart';
import '../../domain/player_attributes_calculator.dart';
import '../statistics_providers.dart';

/// Painel "ATRIBUTOS" de Status, direto de `status.tsx` — mas só com os 3
/// atributos definitivos do MVP (Força/Resistência/Constância; Velocidade
/// e Mobilidade do Lovable foram propositalmente deixados de fora, seção 2
/// da Fase 8). Valores vêm de [PlayerAttributesCalculator] (Fase 8),
/// nunca inventados.
///
/// Usa [SystemProgressBar], não [SystemXpBar] — o Lovable reaproveita a
/// barra de XP aqui, mas atributo não é XP (mesma decisão já tomada pras
/// missões na Fase 7).
class PlayerAttributesPanel extends ConsumerWidget {
  const PlayerAttributesPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attributesAsync = ref.watch(playerAttributesProvider);

    return SystemPanel(
      title: 'ATRIBUTOS',
      child: attributesAsync.when(
        data: (attrs) => Column(
          children: [
            _AttributeRow(label: 'FORÇA', value: attrs.forca),
            const SizedBox(height: SystemSpacing.md),
            _AttributeRow(label: 'RESISTÊNCIA', value: attrs.resistencia),
            const SizedBox(height: SystemSpacing.md),
            _AttributeRow(label: 'CONSTÂNCIA', value: attrs.constancia),
          ],
        ),
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: SystemSpacing.md),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: SystemPalette.primary),
            ),
          ),
        ),
        error: (error, stackTrace) => const SystemEmptyState(
          icon: Icons.error_outline,
          message: 'ERRO AO CARREGAR ATRIBUTOS',
        ),
      ),
    );
  }
}

class _AttributeRow extends StatelessWidget {
  const _AttributeRow({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: SystemTextStyles.label.copyWith(fontSize: 8)),
            Text(
              '$value',
              style: const TextStyle(
                fontFamily: SystemFonts.display,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: SystemPalette.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SystemProgressBar(value: value, max: 100),
      ],
    );
  }
}

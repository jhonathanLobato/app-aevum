import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/system_colors.dart';
import '../../../design_system/system_spacing.dart';
import '../../../design_system/system_stat_box.dart';
import '../../../design_system/system_text_styles.dart';
import '../../profile/presentation/profile_providers.dart';
import '../domain/body.dart';
import 'body_providers.dart';

String formatarDataBr(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// "+1.2" / "-0.5" / "0.0".
String formatarVariacao(double v) =>
    '${v > 0 ? '+' : ''}${v.toStringAsFixed(1)}';

/// Resumo: peso atual, variação desde o primeiro registro e IMC (último peso
/// + altura do perfil). Usado na Ficha e no topo da tela Corpo.
class BodySummary extends ConsumerWidget {
  const BodySummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registros = ref.watch(bodyRecordsProvider).valueOrNull ?? const [];
    final units = ref.watch(unitsProvider);
    final altura = ref.watch(currentUserProvider).valueOrNull?.alturaCm;
    final peso = evolucaoDe(registros, BodyMeasure.peso);

    final atual = peso.ultimo;
    final variacao = peso.variacaoDesdePrimeiro;
    final imc = calcularImc(atual, altura);

    final pesoTxt =
        atual == null ? '—' : BodyMeasure.peso.formatar(atual, units);
    final varTxt = variacao == null
        ? '—'
        : '${formatarVariacao(units.pesoParaExibir(variacao))} ${units.pesoSufixo}';
    final imcTxt = imc == null ? '—' : imc.toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: SystemStatBox(
                  key: const Key('body_peso_atual'),
                  label: 'PESO ATUAL',
                  value: pesoTxt),
            ),
            const SizedBox(width: SystemSpacing.sm),
            Expanded(
              child: SystemStatBox(
                  key: const Key('body_variacao'),
                  label: 'VARIAÇÃO',
                  value: varTxt),
            ),
            const SizedBox(width: SystemSpacing.sm),
            Expanded(
              child: SystemStatBox(
                  key: const Key('body_imc'), label: 'IMC', value: imcTxt),
            ),
          ],
        ),
        const SizedBox(height: SystemSpacing.xs),
        Text(
          imc != null
              ? 'IMC ${faixaImc(imc)}'
              : (altura == null
                  ? 'Informe a altura na Ficha para calcular o IMC.'
                  : 'Registre seu peso para calcular o IMC.'),
          key: const Key('body_imc_faixa'),
          style: SystemTextStyles.body
              .copyWith(color: SystemPalette.mutedForeground),
        ),
      ],
    );
  }
}

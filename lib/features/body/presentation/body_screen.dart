import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/system_back_button.dart';
import '../../../design_system/system_button.dart';
import '../../../design_system/system_colors.dart';
import '../../../design_system/system_confirm_dialog.dart';
import '../../../design_system/system_empty_state.dart';
import '../../../design_system/system_panel.dart';
import '../../../design_system/system_scaffold.dart';
import '../../../design_system/system_spacing.dart';
import '../../../design_system/system_text_styles.dart';
import '../../profile/domain/units.dart';
import '../../profile/presentation/option_tile.dart';
import '../../profile/presentation/profile_providers.dart';
import '../domain/body.dart';
import 'body_providers.dart';
import 'body_summary.dart';

/// Tela Corpo: resumo, evolução (gráfico + comparações por medida) e a lista
/// de registros com editar/excluir.
class BodyScreen extends ConsumerStatefulWidget {
  const BodyScreen({super.key});

  @override
  ConsumerState<BodyScreen> createState() => _BodyScreenState();
}

class _BodyScreenState extends ConsumerState<BodyScreen> {
  BodyMeasure _medida = BodyMeasure.peso;

  Future<void> _excluir(BodyRecord r) async {
    final confirmou = await showSystemConfirmDialog(
      context,
      titulo: 'Excluir registro?',
      mensagem: 'O registro de ${formatarDataBr(r.data)} será apagado.',
      confirmar: 'Excluir',
    );
    if (confirmou) await ref.read(bodyRepositoryProvider).excluir(r.id);
  }

  @override
  Widget build(BuildContext context) {
    final registros = ref.watch(bodyRecordsProvider).valueOrNull ?? const [];
    final units = ref.watch(unitsProvider);
    final evolucao = evolucaoDe(registros, _medida);
    final recentes = registros.reversed.toList();

    return SystemScaffold(
      title: 'CORPO',
      subtitle: 'REGISTROS CORPORAIS',
      leading: const SystemBackButton(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SystemPanel(title: 'RESUMO', child: BodySummary()),
          const SizedBox(height: SystemSpacing.lg),
          SystemButton(
            key: const Key('body_novo'),
            label: 'Novo registro',
            variant: SystemButtonVariant.action,
            size: SystemButtonSize.lg,
            onPressed: () => context.push('/body/new'),
          ),
          const SizedBox(height: SystemSpacing.lg),
          if (registros.isEmpty)
            const SystemEmptyState(
                icon: Icons.monitor_weight_outlined,
                message: 'NENHUM REGISTRO CORPORAL')
          else ...[
            SystemPanel(
              title: 'EVOLUÇÃO',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: SystemSpacing.sm,
                    runSpacing: SystemSpacing.sm,
                    children: [
                      for (final m in BodyMeasure.values)
                        OptionTile(
                          key: Key('body_medida_${m.name}'),
                          selected: _medida == m,
                          semanticLabel: m.label,
                          onTap: () => setState(() => _medida = m),
                          child: OptionLabel(m.label, selected: _medida == m),
                        ),
                    ],
                  ),
                  const SizedBox(height: SystemSpacing.md),
                  _Grafico(evolucao: evolucao, medida: _medida, units: units),
                  const SizedBox(height: SystemSpacing.md),
                  for (final m in BodyMeasure.values)
                    _LinhaMedida(
                        medida: m,
                        evolucao: evolucaoDe(registros, m),
                        units: units,
                        destacada: m == _medida),
                ],
              ),
            ),
            const SizedBox(height: SystemSpacing.lg),
            SystemPanel(
              title: 'REGISTROS',
              child: Column(
                children: [
                  for (final r in recentes)
                    _LinhaRegistro(
                      registro: r,
                      units: units,
                      onEditar: () => context.push('/body/${r.id}/edit'),
                      onExcluir: () => _excluir(r),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Grafico extends StatelessWidget {
  const _Grafico(
      {required this.evolucao, required this.medida, required this.units});

  final MeasureEvolution evolucao;
  final BodyMeasure medida;
  final Units units;

  @override
  Widget build(BuildContext context) {
    if (evolucao.vazia) {
      return Text('Sem registros de ${medida.label.toLowerCase()}.',
          key: const Key('body_grafico_vazio'),
          style: SystemTextStyles.body
              .copyWith(color: SystemPalette.mutedForeground));
    }
    final valores = [
      for (final p in evolucao.pontos) medida.paraExibir(p.valor, units)
    ];
    var minY = valores.reduce((a, b) => a < b ? a : b);
    var maxY = valores.reduce((a, b) => a > b ? a : b);
    final folga = (maxY - minY) * 0.15 + 0.5;
    minY -= folga;
    maxY += folga;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          key: const Key('body_grafico'),
          height: 160,
          child: LineChart(LineChartData(
            minY: minY,
            maxY: maxY,
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (var i = 0; i < valores.length; i++)
                    FlSpot(i.toDouble(), valores[i]),
                ],
                color: SystemPalette.primary,
                barWidth: 2,
                dotData: const FlDotData(show: true),
              ),
            ],
          )),
        ),
        const SizedBox(height: SystemSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(formatarDataBr(evolucao.pontos.first.data),
                style: SystemTextStyles.label.copyWith(fontSize: 9)),
            Text(formatarDataBr(evolucao.pontos.last.data),
                style: SystemTextStyles.label.copyWith(fontSize: 9)),
          ],
        ),
      ],
    );
  }
}

/// Atual + variação em relação ao primeiro e ao registro anterior.
class _LinhaMedida extends StatelessWidget {
  const _LinhaMedida({
    required this.medida,
    required this.evolucao,
    required this.units,
    required this.destacada,
  });

  final BodyMeasure medida;
  final MeasureEvolution evolucao;
  final Units units;
  final bool destacada;

  @override
  Widget build(BuildContext context) {
    if (evolucao.vazia) return const SizedBox.shrink();
    // Deltas em unidade guardada → exibida (escala linear, sem offset).
    String delta(double? v) =>
        v == null ? '—' : formatarVariacao(medida.paraExibir(v, units));
    return Padding(
      key: Key('body_linha_${medida.name}'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(medida.label.toUpperCase(),
                style: SystemTextStyles.label.copyWith(
                    color: destacada
                        ? SystemPalette.primary
                        : SystemPalette.mutedForeground)),
          ),
          Expanded(
            flex: 3,
            child: Text(medida.formatar(evolucao.ultimo!, units),
                style: SystemTextStyles.body),
          ),
          Expanded(
            flex: 4,
            child: Text(
              '1º ${delta(evolucao.variacaoDesdePrimeiro)} · ant. ${delta(evolucao.variacaoDesdeAnterior)}',
              style: SystemTextStyles.body
                  .copyWith(color: SystemPalette.mutedForeground),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinhaRegistro extends StatelessWidget {
  const _LinhaRegistro({
    required this.registro,
    required this.units,
    required this.onEditar,
    required this.onExcluir,
  });

  final BodyRecord registro;
  final Units units;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  @override
  Widget build(BuildContext context) {
    final partes = [
      for (final m in BodyMeasure.values)
        if (m.de(registro) != null)
          '${m.label}: ${m.formatar(m.de(registro)!, units)}',
    ];
    return InkWell(
      key: Key('body_registro_${registro.id}'),
      onTap: onEditar,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: SystemSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(formatarDataBr(registro.data),
                      style:
                          SystemTextStyles.displaySmall.copyWith(fontSize: 13)),
                  Text(partes.join(' · '), style: SystemTextStyles.body),
                ],
              ),
            ),
            IconButton(
              key: Key('body_excluir_${registro.id}'),
              tooltip: 'Excluir registro',
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: SystemPalette.mutedForeground),
              onPressed: onExcluir,
            ),
          ],
        ),
      ),
    );
  }
}

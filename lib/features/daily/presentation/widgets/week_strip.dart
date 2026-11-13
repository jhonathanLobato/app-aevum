import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/system_colors.dart';
import '../../../../design_system/system_spacing.dart';
import '../../../../design_system/system_text_styles.dart';
import '../../domain/daily_models.dart';
import '../daily_providers.dart';

const _siglas = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'];

/// Faixa da semana (seg–dom) com o estado da missão diária de cada dia e um
/// ponto nos dias de treino programado. Tocar num dia (hoje ou futuro) abre
/// a escolha de usar/desfazer folga. Também mostra "Folgas: X/4".
class WeekStrip extends ConsumerWidget {
  const WeekStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dias = ref.watch(weekStripProvider).valueOrNull;
    final folgas = ref.watch(folgasProvider).valueOrNull;

    if (dias == null) return const SizedBox(height: 72);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final d in dias)
              Expanded(
                child: _DayCell(
                  info: d,
                  onTap: () => _alternarFolga(context, ref, d),
                ),
              ),
          ],
        ),
        const SizedBox(height: SystemSpacing.sm),
        Row(
          children: [
            const Icon(Icons.pause_circle_outline,
                size: 14, color: SystemPalette.primary),
            const SizedBox(width: 6),
            Text(
              'FOLGAS: ${folgas?.usadas ?? 0}/${folgas?.total ?? 4}',
              style: SystemTextStyles.label.copyWith(fontSize: 9),
            ),
            const SizedBox(width: SystemSpacing.sm),
            Expanded(
              child: Text('TOQUE NO DIA PARA USAR FOLGA',
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SystemTextStyles.label.copyWith(
                      fontSize: 7.5, color: SystemPalette.mutedForeground)),
            ),
          ],
        ),
      ],
    );
  }
}

/// Usa/desfaz a folga de [d] e avisa o resultado. Também usado pela tela da
/// missão diária.
Future<void> alternarFolgaDoDia(
    BuildContext context, WidgetRef ref, DateTime dia) async {
  final resultado = await ref.read(dailyRepositoryProvider).alternarFolga(dia);
  if (!context.mounted) return;
  final mensagem = switch (resultado) {
    FolgaResult.marcada => 'Folga marcada. A missão diária não será cobrada.',
    FolgaResult.desmarcada => 'Folga desfeita.',
    FolgaResult.limiteAtingido => 'Você já usou as 4 folgas deste mês.',
    FolgaResult.indisponivel =>
      'Não é possível usar folga neste dia (já passou ou a missão foi cumprida).',
  };
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(mensagem)));
}

Future<void> _alternarFolga(
        BuildContext context, WidgetRef ref, WeekDayInfo d) =>
    alternarFolgaDoDia(context, ref, d.dia);

class _DayCell extends StatelessWidget {
  const _DayCell({required this.info, required this.onTap});

  final WeekDayInfo info;
  final VoidCallback onTap;

  (IconData, Color) get _visual => switch (info.status) {
        DayStatus.cumprida => (Icons.check_circle, SystemPalette.success),
        DayStatus.folga => (Icons.pause_circle_filled, SystemPalette.primary),
        DayStatus.falhou => (Icons.cancel, SystemPalette.destructive),
        DayStatus.hoje => (Icons.adjust, SystemPalette.foreground),
        DayStatus.futuro => (
            Icons.radio_button_unchecked,
            SystemPalette.mutedForeground
          ),
      };

  @override
  Widget build(BuildContext context) {
    final (icone, cor) = _visual;
    return Semantics(
      button: true,
      label:
          '${_siglas[info.dia.weekday - 1]} ${info.dia.day}: ${info.status.name}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: SystemSpacing.sm),
          decoration: BoxDecoration(
            border: Border.all(
              color: info.ehHoje
                  ? SystemPalette.primary
                  : SystemPalette.primary.withValues(alpha: 0.15),
            ),
            color: info.ehHoje
                ? SystemPalette.primary.withValues(alpha: 0.08)
                : null,
          ),
          child: Column(
            children: [
              Text(_siglas[info.dia.weekday - 1],
                  style: SystemTextStyles.label.copyWith(fontSize: 8)),
              const SizedBox(height: 4),
              Icon(icone, size: 20, color: cor),
              const SizedBox(height: 4),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: info.treinoProgramado
                      ? SystemPalette.gold
                      : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

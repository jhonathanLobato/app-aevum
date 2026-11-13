import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/system_colors.dart';
import '../../../../design_system/system_panel.dart';
import '../../../../design_system/system_spacing.dart';
import '../../../../design_system/system_text_styles.dart';
import '../../../daily/presentation/daily_providers.dart';

const _siglas = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'];

/// "MINHA SEMANA": o usuário marca livremente quais dias da semana são de
/// treino de academia; os outros são descanso programado (3 treinos e 4
/// descansos, 6 e 1, etc.). A missão semanal usa esta programação.
class WeekSchedulePanel extends ConsumerWidget {
  const WeekSchedulePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programacao = ref.watch(scheduleProvider).valueOrNull ?? const {};
    final treinos = programacao.length;

    return SystemPanel(
      title: 'MINHA SEMANA',
      action: Text(
        '$treinos TREINO${treinos == 1 ? '' : 'S'} · ${7 - treinos} DESCANSO${7 - treinos == 1 ? '' : 'S'}',
        style: SystemTextStyles.label
            .copyWith(fontSize: 8.5, color: SystemPalette.gold),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (var dia = 1; dia <= 7; dia++)
                Expanded(
                  child: _Dia(
                    sigla: _siglas[dia - 1],
                    treino: programacao.contains(dia),
                    chave: Key('schedule_day_$dia'),
                    onTap: () => ref
                        .read(dailyRepositoryProvider)
                        .alternarDiaDeTreino(dia),
                  ),
                ),
            ],
          ),
          const SizedBox(height: SystemSpacing.sm),
          Text(
            'Toque nos dias de treino. Os demais são descanso programado.',
            style: SystemTextStyles.body
                .copyWith(color: SystemPalette.mutedForeground),
          ),
        ],
      ),
    );
  }
}

class _Dia extends StatelessWidget {
  const _Dia(
      {required this.sigla,
      required this.treino,
      required this.chave,
      required this.onTap});

  final String sigla;
  final bool treino;
  final Key chave;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: treino,
      label: '$sigla: ${treino ? 'treino' : 'descanso'}',
      child: GestureDetector(
        key: chave,
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: SystemSpacing.md),
          decoration: BoxDecoration(
            color:
                treino ? SystemPalette.primary.withValues(alpha: 0.15) : null,
            border: Border.all(
              color: treino
                  ? SystemPalette.primary
                  : SystemPalette.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            children: [
              Text(sigla,
                  style: SystemTextStyles.label.copyWith(
                      fontSize: 9,
                      color: treino
                          ? SystemPalette.primary
                          : SystemPalette.mutedForeground)),
              const SizedBox(height: 4),
              Icon(
                treino ? Icons.fitness_center : Icons.bedtime_outlined,
                size: 16,
                color: treino
                    ? SystemPalette.primary
                    : SystemPalette.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/system_button.dart';
import '../../../../design_system/system_colors.dart';
import '../../../../design_system/system_panel.dart';
import '../../../../design_system/system_spacing.dart';
import '../../../../design_system/system_text_styles.dart';
import '../../../daily/presentation/daily_providers.dart';
import '../../../workouts/presentation/widgets/active_workout_card.dart';
import '../../../workouts/presentation/workout_session_providers.dart';

/// "HOJE": treino programado (ou descanso programado) com o botão de
/// iniciar treino — ou o cartão do treino em andamento, se houver um.
class HomeTodayPanel extends ConsumerWidget {
  const HomeTodayPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ativo = ref.watch(activeWorkoutProvider).valueOrNull;
    if (ativo != null) return const ActiveWorkoutCard();

    final programacao = ref.watch(scheduleProvider).valueOrNull ?? const {};
    final hoje = DateTime.now().weekday;
    final String titulo;
    final String? detalhe;
    final bool treino;
    if (programacao.isEmpty) {
      titulo = 'NENHUM TREINO PROGRAMADO';
      detalhe = 'Escolha seus dias de treino na aba Treinos.';
      treino = true;
    } else if (programacao.contains(hoje)) {
      titulo = 'TREINO PROGRAMADO';
      detalhe = null;
      treino = true;
    } else {
      titulo = 'DESCANSO PROGRAMADO';
      detalhe = 'Hoje não há treino de academia. A missão diária continua.';
      treino = false;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: SystemSpacing.lg),
      child: SystemPanel(
        title: 'HOJE',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(titulo,
                style: SystemTextStyles.displaySmall.copyWith(
                    color: treino
                        ? SystemPalette.foreground
                        : SystemPalette.violet)),
            if (detalhe != null) ...[
              const SizedBox(height: 2),
              Text(detalhe,
                  style: SystemTextStyles.body
                      .copyWith(color: SystemPalette.mutedForeground)),
            ],
            const SizedBox(height: SystemSpacing.md),
            SystemButton(
              label: 'Iniciar treino',
              variant: treino
                  ? SystemButtonVariant.action
                  : SystemButtonVariant.ghost,
              size: SystemButtonSize.lg,
              kicker: treino ? 'SYSTEM ACTION' : null,
              icon: const Icon(Icons.play_arrow,
                  size: 16, color: SystemPalette.foreground),
              onPressed: () => context.go('/workouts'),
            ),
          ],
        ),
      ),
    );
  }
}

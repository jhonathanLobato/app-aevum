import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/system_colors.dart';
import '../../../../design_system/system_button.dart';
import '../../../../design_system/system_empty_state.dart';
import '../../../../design_system/system_panel.dart';
import '../../../../design_system/system_progress_bar.dart';
import '../../../../design_system/system_spacing.dart';
import '../../../../design_system/system_text_styles.dart';
import '../../../missions/domain/mission.dart';
import '../../../missions/presentation/mission_providers.dart';

/// "MISSÃO ATUAL", direto de `index.tsx`. Mostra a missão ativa mais
/// relevante entre as retornadas por [activeMissionsProvider] — não existe
/// um provider de "uma única missão em destaque", então a escolha é feita
/// aqui: prioriza uma missão diária (a mais comum de estar em andamento);
/// se não houver nenhuma diária ativa, usa a primeira da lista.
///
/// O CTA "Iniciar treino" do protótipo é mantido mesmo sem ligação direta
/// com a missão em si (no próprio protótipo ele já era só um atalho fixo
/// pra tela de treinos) — vai para a aba Treinos.
class HomeMissionPanel extends ConsumerWidget {
  const HomeMissionPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionsAsync = ref.watch(activeMissionsProvider);

    return missionsAsync.when(
      data: (missions) {
        if (missions.isEmpty) {
          return const SystemPanel(
            title: 'MISSÃO ATUAL',
            child: SystemEmptyState(
              icon: Icons.flag_outlined,
              message: 'NENHUMA MISSÃO ATIVA',
              detail: 'Finalize um treino para gerar novas missões.',
            ),
          );
        }

        final mission = missions.firstWhere(
          (m) => m.tipo == MissionType.diaria,
          orElse: () => missions.first,
        );
        final objetivo = mission.objetivo <= 0 ? 1 : mission.objetivo;

        return SystemPanel(
          title: 'MISSÃO ATUAL',
          action: Text(
            '+${mission.recompensaXp} XP',
            style: SystemTextStyles.label
                .copyWith(fontSize: 8.8, color: SystemPalette.gold),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(mission.nome, style: SystemTextStyles.displaySmall),
              const SizedBox(height: SystemSpacing.xs),
              Text(mission.descricao,
                  style: SystemTextStyles.body.copyWith(
                    color: SystemPalette.mutedForeground,
                  )),
              const SizedBox(height: SystemSpacing.md),
              SystemProgressBar(value: mission.progresso, max: objetivo),
              const SizedBox(height: SystemSpacing.md),
              SystemButton(
                label: 'Iniciar treino',
                variant: SystemButtonVariant.action,
                size: SystemButtonSize.lg,
                kicker: 'SYSTEM ACTION',
                icon: const Icon(Icons.play_arrow,
                    size: 16, color: SystemPalette.foreground),
                onPressed: () => context.go('/workouts'),
              ),
            ],
          ),
        );
      },
      loading: () => const SystemPanel(
        title: 'MISSÃO ATUAL',
        child: Padding(
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
      ),
      error: (error, stackTrace) => const SystemPanel(
        title: 'MISSÃO ATUAL',
        child: SystemEmptyState(
          icon: Icons.error_outline,
          message: 'ERRO AO CARREGAR MISSÕES',
        ),
      ),
    );
  }
}

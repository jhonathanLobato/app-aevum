import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/rank_badge.dart';
import '../../../../design_system/system_colors.dart';
import '../../../../design_system/system_empty_state.dart';
import '../../../../design_system/system_panel.dart';
import '../../../../design_system/system_spacing.dart';
import '../../../../design_system/system_text_styles.dart';
import '../../../../design_system/system_xp_bar.dart';
import '../../../profile/domain/level_curve.dart';
import '../../../profile/domain/player_class.dart';
import '../../../profile/domain/user_profile.dart';
import '../../../profile/presentation/profile_providers.dart';

/// Painel de identidade do topo de Status, direto de `status.tsx`: rank,
/// nome, classe, nível e XP real — mesmos dados de [HomeIdentityPanel]
/// (Fase 5), mas sem o rótulo "SYSTEM ONLINE" nem a linha de
/// sequência/treinos (o protótipo não tem isso aqui, e Status já tem seu
/// próprio grid de estatísticas logo abaixo). Widget próprio, não
/// compartilhado com a Home, pra não arriscar mexer numa tela já aprovada
/// só por causa de uma pequena diferença de conteúdo.
class StatusIdentityPanel extends ConsumerWidget {
  const StatusIdentityPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) => _Content(user: user),
      loading: () => const SystemPanel(
        glow: true,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: SystemSpacing.lg),
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
        glow: true,
        child: SystemEmptyState(
          icon: Icons.error_outline,
          message: 'ERRO AO CARREGAR STATUS',
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.user});

  final UserProfile? user;

  @override
  Widget build(BuildContext context) {
    final nome = user?.nome ?? 'Jogador';
    final classe = user?.classe ?? PlayerClass.guerreiro;
    final rank = user?.rank ?? 'F';
    final info = const LevelCurve().calcularNivel(user?.xp ?? 0);

    return SystemPanel(
      glow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              RankBadge(rank: rank, size: 56),
              const SizedBox(width: SystemSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SystemTextStyles.displayMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '⚔ ${nomeDaClasse(classe).toUpperCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SystemTextStyles.label
                          .copyWith(color: SystemPalette.violet),
                    ),
                  ],
                ),
              ),
              Text(
                'LV. ${info.nivel}',
                style: const TextStyle(
                  fontFamily: SystemFonts.display,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: SystemPalette.primary,
                  shadows: SystemTextStyles.glowPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: SystemSpacing.md),
          const SystemDivider(),
          const SizedBox(height: SystemSpacing.md),
          SystemXpBar(
              value: info.xpNoNivelAtual,
              max: info.xpParaProximoNivel,
              level: info.nivel),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/rank_badge.dart';
import '../../../../design_system/system_colors.dart';
import '../../../../design_system/system_empty_state.dart';
import '../../../../design_system/system_panel.dart';
import '../../../../design_system/system_spacing.dart';
import '../../../../design_system/system_text_styles.dart';
import '../../../../design_system/system_xp_bar.dart';
import '../../../profile/domain/level_curve.dart';
import '../../../profile/domain/player_class.dart';
import '../../../profile/domain/titles.dart';
import '../../../profile/domain/user_profile.dart';
import '../../../profile/presentation/avatar_icons.dart';
import '../../../profile/presentation/profile_providers.dart';
import '../../../statistics/presentation/statistics_providers.dart';

/// Painel de identidade do jogador — o "hero card" do topo da Home, direto
/// de `index.tsx` (primeiro `<Panel glow>`). Nome, classe, rank e nível
/// vêm de [currentUserProvider]; a sequência/treinos realizados vêm de
/// [globalStatisticsProvider].
///
/// Quando ainda não existe nenhuma linha de usuário no banco (antes de
/// qualquer ação que conceda XP), [currentUserProvider] emite `null` — não
/// é um caso hipotético, é o estado real de primeiro uso do app. Nesse
/// caso mostramos os valores-padrão que o próprio repositório usa ao criar
/// a primeira linha (nome "Jogador", nível 1, rank F, 0 XP), não um dado
/// inventado.
class HomeIdentityPanel extends ConsumerWidget {
  const HomeIdentityPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) => _IdentityContent(user: user),
      loading: () => const SystemPanel(
        glow: true,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: SystemSpacing.lg),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: SystemPalette.primary,
              ),
            ),
          ),
        ),
      ),
      error: (error, stackTrace) => const SystemPanel(
        glow: true,
        child: SystemEmptyState(
          icon: Icons.error_outline,
          message: 'ERRO AO CARREGAR SISTEMA',
          detail: 'Não foi possível ler seu perfil agora.',
        ),
      ),
    );
  }
}

class _IdentityContent extends ConsumerWidget {
  const _IdentityContent({required this.user});

  final UserProfile? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nome = user?.nome ?? 'Jogador';
    final classe = user?.classe ?? PlayerClass.guerreiro;
    final rank = user?.rank ?? 'F';
    final info = const LevelCurve().calcularNivel(user?.xp ?? 0);

    // O painel inteiro abre o Perfil (como o da missão diária).
    return GestureDetector(
      key: const Key('home_avatar'),
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/profile'),
      child: SystemPanel(
        glow: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  margin: const EdgeInsets.only(right: SystemSpacing.md),
                  decoration: BoxDecoration(
                    color: SystemPalette.primary.withValues(alpha: 0.08),
                    border: Border.all(color: SystemPalette.primary),
                  ),
                  child: Icon(iconeDoAvatar(user?.avatar),
                      color: SystemPalette.primary, size: 26),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (user?.titulo ?? tituloPadrao).toUpperCase(),
                        key: const Key('home_titulo'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SystemTextStyles.label
                            .copyWith(color: SystemPalette.gold),
                      ),
                      const SizedBox(height: SystemSpacing.xs),
                      Text(
                        nome.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SystemTextStyles.displayLarge,
                      ),
                      const SizedBox(height: SystemSpacing.xs),
                      Text(
                        '⚔ ${nomeDaClasse(classe).toUpperCase()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: SystemFonts.body,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.5, // tracking-[0.18em] de 14px
                          color: SystemPalette.violet,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: SystemSpacing.md),
                Column(
                  children: [
                    RankBadge(rank: rank, size: 56),
                    const SizedBox(height: SystemSpacing.sm),
                    Text(
                      'LV. ${info.nivel}',
                      style: const TextStyle(
                        fontFamily: SystemFonts.display,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.8,
                        color: SystemPalette.primary,
                        shadows: SystemTextStyles.glowPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: SystemSpacing.md),
            const SystemDivider(),
            const SizedBox(height: SystemSpacing.md),
            SystemXpBar(
              value: info.xpNoNivelAtual,
              max: info.xpParaProximoNivel,
              level: info.nivel,
            ),
            const SizedBox(height: SystemSpacing.md),
            const _HomeStatsRow(),
          ],
        ),
      ),
    );
  }
}

/// Sequência de dias (maior já alcançada — ver doc de [GlobalStatistics])
/// e total de treinos realizados. Observa [globalStatisticsProvider] à
/// parte do resto do card: enquanto ele carrega, o nome/nível/XP já
/// aparecem normalmente, só os dois números desta linha mostram "—".
class _HomeStatsRow extends ConsumerWidget {
  const _HomeStatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(globalStatisticsProvider);

    final sequencia = statsAsync.maybeWhen(
      data: (stats) => '${stats.maiorSequenciaDias} DIAS',
      orElse: () => '—',
    );
    final treinos = statsAsync.maybeWhen(
      data: (stats) => '${stats.treinosRealizados}',
      orElse: () => '—',
    );

    return Row(
      children: [
        Expanded(
          child: _StatBox(
            label: 'MAIOR SEQUÊNCIA',
            value: sequencia,
            icon: Icons.local_fire_department,
            iconColor: SystemPalette.gold,
          ),
        ),
        const SizedBox(width: SystemSpacing.sm),
        Expanded(child: _StatBox(label: 'TREINOS FEITOS', value: treinos)),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox(
      {required this.label, required this.value, this.icon, this.iconColor});

  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: SystemSpacing.md, vertical: SystemSpacing.sm),
      decoration: BoxDecoration(
        color:
            SystemPalette.surface2.withValues(alpha: SystemOpacities.surface2),
        border: Border.all(
            color: SystemPalette.primary
                .withValues(alpha: SystemOpacities.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: SystemTextStyles.label.copyWith(fontSize: 8)),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 16, color: iconColor ?? SystemPalette.foreground),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: SystemFonts.display,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: SystemPalette.foreground,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

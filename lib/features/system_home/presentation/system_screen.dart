import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/system_entrance.dart';
import '../../../design_system/system_motion.dart';
import '../../../design_system/system_scaffold.dart';
import '../../../design_system/system_spacing.dart';
import '../../rank_exam/presentation/rank_exam_providers.dart';
import '../../rank_exam/presentation/widgets/rank_exam_card.dart';
import 'widgets/home_daily_panel.dart';
import 'widgets/home_identity_panel.dart';
import 'widgets/home_penalty_banner.dart';
import 'widgets/home_today_panel.dart';
import 'widgets/home_week_panel.dart';

/// Tela Sistema/Home: o painel do Sistema. Ordem: cabeçalho do jogador
/// (avatar que abre o Perfil, nível, rank, XP e aviso de penalidade),
/// resumo da missão diária, "Hoje" (treino programado/descanso ou treino em
/// andamento), exame de rank (só se ativo) e faixa da semana com folgas.
///
/// Cada seção observa só o provider de que precisa. Os painéis entram com um
/// stagger discreto só na primeira montagem (as abas ficam num
/// `IndexedStack`, então trocar de aba e voltar não repete a entrada).
class SystemScreen extends ConsumerWidget {
  const SystemScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exameAtivo = ref.watch(rankExamProvider).valueOrNull != null;

    return SystemScaffold(
      title: 'SYSTEM',
      subtitle: 'PAINEL DO JOGADOR',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HomePenaltyBanner(),
          const SystemEntrance(child: HomeIdentityPanel()),
          const SizedBox(height: SystemSpacing.lg),
          const SystemEntrance(
            delay: SystemDurations.staggerStep,
            child: HomeDailyPanel(),
          ),
          const SizedBox(height: SystemSpacing.lg),
          SystemEntrance(
            delay: SystemDurations.staggerStep * 2,
            child: const HomeTodayPanel(),
          ),
          if (exameAtivo) ...[
            RankExamCard(
                compacto: true, onAbrir: () => context.go('/missions')),
            const SizedBox(height: SystemSpacing.lg),
          ],
          SystemEntrance(
            delay: SystemDurations.staggerStep * 3,
            child: const HomeWeekPanel(),
          ),
        ],
      ),
    );
  }
}

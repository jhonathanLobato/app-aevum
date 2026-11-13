import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/system_colors.dart';
import '../../../design_system/system_entrance.dart';
import '../../../design_system/system_motion.dart';
import '../../../design_system/system_scaffold.dart';
import '../../../design_system/system_spacing.dart';
import 'widgets/home_identity_panel.dart';
import 'widgets/home_mission_panel.dart';
import 'widgets/home_shortcuts_row.dart';
import '../../workouts/presentation/widgets/active_workout_card.dart';

/// Tela Sistema/Home, reconstruída na Fase 5 a partir de `index.tsx` do
/// ZIP do Lovable (ver `SystemLayout.tsx`/`Panel.tsx`/`XpBar.tsx`/
/// `RankBadge.tsx`/`SystemButton.tsx` como referências de componente).
///
/// Cada seção é um `ConsumerWidget` próprio que observa só o provider que
/// precisa (perfil, missões, treinos, histórico) — assim trocar de XP não
/// reconstrói o card de missão, por exemplo, e vice-versa.
///
/// Fase 9: os 5 painéis entram com um stagger discreto (`SystemEntrance` +
/// [SystemDurations.staggerStep]) só na primeira montagem desta tela — como
/// [SystemScreen] é `StatelessWidget` sem nenhum estado que force um rebuild
/// do zero, trocar de aba e voltar (`IndexedStack` das 5 abas, Fase 4)
/// reaproveita os mesmos elementos/estados e não repete a entrada.
class SystemScreen extends StatelessWidget {
  const SystemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SystemScaffold(
      title: 'SYSTEM',
      subtitle: 'PAINEL DO JOGADOR',
      actions: [
        IconButton(
          icon: const Icon(Icons.person_outline),
          iconSize: 18,
          color: SystemPalette.mutedForeground,
          tooltip: 'Perfil',
          onPressed: () => context.push('/profile'),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SystemEntrance(child: HomeIdentityPanel()),
          const SizedBox(height: SystemSpacing.lg),
          const SystemEntrance(
            delay: SystemDurations.staggerStep,
            child: HomeMissionPanel(),
          ),
          const SizedBox(height: SystemSpacing.lg),
          // O cartão já traz o próprio espaçamento inferior (e some sozinho
          // quando não há treino em andamento).
          const ActiveWorkoutCard(),
          SystemEntrance(
            delay: SystemDurations.staggerStep * 3,
            child: const HomeShortcutsRow(),
          ),
        ],
      ),
    );
  }
}

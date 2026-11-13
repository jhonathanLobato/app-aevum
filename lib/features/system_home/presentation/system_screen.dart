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

/// Tela Sistema/Home: painel do jogador (identidade, nível, rank e XP), a
/// missão atual, o treino em andamento (quando houver) e o atalho para o
/// histórico.
///
/// Cada seção é um `ConsumerWidget` próprio que observa só o provider que
/// precisa (perfil, missões, treino ativo) — assim trocar de XP não
/// reconstrói o card de missão, por exemplo, e vice-versa.
///
/// Os painéis entram com um stagger discreto (`SystemEntrance` +
/// [SystemDurations.staggerStep]) só na primeira montagem desta tela — como
/// [SystemScreen] é `StatelessWidget` sem nenhum estado que force um rebuild
/// do zero, trocar de aba e voltar (`IndexedStack` das 6 abas) reaproveita
/// os mesmos elementos/estados e não repete a entrada.
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

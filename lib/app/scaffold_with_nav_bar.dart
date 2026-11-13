import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design_system/system_navigation_bar.dart';
import '../features/daily/presentation/daily_providers.dart';
import '../features/missions/presentation/mission_providers.dart';
import '../features/achievements/presentation/achievement_notifier.dart';
import '../features/rank_exam/presentation/rank_exam_providers.dart';

/// Casca das 5 áreas principais (Sistema, Treinos, Atividades, Missões e
/// Status): o conteúdo da aba atual (um `IndexedStack` administrado pelo
/// `StatefulShellRoute` do go_router) embaixo, e a [SystemNavigationBar]
/// fixa abaixo dele.
///
/// Ao abrir o app, esta casca avalia os dias que passaram (penalidade da
/// missão diária), garante a missão semanal e sincroniza o exame de rank.
///
/// O índice selecionado mora só em [navigationShell] (estado do próprio
/// go_router).
class ScaffoldWithNavBar extends ConsumerStatefulWidget {
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = [
    SystemNavItem(icon: Icons.dashboard_rounded, label: 'SISTEMA'),
    SystemNavItem(icon: Icons.fitness_center_rounded, label: 'TREINOS'),
    SystemNavItem(icon: Icons.directions_run_rounded, label: 'ATIVIDADES'),
    SystemNavItem(icon: Icons.assignment_rounded, label: 'MISSÕES'),
    SystemNavItem(icon: Icons.monitor_heart_rounded, label: 'STATUS'),
  ];

  @override
  ConsumerState<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends ConsumerState<ScaffoldWithNavBar> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _aoAbrir());
  }

  Future<void> _aoAbrir() async {
    try {
      await ref.read(dailyRepositoryProvider).processarVirada();
      await ref.read(missionRepositoryProvider).ensureRecurringMissions();
      if (mounted) await sincronizarExame(context, ref);
      if (mounted) await conferirConquistas(context, ref);
    } catch (_) {
      // Rotina de abertura nunca deve impedir o uso do app.
    }
  }

  @override
  Widget build(BuildContext context) {
    final shell = widget.navigationShell;
    return Scaffold(
      body: shell,
      bottomNavigationBar: SystemNavigationBar(
        items: ScaffoldWithNavBar._items,
        currentIndex: shell.currentIndex,
        onTap: (index) => shell.goBranch(
          index,
          // Tocar na aba já ativa volta pro topo dela em vez de empilhar
          // de novo; tocar numa aba diferente preserva o estado dela.
          initialLocation: index == shell.currentIndex,
        ),
      ),
    );
  }
}

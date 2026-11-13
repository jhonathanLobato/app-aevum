import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design_system/system_navigation_bar.dart';

/// Casca das 6 áreas principais: o conteúdo da aba atual (um `IndexedStack`
/// administrado pelo `StatefulShellRoute` do go_router) embaixo, e a
/// [SystemNavigationBar] fixa abaixo dele.
///
/// O índice selecionado mora só em [navigationShell] (estado do próprio
/// go_router) — esta casca é a única instância da barra de navegação; as 5
/// telas não sabem da existência umas das outras nem duplicam esse índice.
class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = [
    SystemNavItem(icon: Icons.dashboard_rounded, label: 'SISTEMA'),
    SystemNavItem(icon: Icons.fitness_center_rounded, label: 'TREINOS'),
    SystemNavItem(icon: Icons.directions_run_rounded, label: 'ATIVIDADES'),
    SystemNavItem(icon: Icons.assignment_rounded, label: 'MISSÕES'),
    SystemNavItem(icon: Icons.monitor_heart_rounded, label: 'STATUS'),
    SystemNavItem(icon: Icons.emoji_events_rounded, label: 'CONQUISTAS'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: SystemNavigationBar(
        items: _items,
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          // Tocar na aba já ativa volta pro topo dela em vez de empilhar
          // de novo; tocar numa aba diferente preserva o estado dela.
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

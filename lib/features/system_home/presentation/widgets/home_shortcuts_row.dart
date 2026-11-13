import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/system_button.dart';
import '../../../../design_system/system_colors.dart';

/// Atalho discreto pra tela secundária que não tem aba própria. Só o
/// Histórico fica aqui — Exercícios fica na aba Treinos e o Perfil tem seu
/// próprio ícone no cabeçalho ([SystemScreen]). Variante `ghost`
/// (discreta) de propósito, pra não competir visualmente com o CTA
/// principal da missão.
class HomeShortcutsRow extends StatelessWidget {
  const HomeShortcutsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SystemButton(
      label: 'Histórico',
      variant: SystemButtonVariant.ghost,
      icon: const Icon(Icons.history_rounded,
          size: 16, color: SystemPalette.foreground),
      onPressed: () => context.push('/history'),
    );
  }
}

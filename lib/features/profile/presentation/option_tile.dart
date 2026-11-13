import 'package:flutter/material.dart';

import '../../../design_system/system_colors.dart';
import '../../../design_system/system_effects.dart';

/// Opção selecionável (avatar, classe, tema, unidade...): borda e glow ciano
/// quando ativa.
class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
    required this.semanticLabel,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? SystemPalette.primary.withValues(alpha: 0.15)
                : SystemPalette.surface2
                    .withValues(alpha: SystemOpacities.surface2),
            border: Border.all(
              color: selected
                  ? SystemPalette.primary.withValues(alpha: 0.7)
                  : SystemPalette.primary
                      .withValues(alpha: SystemOpacities.border),
            ),
            boxShadow: selected ? SystemShadows.glowPrimary : null,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Rótulo de opção em texto (para usar dentro de [OptionTile]).
class OptionLabel extends StatelessWidget {
  const OptionLabel(this.texto, {super.key, required this.selected});

  final String texto;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto.toUpperCase(),
      style: TextStyle(
        fontFamily: 'Rajdhani',
        fontWeight: FontWeight.w600,
        fontSize: 11,
        letterSpacing: 1,
        color: selected ? SystemPalette.primary : SystemPalette.mutedForeground,
      ),
    );
  }
}

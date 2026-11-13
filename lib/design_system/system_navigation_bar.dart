import 'package:flutter/material.dart';

import 'system_clippers.dart';
import 'system_colors.dart';
import 'system_effects.dart';
import 'system_geometry.dart';
import 'system_motion.dart';
import 'system_panel.dart';
import 'system_spacing.dart';
import 'system_text_styles.dart';

/// Um item da [SystemNavigationBar]: ícone + label.
class SystemNavItem {
  const SystemNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Barra de navegação inferior do sistema, direto de `SystemNav.tsx`.
///
/// Reaproveita os tokens/clippers das Fases 1-2: corte diagonal de 6px
/// ([SystemCutSizes.small]) na caixa do ícone, glow ciano
/// ([SystemShadows.glowPrimary]) no item ativo e a linha tecnológica
/// ([SystemDivider]) no topo da barra.
///
/// Não guarda estado de navegação — [currentIndex]/[onTap] vêm de fora (a
/// fonte central de estado é o `StatefulShellRoute` do go_router). Nenhuma
/// tela deve instanciar sua própria cópia desta barra.
///
/// Diferenças do Lovable: sem `backdrop-blur-xl` (a barra fica num slot
/// fixo do `Scaffold`, nunca sobre conteúdo rolando por baixo, então o
/// blur não agregaria nada visível ao custo de o calcular); o indicador
/// luminoso da aba ativa, que no CSS flutua 9px acima da barra via
/// `position: absolute`, foi reposicionado para dentro da própria barra
/// (não há como pintar fora dos limites do slot `bottomNavigationBar` do
/// `Scaffold` sem truques arriscados) — o efeito "marcador aceso acima do
/// ícone" continua o mesmo, só mais próximo do ícone.
class SystemNavigationBar extends StatelessWidget {
  const SystemNavigationBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<SystemNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SystemPalette.background.withValues(alpha: 0.85),
        border: Border(
          top: BorderSide(
            color:
                SystemPalette.primary.withValues(alpha: SystemOpacities.border),
            width: SystemBorders.hairline,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SystemDivider(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SystemSpacing.sm,
                vertical: SystemSpacing.sm,
              ),
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: _SystemNavItem(
                        item: items[i],
                        active: i == currentIndex,
                        onTap: () => onTap(i),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemNavItem extends StatefulWidget {
  const _SystemNavItem(
      {required this.item, required this.active, required this.onTap});

  final SystemNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_SystemNavItem> createState() => _SystemNavItemState();
}

class _SystemNavItemState extends State<_SystemNavItem> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.active ? SystemPalette.primary : SystemPalette.mutedForeground;

    return Semantics(
      button: true,
      selected: widget.active,
      label: widget.item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: SystemDurations.pressDecoration,
          curve: SystemCurves.press,
          color: _pressed
              ? SystemPalette.primary.withValues(alpha: 0.05)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: SystemSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedOpacity(
                duration: SystemDurations.pressDecoration,
                opacity: widget.active ? 1 : 0,
                child: Container(
                  height: 2,
                  margin:
                      const EdgeInsets.symmetric(horizontal: SystemSpacing.sm),
                  decoration: const BoxDecoration(
                    color: SystemPalette.primary,
                    boxShadow: [
                      BoxShadow(color: SystemPalette.primary, blurRadius: 10)
                    ],
                  ),
                ),
              ),
              const SizedBox(height: SystemSpacing.xs),
              ClipPath(
                clipper: const DiagonalCutCornersClipper(SystemCutSizes.small),
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: widget.active
                        ? SystemPalette.primary.withValues(alpha: 0.15)
                        : Colors.transparent,
                    border: Border.all(
                      color: widget.active
                          ? SystemPalette.primary.withValues(alpha: 0.6)
                          : Colors.transparent,
                    ),
                    boxShadow: widget.active ? SystemShadows.glowPrimary : null,
                  ),
                  child: Icon(widget.item.icon, size: 18, color: color),
                ),
              ),
              const SizedBox(height: SystemSpacing.xs),
              // Com 6 abas o rótulo mais longo ("CONQUISTAS"/"ATIVIDADES") não
              // cabe em telas estreitas: reduz a fonte em vez de cortar.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.item.label,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: SystemFonts.display,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.12, // tracking-[0.14em] de 8px
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

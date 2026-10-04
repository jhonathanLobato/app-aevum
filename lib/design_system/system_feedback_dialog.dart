import 'package:flutter/material.dart';

import 'system_button.dart';
import 'system_clippers.dart';
import 'system_effects.dart';
import 'system_geometry.dart';
import 'system_motion.dart';
import 'system_spacing.dart';
import 'system_text_styles.dart';

/// Força visual do feedback — Fase 9, seção 16 (hierarquia de feedback):
/// série registrada e exercício avançado usam feedback pequeno embutido na
/// própria tela (sem diálogo); PR e missão concluída usam [medium]; conquista
/// desbloqueada usa [strong]; LEVEL UP (Fase 10, cinemático) fica acima de
/// tudo isso.
enum SystemFeedbackIntensity { medium, strong }

/// Diálogo de feedback do sistema — base visual compartilhada por PR
/// detectado, missão concluída, conquista desbloqueada e level up (Fase 9).
/// Substitui os `AlertDialog`s genéricos que cada um usava antes: mesmo
/// painel de cortes diagonais, cor de destaque e entrada (fade + escala
/// curta) para os quatro, só variando ícone/cor/intensidade — exatamente o
/// tipo de consistência pedido na seção 21.
///
/// Continua sendo um `Dialog`/`showDialog` por baixo (o fluxo de
/// confirmação via `Navigator.pop` que as telas já usam não muda), só a
/// apresentação interna foi redesenhada.
class SystemFeedbackDialog extends StatelessWidget {
  const SystemFeedbackDialog({
    super.key,
    required this.icon,
    required this.title,
    required this.accentColor,
    required this.child,
    this.intensity = SystemFeedbackIntensity.medium,
  });

  final IconData icon;
  final String title;
  final Color accentColor;
  final Widget child;
  final SystemFeedbackIntensity intensity;

  @override
  Widget build(BuildContext context) {
    final forte = intensity == SystemFeedbackIntensity.strong;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: SystemDialogEntrance(
        child: ClipPath(
          clipper: const DiagonalCutCornersClipper(SystemCutSizes.panel),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: SystemGradients.panel,
              border: Border.all(
                color: accentColor.withValues(alpha: 0.6),
                width: SystemBorders.hairline,
              ),
              boxShadow: SystemShadows.coloredGlow(
                accentColor.withValues(alpha: forte ? 0.55 : 0.35),
                blurRadius: forte ? 36 : 24,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(SystemSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: forte ? 56 : 48,
                      height: forte ? 56 : 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor.withValues(alpha: 0.15),
                        border: Border.all(
                            color: accentColor.withValues(alpha: 0.6)),
                        boxShadow: SystemShadows.coloredGlow(accentColor,
                            blurRadius: forte ? 28 : 18),
                      ),
                      child:
                          Icon(icon, color: accentColor, size: forte ? 28 : 24),
                    ),
                  ),
                  const SizedBox(height: SystemSpacing.md),
                  Text(
                    title.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: SystemFonts.display,
                      fontSize: forte ? 18 : 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.4,
                      color: accentColor,
                      shadows: [
                        Shadow(
                            color: accentColor.withValues(alpha: 0.7),
                            blurRadius: 12),
                      ],
                    ),
                  ),
                  const SizedBox(height: SystemSpacing.lg),
                  child,
                  const SizedBox(height: SystemSpacing.lg),
                  SystemButton(
                    label: 'OK',
                    variant: SystemButtonVariant.ghost,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Entrada do diálogo em si (fade + escala curta) — não usa [SystemEntrance]
/// porque um diálogo não "rebuilda" no mesmo sentido que um painel de tela:
/// ele é criado uma vez por `showDialog` e descartado ao fechar, então o
/// `State` já nasce e morre exatamente quando deveria.
class SystemDialogEntrance extends StatefulWidget {
  const SystemDialogEntrance({super.key, required this.child});

  final Widget child;

  @override
  State<SystemDialogEntrance> createState() => SystemDialogEntranceState();
}

class SystemDialogEntranceState extends State<SystemDialogEntrance> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;

    return AnimatedScale(
      scale: _visible ? 1 : 0.92,
      duration: SystemDurations.panelIn,
      curve: SystemCurves.panelIn,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: SystemDurations.panelIn,
        curve: SystemCurves.panelIn,
        child: widget.child,
      ),
    );
  }
}

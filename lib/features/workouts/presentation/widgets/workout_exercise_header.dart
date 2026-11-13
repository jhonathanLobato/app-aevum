import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/system_colors.dart';
import '../../../../design_system/system_motion.dart';
import '../../../../design_system/system_panel.dart';
import '../../../../design_system/system_spacing.dart';
import '../../../../design_system/system_stat_box.dart';
import '../../../../design_system/system_text_styles.dart';
import '../workout_session_providers.dart';
import 'workout_exercise_progress_track.dart';

/// Painel do topo do carrossel — contador, navegação anterior/próximo,
/// nome + grupo muscular do exercício atual, PR/meta reais quando
/// existirem, e a trilha de progresso entre exercícios (não é XP, ver
/// [WorkoutExerciseProgressTrack]). Direto de `treinos.tsx`.
class WorkoutExerciseHeader extends ConsumerWidget {
  const WorkoutExerciseHeader({
    super.key,
    required this.exerciseId,
    required this.exerciseNome,
    required this.grupoMuscular,
    required this.index,
    required this.total,
    required this.hasSeries,
    required this.seriesAlvo,
    required this.repeticoesAlvo,
    required this.onAnterior,
    required this.onProximo,
  });

  final int exerciseId;
  final String exerciseNome;
  final String grupoMuscular;
  final int index;
  final int total;
  final List<bool> hasSeries;
  final int? seriesAlvo;
  final int? repeticoesAlvo;
  final VoidCallback? onAnterior;
  final VoidCallback? onProximo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // "PR ATUAL" = maior carga já registrada no exercício (inclui a
    // referência do primeiro treino, que não gera um PR formal).
    final historicoAsync = ref.watch(exerciseHistoryProvider(exerciseId));

    final prAtual = historicoAsync.maybeWhen(
      data: (series) {
        if (series.isEmpty) return null;
        return series.map((s) => s.carga).reduce((a, b) => a > b ? a : b);
      },
      orElse: () => null,
    );

    final meta = (seriesAlvo != null && repeticoesAlvo != null)
        ? '$seriesAlvo×$repeticoesAlvo'
        : null;

    return SystemPanel(
      glow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _NavButton(
                icon: Icons.chevron_left,
                onPressed: onAnterior,
                semanticLabel: 'Exercício anterior',
              ),
              Expanded(
                child: Column(
                  children: [
                    // Troca com uma transição curta ao avançar/voltar de
                    // exercício (Fase 9, seção 12) — é só a contagem
                    // mudando, nenhum texto implica que o exercício foi
                    // "salvo": "Finalizar exercício" continua sendo apenas
                    // navegação do carrossel, sem estado persistido.
                    AnimatedSwitcher(
                      duration: MediaQuery.of(context).disableAnimations
                          ? Duration.zero
                          : SystemDurations.pressDecoration,
                      switchInCurve: SystemCurves.easeOut,
                      switchOutCurve: SystemCurves.easeOut,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, -0.3),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: Text(
                        '${(index + 1).toString().padLeft(2, '0')} / '
                        '${total.toString().padLeft(2, '0')}',
                        key: ValueKey(index),
                        style: const TextStyle(
                          fontFamily: SystemFonts.display,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3.6, // tracking-[0.3em] de 12px
                          color: SystemPalette.primary,
                          shadows: SystemTextStyles.glowPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: SystemSpacing.xs),
                    Text(
                      exerciseNome.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: SystemFonts.display,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        color: SystemPalette.foreground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      grupoMuscular.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SystemTextStyles.label.copyWith(fontSize: 8.8),
                    ),
                  ],
                ),
              ),
              _NavButton(
                icon: Icons.chevron_right,
                onPressed: onProximo,
                semanticLabel: 'Próximo exercício',
              ),
            ],
          ),
          if (prAtual != null || meta != null) ...[
            const SizedBox(height: SystemSpacing.md),
            Row(
              children: [
                if (prAtual != null)
                  Expanded(
                    child: SystemStatBox(
                      label: 'PR ATUAL',
                      value: '${prAtual.toStringAsFixed(1)} KG',
                      icon: Icons.emoji_events_outlined,
                      iconColor: SystemPalette.gold,
                    ),
                  ),
                if (prAtual != null && meta != null)
                  const SizedBox(width: SystemSpacing.sm),
                if (meta != null)
                  Expanded(child: SystemStatBox(label: 'META', value: meta)),
              ],
            ),
          ],
          const SizedBox(height: SystemSpacing.md),
          WorkoutExerciseProgressTrack(
            total: total,
            currentIndex: index,
            hasSeries: hasSeries,
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton(
      {required this.icon,
      required this.onPressed,
      required this.semanticLabel});

  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Opacity(
        opacity: enabled ? 1 : 0.3,
        child: InkWell(
          onTap: onPressed,
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: SystemPalette.surface2
                  .withValues(alpha: SystemOpacities.surface2),
              border: Border.all(
                  color: SystemPalette.primary
                      .withValues(alpha: SystemOpacities.border)),
            ),
            child: Icon(icon,
                size: 18,
                color: SystemPalette.foreground.withValues(alpha: 0.85)),
          ),
        ),
      ),
    );
  }
}

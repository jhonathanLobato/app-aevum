import 'package:flutter/material.dart';

import '../../../../design_system/system_clippers.dart';
import '../../../../design_system/system_colors.dart';
import '../../../../design_system/system_effects.dart';
import '../../../../design_system/system_panel.dart';
import '../../../../design_system/system_progress_bar.dart';
import '../../../../design_system/system_spacing.dart';
import '../../../../design_system/system_text_styles.dart';
import '../../domain/achievement.dart';

/// 3 estados reais:
/// - DESBLOQUEADA: `Achievement.status == desbloqueada` (persistido).
/// - DISPONÍVEL: ainda bloqueada, mas com progresso > 0 — derivado, não
///   persistido (uma conquista progressiva "3/10" já em andamento).
/// - BLOQUEADA: ainda bloqueada e sem nenhum progresso (ou binária, nunca
///   "disponível" por natureza).
enum _EstadoVisual { bloqueada, disponivel, desbloqueada }

/// Card de conquista, direto de `conquistas.tsx` — hexágono (reaproveita o
/// [HexagonClipper] da Fase 2, mesma geometria do [RankBadge]), título,
/// descrição, progresso real quando aplicável, e o rótulo de estado.
///
/// Diferença deliberada do protótipo: lá, uma conquista bloqueada esconde
/// título/descrição ("???"/"Requisito oculto"). Aqui sempre mostramos os
/// dois — nosso catálogo não é secreto (o CLAUDE.md já documenta todas as
/// conquistas abertamente), e esconder o nome impediria mostrar progresso
/// real ("3/10 treinos" não faz sentido sem revelar o que são os 10).
class AchievementCard extends StatelessWidget {
  const AchievementCard({
    super.key,
    required this.achievement,
    this.progresso,
  });

  final Achievement achievement;

  /// (atual, objetivo), quando a conquista é contável — ver
  /// `progressoDaConquista`. `null` pra conquistas binárias.
  final (int, int)? progresso;

  _EstadoVisual get _estado {
    if (achievement.status == AchievementStatus.desbloqueada) {
      return _EstadoVisual.desbloqueada;
    }
    if (progresso != null && progresso!.$1 > 0) return _EstadoVisual.disponivel;
    return _EstadoVisual.bloqueada;
  }

  @override
  Widget build(BuildContext context) {
    final estado = _estado;
    final cor = switch (estado) {
      _EstadoVisual.desbloqueada => SystemPalette.gold,
      _EstadoVisual.disponivel => SystemPalette.primary,
      _EstadoVisual.bloqueada => SystemPalette.mutedForeground,
    };
    final rotulo = switch (estado) {
      _EstadoVisual.desbloqueada => 'DESBLOQUEADA',
      _EstadoVisual.disponivel => 'DISPONÍVEL',
      _EstadoVisual.bloqueada => 'BLOQUEADA',
    };

    return SystemPanel(
      glow: estado == _EstadoVisual.desbloqueada,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: SizedBox(
              width: 56,
              height: 56,
              child: ClipPath(
                clipper: const HexagonClipper(),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: cor.withValues(
                        alpha: estado == _EstadoVisual.bloqueada ? 0.08 : 0.15),
                    border: Border.all(color: cor.withValues(alpha: 0.5)),
                    boxShadow: estado == _EstadoVisual.desbloqueada
                        ? SystemShadows.coloredGlow(cor)
                        : null,
                  ),
                  child: Center(
                    child: Icon(
                      estado == _EstadoVisual.bloqueada
                          ? Icons.lock_outline
                          : _iconeDe(achievement.icone),
                      size: 22,
                      color: estado == _EstadoVisual.bloqueada
                          ? SystemPalette.mutedForeground
                          : SystemPalette.foreground,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: SystemSpacing.sm),
          Text(
            achievement.nome,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: SystemTextStyles.displaySmall.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            achievement.descricao,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: SystemTextStyles.bodySmall,
          ),
          if (progresso != null) ...[
            const SizedBox(height: SystemSpacing.sm),
            SystemProgressBar(value: progresso!.$1, max: progresso!.$2),
            const SizedBox(height: 2),
            Text(
              '${progresso!.$1} / ${progresso!.$2}',
              textAlign: TextAlign.center,
              style: SystemTextStyles.bodySmall,
            ),
          ],
          const SizedBox(height: SystemSpacing.sm),
          Container(
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(
                      color: SystemPalette.primary
                          .withValues(alpha: SystemOpacities.border))),
            ),
            padding: const EdgeInsets.only(top: SystemSpacing.xs),
            child: Text(
              rotulo,
              textAlign: TextAlign.center,
              style: SystemTextStyles.label.copyWith(fontSize: 8, color: cor),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconeDe(String nome) {
    switch (nome) {
      case 'flag':
        return Icons.flag;
      case 'trending_up':
        return Icons.trending_up;
      case 'military_tech':
        return Icons.military_tech;
      case 'bolt':
        return Icons.bolt;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'wb_twilight':
        return Icons.wb_twilight;
      case 'bedtime':
        return Icons.bedtime;
      case 'timer':
        return Icons.timer;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'directions_run':
        return Icons.directions_run;
      case 'explore':
        return Icons.explore;
      case 'sports_mma':
        return Icons.sports_mma;
      case 'event_available':
        return Icons.event_available;
      case 'monitor_weight':
        return Icons.monitor_weight;
      default:
        return Icons.emoji_events;
    }
  }
}

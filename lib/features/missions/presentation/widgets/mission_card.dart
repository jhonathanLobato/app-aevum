import 'package:flutter/material.dart';

import '../../../../design_system/system_colors.dart';
import '../../../../design_system/system_geometry.dart';
import '../../../../design_system/system_panel.dart';
import '../../../../design_system/system_progress_bar.dart';
import '../../../../design_system/system_spacing.dart';
import '../../../../design_system/system_text_styles.dart';
import '../../../profile/domain/level_curve.dart';
import '../../domain/mission.dart';

/// Matriz de dessaturação (preserva luminância) — aproxima o `grayscale`
/// do CSS pra missões bloqueadas por rank, sem precisar de nenhum pacote
/// de efeitos de imagem.
const _grayscaleMatrix = <double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0, //
];

/// Card de missão, direto de `missoes.tsx`. Três estados visuais reais:
/// ativa (padrão), concluída (ícone de check, destaque verde) e bloqueada
/// por rank (ícone de cadeado, dessaturado — ver [Mission.minimumRank]).
/// "Bloqueada" não é alcançável com dados de produção hoje (nenhuma
/// missão real tem `minimumRank` preenchido — Fase 7, seção 8), mas o
/// caminho de código já existe e é testado com um [Mission] construído à
/// mão.
class MissionCard extends StatelessWidget {
  const MissionCard({super.key, required this.mission, required this.userRank});

  final Mission mission;

  /// Rank atual do jogador, pra decidir se a missão está bloqueada.
  final String userRank;

  bool get _concluida => mission.status == MissionStatus.concluida;

  bool get _bloqueada =>
      mission.minimumRank != null &&
      !rankAtende(userRank, mission.minimumRank!);

  @override
  Widget build(BuildContext context) {
    final card = SystemPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TipoBadge(tipo: mission.tipo),
                    const SizedBox(height: SystemSpacing.sm),
                    Text(mission.nome, style: SystemTextStyles.displaySmall),
                    const SizedBox(height: 2),
                    Text(
                      mission.descricao,
                      style: SystemTextStyles.body
                          .copyWith(color: SystemPalette.mutedForeground),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: SystemSpacing.sm),
              _StatusBox(
                  concluida: _concluida,
                  bloqueada: _bloqueada,
                  mission: mission),
            ],
          ),
          if (!_bloqueada) ...[
            const SizedBox(height: SystemSpacing.md),
            SystemProgressBar(value: mission.progresso, max: mission.objetivo),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${mission.progresso} / ${mission.objetivo}',
                style: SystemTextStyles.bodySmall,
              ),
            ),
          ],
          const SizedBox(height: SystemSpacing.md),
          const _HairlineDivider(),
          const SizedBox(height: SystemSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('RECOMPENSA',
                  style: SystemTextStyles.label.copyWith(fontSize: 8)),
              Text(
                _bloqueada ? '???' : '+${mission.recompensaXp} XP',
                style: SystemTextStyles.label
                    .copyWith(fontSize: 9.6, color: SystemPalette.gold),
              ),
            ],
          ),
        ],
      ),
    );

    if (!_bloqueada) return card;

    return Opacity(
      opacity: 0.55,
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix(_grayscaleMatrix),
        child: card,
      ),
    );
  }
}

class _TipoBadge extends StatelessWidget {
  const _TipoBadge({required this.tipo});

  final MissionType tipo;

  @override
  Widget build(BuildContext context) {
    final Color cor;
    final String label;
    switch (tipo) {
      case MissionType.diaria:
        cor = SystemPalette.primary;
        label = 'MISSÃO DIÁRIA';
      case MissionType.semanal:
        cor = SystemPalette.violet;
        label = 'MISSÃO SEMANAL';
      case MissionType.desafio:
        cor = SystemPalette.gold;
        label = 'MISSÃO DESAFIO';
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: SystemSpacing.sm, vertical: 2),
      decoration:
          BoxDecoration(border: Border.all(color: cor.withValues(alpha: 0.5))),
      child: Text(label,
          style: SystemTextStyles.label.copyWith(fontSize: 8, color: cor)),
    );
  }
}

class _StatusBox extends StatelessWidget {
  const _StatusBox(
      {required this.concluida,
      required this.bloqueada,
      required this.mission});

  final bool concluida;
  final bool bloqueada;
  final Mission mission;

  @override
  Widget build(BuildContext context) {
    final Color cor;
    final Widget conteudo;
    if (concluida) {
      cor = SystemPalette.success;
      conteudo = Icon(Icons.check, size: 16, color: cor);
    } else if (bloqueada) {
      cor = SystemPalette.mutedForeground;
      conteudo = Icon(Icons.lock_outline, size: 16, color: cor);
    } else {
      cor = SystemPalette.primary;
      final percentual = (mission.progressoFracao * 100).round();
      conteudo = Text(
        '$percentual%',
        style: TextStyle(
          fontFamily: SystemFonts.display,
          fontSize: 9.6,
          fontWeight: FontWeight.bold,
          color: cor,
        ),
      );
    }

    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cor.withValues(alpha: concluida || !bloqueada ? 0.12 : 0),
        border: Border.all(color: cor.withValues(alpha: 0.5)),
      ),
      child: conteudo,
    );
  }
}

class _HairlineDivider extends StatelessWidget {
  const _HairlineDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: SystemBorders.hairline,
      color: SystemPalette.primary.withValues(alpha: SystemOpacities.border),
    );
  }
}

import 'dart:async';
import 'dart:math' show cos, pi, sin;

import 'package:flutter/material.dart';

import '../../../design_system/rank_badge.dart';
import '../../../design_system/system_button.dart';
import '../../../design_system/system_colors.dart';
import '../../../design_system/system_motion.dart';
import '../../../design_system/system_spacing.dart';
import '../../../design_system/system_text_styles.dart';

/// Apresentação de LEVEL UP (Fase 10) — o feedback mais importante do
/// Aevum, deliberadamente acima de PR/missão/conquista (Fase 9) em
/// intensidade visual. Baseado em `LevelUpOverlay.tsx` do Lovable, adaptado
/// pra mobile: tela cheia, fundo escurecido, anéis expandindo e partículas
/// leves num único `CustomPainter` (não um `AnimationController` por
/// elemento), sem `BackdropFilter`.
///
/// A detecção de level up e de mudança de rank continua inteiramente do
/// repositório (`ProfileRepository.addXp`, já existente) — [nivelAnterior],
/// [novoNivel], [rankAnterior] e [novoRank] só são exibidos aqui, nunca
/// recalculados.
Future<void> showLevelUpOverlay(
  BuildContext context, {
  required int nivelAnterior,
  required int novoNivel,
  String? rankAnterior,
  String? novoRank,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fechar',
    barrierColor: Colors.black87,
    transitionDuration: SystemDurations.panelIn,
    pageBuilder: (context, _, __) => LevelUpOverlay(
      nivelAnterior: nivelAnterior,
      novoNivel: novoNivel,
      rankAnterior: rankAnterior,
      novoRank: novoRank,
    ),
    transitionBuilder: (context, animation, _, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

class LevelUpOverlay extends StatefulWidget {
  const LevelUpOverlay({
    super.key,
    required this.nivelAnterior,
    required this.novoNivel,
    this.rankAnterior,
    this.novoRank,
  });

  final int nivelAnterior;
  final int novoNivel;

  /// Só exibidos quando realmente diferentes — ver `XpGainResult.subiuDeRank`.
  /// `null`/iguais significa "sem mudança de rank": nada é inventado aqui.
  final String? rankAnterior;
  final String? novoRank;

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _burstController;
  late final Animation<double> _burstCurva;

  /// `null` sob Reduced Motion — nem chega a existir, então não há
  /// `Ticker` nenhum rodando pros anéis/partículas.
  AnimationController? _loopController;

  Timer? _autoCloseTimer;

  bool get _mudouDeRank =>
      widget.rankAnterior != null &&
      widget.novoRank != null &&
      widget.rankAnterior != widget.novoRank;

  @override
  void initState() {
    super.initState();
    final reduceMotion = WidgetsBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations;

    _burstController = AnimationController(
      vsync: this,
      duration: reduceMotion ? Duration.zero : SystemDurations.levelBurst,
    )..forward();
    _burstCurva = CurvedAnimation(
        parent: _burstController, curve: SystemCurves.levelBurst);

    if (!reduceMotion) {
      _loopController = AnimationController(
        vsync: this,
        duration: SystemDurations.ringExpand,
      )..repeat();
    }

    // O usuário nunca fica preso: fecha sozinho depois de alguns segundos,
    // mesmo sob Reduced Motion (que só remove a animação, não a função).
    _autoCloseTimer = Timer(SystemDurations.levelUpAutoClose, _fechar);
  }

  void _fechar() {
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    _burstController.dispose();
    _loopController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _fechar,
        child: SizedBox.expand(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_loopController != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _loopController!,
                      builder: (context, _) => CustomPaint(
                        painter: _LevelUpFxPainter(t: _loopController!.value),
                      ),
                    ),
                  ),
                ),
              ScaleTransition(
                scale: _burstCurva,
                child: FadeTransition(
                  opacity: _burstCurva,
                  child: _Conteudo(
                    nivelAnterior: widget.nivelAnterior,
                    novoNivel: widget.novoNivel,
                    novoRank: _mudouDeRank ? widget.novoRank : null,
                    onFechar: _fechar,
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

class _Conteudo extends StatelessWidget {
  const _Conteudo({
    required this.nivelAnterior,
    required this.novoNivel,
    required this.novoRank,
    required this.onFechar,
  });

  final int nivelAnterior;
  final int novoNivel;
  final String? novoRank;
  final VoidCallback onFechar;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'LEVEL UP',
          style: TextStyle(
            fontFamily: SystemFonts.display,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 8,
            color: SystemPalette.primary,
            shadows: SystemTextStyles.glowPrimary,
          ),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'LV. $nivelAnterior',
              style: SystemTextStyles.label.copyWith(fontSize: 13),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Icon(Icons.arrow_forward,
                  color: SystemPalette.primary, size: 22),
            ),
            Text(
              'LV. $novoNivel',
              style: const TextStyle(
                fontFamily: SystemFonts.display,
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: SystemPalette.primary,
                shadows: SystemTextStyles.glowPrimary,
              ),
            ),
          ],
        ),
        if (novoRank != null) ...[
          const SizedBox(height: 28),
          Text('NOVO RANK',
              style: SystemTextStyles.label.copyWith(fontSize: 10)),
          const SizedBox(height: SystemSpacing.sm),
          RankBadge(rank: novoRank!, size: 64),
        ],
        const SizedBox(height: 36),
        SystemButton(
          label: 'Continuar',
          variant: SystemButtonVariant.action,
          onPressed: onFechar,
        ),
      ],
    );
  }
}

/// Anéis expandindo + partículas leves, tudo num único `CustomPainter` —
/// mais barato no Android do que um widget animado por elemento. Quantidade
/// pequena de propósito (3 anéis, 8 partículas).
class _LevelUpFxPainter extends CustomPainter {
  const _LevelUpFxPainter({required this.t});

  final double t;

  static const _aneis = 3;
  static const _particulas = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final raioMaximo = size.shortestSide * 0.42;

    for (var i = 0; i < _aneis; i++) {
      final fase = (t + i / _aneis) % 1.0;
      final raio = raioMaximo * fase;
      final opacidade = (1 - fase) * 0.45;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = (i.isEven ? SystemPalette.primary : SystemPalette.violet)
            .withValues(alpha: opacidade);
      canvas.drawCircle(center, raio, paint);
    }

    for (var i = 0; i < _particulas; i++) {
      final fase = (t + i / _particulas) % 1.0;
      final angulo = (2 * pi * i) / _particulas;
      final distancia = raioMaximo * 0.55 * fase;
      final dx = center.dx + cos(angulo) * distancia;
      final dy =
          center.dy + sin(angulo) * distancia - (raioMaximo * 0.5 * fase);
      final opacidade = 1 - fase;
      final paint = Paint()
        ..color = SystemPalette.foreground.withValues(alpha: opacidade * 0.6);
      canvas.drawCircle(Offset(dx, dy), 2.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LevelUpFxPainter oldDelegate) =>
      oldDelegate.t != t;
}

import 'package:flutter/material.dart';

import 'system_colors.dart';
import 'system_motion.dart';

/// O ponto + "ONLINE" do [SystemHeader], agora com um pulso sutil (`sys-pulse`,
/// Fase 9) — uma respiração lenta de opacidade, nunca de tamanho.
///
/// É uma das poucas animações contínuas autorizadas no app, e fica isolada
/// neste widget pequeno de propósito: só o ponto e o texto repintam a cada
/// frame do pulso, nunca o resto do cabeçalho (que não depende de
/// `AnimationController` nenhum). Usa `SingleTickerProviderStateMixin`, o
/// que automaticamente respeita o `TickerMode` do `IndexedStack` das 6 abas
/// (Fase 4/go_router): quando esta aba não está em foco, o `Offstage` +
/// `TickerMode(enabled: false)` que o próprio `StatefulShellRoute.indexedStack`
/// já aplica pausa este ticker sozinho, sem nenhum código extra aqui.
///
/// Respeita `MediaQuery.disableAnimations`: com Reduced Motion ativo, o ponto
/// fica estático na opacidade máxima.
class SystemOnlineIndicator extends StatefulWidget {
  const SystemOnlineIndicator({super.key});

  @override
  State<SystemOnlineIndicator> createState() => _SystemOnlineIndicatorState();
}

class _SystemOnlineIndicatorState extends State<SystemOnlineIndicator>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: SystemDurations.sysPulse,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return const _OnlineDot(opacity: 1);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Respiração entre 55% e 100% — nunca pisca, nunca muda de tamanho.
        final opacity = 0.55 + (_controller.value * 0.45);
        return _OnlineDot(opacity: opacity);
      },
    );
  }
}

/// Só o ponto — o rótulo "ONLINE" ao lado continua estático em
/// [SystemHeader], o pedido da Fase 9 é só pro indicador luminoso.
class _OnlineDot extends StatelessWidget {
  const _OnlineDot({required this.opacity});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: SystemPalette.success,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

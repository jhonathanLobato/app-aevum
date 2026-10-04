import 'package:flutter/material.dart';

import 'system_motion.dart';

/// Versão leve de `panel-in` (Fase 9): opacidade 0→1 + um pequeno translate
/// vertical quando o widget é montado de verdade pela primeira vez — não a
/// cada rebuild.
///
/// Isso funciona porque a animação mora no `State` deste widget: ela toca
/// uma vez em [initState] e fica parada depois disso. Rebuilds do pai (XP
/// mudando, stream emitindo um novo valor, timer do treino) só atualizam as
/// propriedades do [child] — não recriam este `State`, então não disparam a
/// entrada de novo. Isso só deixa de valer se o pai KEY-ar explicitamente
/// este widget com uma chave que muda (ex.: `ValueKey(item.id)` numa lista
/// que insere itens nela mesma) — nesse caso cada nova chave é, de fato, um
/// painel novo entrando, que é exatamente o comportamento desejado (ver
/// `WorkoutSetsPanel`, que usa isso de propósito para a entrada de cada
/// série nova).
///
/// Respeita `MediaQuery.disableAnimations` (Reduced Motion do SO): quando
/// ativo, o conteúdo aparece imediatamente, sem nenhuma animação.
class SystemEntrance extends StatefulWidget {
  const SystemEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  final Widget child;

  /// Atraso antes de iniciar a entrada deste painel específico — usado para
  /// o stagger discreto entre painéis de uma mesma tela (ver
  /// [SystemDurations.staggerStep]). Mantenha pequeno: o usuário não deve
  /// esperar a interface terminar de animar para usá-la.
  final Duration delay;

  @override
  State<SystemEntrance> createState() => _SystemEntranceState();
}

class _SystemEntranceState extends State<SystemEntrance> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    final reduceMotion = WidgetsBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (reduceMotion) {
      _visible = true;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.delay > Duration.zero) {
        await Future.delayed(widget.delay);
      }
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;

    return AnimatedSlide(
      offset: _visible ? Offset.zero : const Offset(0, 0.04),
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

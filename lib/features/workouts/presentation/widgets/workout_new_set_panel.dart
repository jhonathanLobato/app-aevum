import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/system_button.dart';
import '../../../../design_system/system_colors.dart';
import '../../../../design_system/system_panel.dart';
import '../../../../design_system/system_spacing.dart';
import '../../../../design_system/system_text_field.dart';
import '../../../profile/presentation/profile_providers.dart';

/// "NOVA SÉRIE" — carga, repetições e os dois botões de ação do exercício
/// atual, direto de `treinos.tsx`.
///
/// É um `StatefulWidget` próprio, isolado do resto da tela: a validação
/// ao vivo (borda verde/vermelha enquanto digita, como no protótipo) só
/// precisa reconstruir estes dois campos, não a sessão inteira — evita
/// recalcular/repintar o cabeçalho, a lista de séries e o timer a cada
/// caractere digitado (Fase 6, seção 14).
class WorkoutNewSetPanel extends StatefulWidget {
  const WorkoutNewSetPanel({
    super.key,
    required this.cargaController,
    required this.repsController,
    required this.enabled,
    required this.onRegistrar,
    required this.onFinalizarExercicio,
    required this.onRetornarExercicio,
    this.exercicioFinalizado = false,
  });

  final TextEditingController cargaController;
  final TextEditingController repsController;
  final bool enabled;
  final VoidCallback onRegistrar;
  final VoidCallback onFinalizarExercicio;

  /// Exercício marcado como finalizado: os campos somem e só resta o botão
  /// "Retornar ao exercício".
  final bool exercicioFinalizado;
  final VoidCallback onRetornarExercicio;

  @override
  State<WorkoutNewSetPanel> createState() => _WorkoutNewSetPanelState();
}

class _WorkoutNewSetPanelState extends State<WorkoutNewSetPanel> {
  @override
  void initState() {
    super.initState();
    widget.cargaController.addListener(_onChanged);
    widget.repsController.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(WorkoutNewSetPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cargaController != widget.cargaController) {
      oldWidget.cargaController.removeListener(_onChanged);
      widget.cargaController.addListener(_onChanged);
    }
    if (oldWidget.repsController != widget.repsController) {
      oldWidget.repsController.removeListener(_onChanged);
      widget.repsController.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    widget.cargaController.removeListener(_onChanged);
    widget.repsController.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  double? get _carga =>
      double.tryParse(widget.cargaController.text.replaceAll(',', '.'));
  int? get _reps => int.tryParse(widget.repsController.text);

  bool get _cargaValida => _carga != null && _carga! > 0;
  bool get _repsValidas => _reps != null && _reps! > 0;

  SystemFieldStatus _statusFor(String text, bool valido) {
    if (text.isEmpty) return SystemFieldStatus.idle;
    return valido ? SystemFieldStatus.success : SystemFieldStatus.error;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.exercicioFinalizado) {
      return SystemPanel(
        title: 'NOVA SÉRIE',
        child: SystemButton(
          label: 'Retornar ao exercício',
          variant: SystemButtonVariant.action,
          size: SystemButtonSize.lg,
          icon:
              const Icon(Icons.undo, size: 16, color: SystemPalette.foreground),
          onPressed: widget.enabled ? widget.onRetornarExercicio : null,
        ),
      );
    }

    final cargaTexto = widget.cargaController.text;
    final repsTexto = widget.repsController.text;

    return SystemPanel(
      title: 'NOVA SÉRIE',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Consumer(
                  builder: (context, ref, _) => SystemTextField(
                    key: const Key('workout_carga_field'),
                    label: 'CARGA',
                    controller: widget.cargaController,
                    enabled: widget.enabled,
                    suffix: ref.watch(unitsProvider).pesoSufixo,
                    icon: const Icon(Icons.fitness_center, size: 18),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    status: _statusFor(cargaTexto, _cargaValida),
                    hint: cargaTexto.isNotEmpty && !_cargaValida
                        ? 'Valor inválido'
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: SystemSpacing.sm),
              Expanded(
                child: SystemTextField(
                  key: const Key('workout_reps_field'),
                  label: 'REPETIÇÕES',
                  controller: widget.repsController,
                  enabled: widget.enabled,
                  suffix: 'REPS',
                  icon: const Icon(Icons.repeat, size: 18),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  status: _statusFor(repsTexto, _repsValidas),
                  hint: repsTexto.isNotEmpty && !_repsValidas
                      ? 'Valor inválido'
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: SystemSpacing.md),
          SystemButton(
            label: 'Registrar série',
            variant: SystemButtonVariant.action,
            size: SystemButtonSize.lg,
            kicker: 'SYSTEM ACTION',
            icon: const Icon(Icons.add,
                size: 16, color: SystemPalette.foreground),
            onPressed: widget.enabled && _cargaValida && _repsValidas
                ? widget.onRegistrar
                : null,
          ),
          const SizedBox(height: SystemSpacing.sm),
          SystemButton(
            label: 'Finalizar exercício',
            icon: const Icon(Icons.flag_outlined,
                size: 16, color: SystemPalette.foreground),
            onPressed: widget.enabled ? widget.onFinalizarExercicio : null,
          ),
        ],
      ),
    );
  }
}

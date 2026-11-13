import 'package:flutter/material.dart';

import '../../../design_system/system_button.dart';
import '../../../design_system/system_colors.dart';
import '../../../design_system/system_panel.dart';
import '../../../design_system/system_spacing.dart';
import '../../../design_system/system_text_field.dart';

/// Diálogo (estilo Sistema) para criar ou renomear um treino. Devolve o nome
/// digitado, ou `null` se for cancelado.
Future<String?> showWorkoutNameDialog(
  BuildContext context, {
  String titulo = 'NOVO TREINO',
  String? nomeInicial,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) =>
        _WorkoutNameDialog(titulo: titulo, nomeInicial: nomeInicial),
  );
}

class _WorkoutNameDialog extends StatefulWidget {
  const _WorkoutNameDialog({required this.titulo, this.nomeInicial});

  final String titulo;
  final String? nomeInicial;

  @override
  State<_WorkoutNameDialog> createState() => _WorkoutNameDialogState();
}

class _WorkoutNameDialogState extends State<_WorkoutNameDialog> {
  late final _controller = TextEditingController(text: widget.nomeInicial);

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _salvar() {
    final nome = _controller.text.trim();
    if (nome.isNotEmpty) Navigator.of(context).pop(nome);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: SystemPanel(
        glow: true,
        title: widget.titulo,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SystemTextField(
              key: const Key('workout_nome_field'),
              label: 'Nome do treino',
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _salvar(),
            ),
            const SizedBox(height: SystemSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: SystemButton(
                    label: 'Cancelar',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: SystemSpacing.sm),
                Expanded(
                  child: SystemButton(
                    label: 'Salvar',
                    variant: SystemButtonVariant.action,
                    icon: const Icon(Icons.check,
                        size: 16, color: SystemPalette.foreground),
                    onPressed: _controller.text.trim().isEmpty ? null : _salvar,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../design_system/system_button.dart';
import '../../../design_system/system_colors.dart';
import '../../../design_system/system_spacing.dart';
import '../../../design_system/system_text_styles.dart';

/// Editar um exercício dentro do treino: hoje só a posição. Devolve a nova
/// posição (começando em 1) ou `null` se o usuário fechar sem salvar.
Future<int?> showExercisePositionSheet(
  BuildContext context, {
  required String exerciseNome,
  required int posicaoAtual,
  required int total,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.85,
    ),
    builder: (context) => _ExercisePositionSheet(
      exerciseNome: exerciseNome,
      posicaoAtual: posicaoAtual,
      total: total,
    ),
  );
}

class _ExercisePositionSheet extends StatefulWidget {
  const _ExercisePositionSheet({
    required this.exerciseNome,
    required this.posicaoAtual,
    required this.total,
  });

  final String exerciseNome;
  final int posicaoAtual;
  final int total;

  @override
  State<_ExercisePositionSheet> createState() => _ExercisePositionSheetState();
}

class _ExercisePositionSheetState extends State<_ExercisePositionSheet> {
  late int _posicao = widget.posicaoAtual;

  String _fmt(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SystemPalette.background,
        border: Border(
          top: BorderSide(
            color:
                SystemPalette.primary.withValues(alpha: SystemOpacities.border),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            SystemSpacing.xl,
            SystemSpacing.lg,
            SystemSpacing.xl,
            SystemSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(width: 2, height: 12, color: SystemPalette.primary),
                  const SizedBox(width: SystemSpacing.sm),
                  const Text('EDITAR EXERCÍCIO NO TREINO',
                      style: SystemTextStyles.label),
                ],
              ),
              const SizedBox(height: SystemSpacing.lg),
              Text(
                widget.exerciseNome.toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: SystemTextStyles.displayMedium,
              ),
              const SizedBox(height: SystemSpacing.lg),
              const Text(
                'POSIÇÃO NO TREINO',
                textAlign: TextAlign.center,
                style: SystemTextStyles.label,
              ),
              const SizedBox(height: SystemSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    color: SystemPalette.primary,
                    iconSize: 32,
                    tooltip: 'Subir posição',
                    onPressed:
                        _posicao > 1 ? () => setState(() => _posicao--) : null,
                  ),
                  const SizedBox(width: SystemSpacing.md),
                  Text(
                    '${_fmt(_posicao)} / ${_fmt(widget.total)}',
                    style: const TextStyle(
                      fontFamily: SystemFonts.display,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      color: SystemPalette.primary,
                      shadows: SystemTextStyles.glowPrimary,
                    ),
                  ),
                  const SizedBox(width: SystemSpacing.md),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: SystemPalette.primary,
                    iconSize: 32,
                    tooltip: 'Descer posição',
                    onPressed: _posicao < widget.total
                        ? () => setState(() => _posicao++)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: SystemSpacing.lg),
              SystemButton(
                label: 'Salvar posição',
                variant: SystemButtonVariant.action,
                size: SystemButtonSize.lg,
                onPressed: () => Navigator.of(context).pop(_posicao),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

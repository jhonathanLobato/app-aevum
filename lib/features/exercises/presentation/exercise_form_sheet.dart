import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/system_button.dart';
import '../../../design_system/system_colors.dart';
import '../../../design_system/system_spacing.dart';
import '../../../design_system/system_text_field.dart';
import '../../../design_system/system_text_styles.dart';
import '../domain/exercise.dart';
import 'exercise_providers.dart';

/// Cadastro/edição de exercício. `useSafeArea` + altura máxima evitam que o
/// painel suba até a barra de status (principalmente com o teclado aberto).
Future<void> showExerciseFormSheet(BuildContext context, {Exercise? exercise}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.9,
    ),
    builder: (context) => _ExerciseFormSheet(exercise: exercise),
  );
}

class _ExerciseFormSheet extends ConsumerStatefulWidget {
  const _ExerciseFormSheet({this.exercise});

  final Exercise? exercise;

  @override
  ConsumerState<_ExerciseFormSheet> createState() => _ExerciseFormSheetState();
}

class _ExerciseFormSheetState extends ConsumerState<_ExerciseFormSheet> {
  late final _nomeController =
      TextEditingController(text: widget.exercise?.nome);
  late final _grupoController =
      TextEditingController(text: widget.exercise?.grupoMuscular);
  bool _tentouSalvar = false;
  bool _salvando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _grupoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final nome = _nomeController.text.trim();
    final grupo = _grupoController.text.trim();
    if (nome.isEmpty || grupo.isEmpty) {
      setState(() => _tentouSalvar = true);
      return;
    }
    if (_salvando) return;
    _salvando = true;

    final repo = ref.read(exerciseRepositoryProvider);
    final exercise = widget.exercise;

    if (exercise == null) {
      await repo.create(nome: nome, grupoMuscular: grupo);
    } else {
      await repo.update(exercise.id, nome: nome, grupoMuscular: grupo);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.exercise != null;
    final nomeInvalido = _tentouSalvar && _nomeController.text.trim().isEmpty;
    final grupoInvalido = _tentouSalvar && _grupoController.text.trim().isEmpty;

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
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          SystemSpacing.xl,
          SystemSpacing.lg,
          SystemSpacing.xl,
          MediaQuery.of(context).viewInsets.bottom + SystemSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(width: 2, height: 12, color: SystemPalette.primary),
                const SizedBox(width: SystemSpacing.sm),
                Text(
                  editando ? 'EDITAR EXERCÍCIO' : 'NOVO EXERCÍCIO',
                  style: SystemTextStyles.label,
                ),
              ],
            ),
            const SizedBox(height: SystemSpacing.lg),
            SystemTextField(
              key: const Key('exercise_nome_field'),
              label: 'Nome',
              controller: _nomeController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              status: nomeInvalido
                  ? SystemFieldStatus.error
                  : SystemFieldStatus.idle,
              hint: nomeInvalido ? 'Informe o nome do exercício' : null,
              onChanged: (_) {
                if (_tentouSalvar) setState(() {});
              },
            ),
            const SizedBox(height: SystemSpacing.md),
            SystemTextField(
              key: const Key('exercise_grupo_field'),
              label: 'Grupo muscular',
              controller: _grupoController,
              textInputAction: TextInputAction.done,
              status: grupoInvalido
                  ? SystemFieldStatus.error
                  : SystemFieldStatus.idle,
              hint: grupoInvalido ? 'Informe o grupo muscular' : null,
              onChanged: (_) {
                if (_tentouSalvar) setState(() {});
              },
              onSubmitted: (_) => _salvar(),
            ),
            const SizedBox(height: SystemSpacing.lg),
            SystemButton(
              label: editando ? 'Salvar' : 'Adicionar',
              variant: SystemButtonVariant.action,
              size: SystemButtonSize.lg,
              onPressed: _salvar,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/exercise.dart';
import 'exercise_providers.dart';

Future<void> showExerciseFormSheet(BuildContext context, {Exercise? exercise}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
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
  final _formKey = GlobalKey<FormState>();
  late final _nomeController =
      TextEditingController(text: widget.exercise?.nome);
  late final _grupoController =
      TextEditingController(text: widget.exercise?.grupoMuscular);
  bool _salvando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _grupoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);

    final repo = ref.read(exerciseRepositoryProvider);
    final nome = _nomeController.text.trim();
    final grupo = _grupoController.text.trim();
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

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              editando ? 'Editar exercício' : 'Novo exercício',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nomeController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Informe o nome do exercício'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _grupoController,
              decoration: const InputDecoration(labelText: 'Grupo muscular'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Informe o grupo muscular'
                  : null,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _salvando ? null : _salvar,
              child: Text(editando ? 'Salvar' : 'Adicionar'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/system_back_button.dart';
import '../../../design_system/system_button.dart';
import '../../../design_system/system_panel.dart';
import '../../../design_system/system_scaffold.dart';
import '../../../design_system/system_spacing.dart';
import '../../../design_system/system_text_field.dart';
import 'workout_template_providers.dart';

/// Criar/editar treino — redesenho da Fase 11 do que antes era um
/// `AlertDialog` Material simples (`showWorkoutNameDialog`). Continua usando
/// só os campos reais que o repositório já suporta: `nome` (não existe
/// `descrição` em `WorkoutTemplate`, então não foi inventada aqui).
class WorkoutFormScreen extends ConsumerStatefulWidget {
  const WorkoutFormScreen({this.templateId, super.key});

  /// `null` = criando um treino novo; informado = editando o treino com
  /// este id (nome pré-preenchido com o valor real já salvo).
  final int? templateId;

  bool get isEditing => templateId != null;

  @override
  ConsumerState<WorkoutFormScreen> createState() => _WorkoutFormScreenState();
}

class _WorkoutFormScreenState extends ConsumerState<WorkoutFormScreen> {
  final _nomeController = TextEditingController();
  bool _preenchido = false;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _nomeController.addListener(() => setState(() {}));
    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _preencherNome());
    }
  }

  void _preencherNome() {
    if (_preenchido || !mounted) return;
    final templates = ref.read(workoutTemplatesProvider).valueOrNull;
    if (templates == null) return;
    for (final template in templates) {
      if (template.id == widget.templateId) {
        setState(() {
          _nomeController.text = template.nome;
          _preenchido = true;
        });
        return;
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final nome = _nomeController.text.trim();
    if (nome.isEmpty || _salvando) return;

    setState(() => _salvando = true);
    final repo = ref.read(workoutTemplateRepositoryProvider);

    if (widget.isEditing) {
      await repo.rename(widget.templateId!, nome);
      if (mounted) context.pop();
    } else {
      final id = await repo.create(nome);
      if (mounted) context.pushReplacement('/workouts/$id');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Observa o provider só pra garantir que o preenchimento aconteça assim
    // que os dados chegarem, mesmo se ainda não tivessem no 1º frame
    // (`_preencherNome` é idempotente — não sobrescreve o que o usuário já
    // estiver digitando).
    if (widget.isEditing && !_preenchido) {
      ref.watch(workoutTemplatesProvider);
      WidgetsBinding.instance.addPostFrameCallback((_) => _preencherNome());
    }

    return SystemScaffold(
      title: widget.isEditing ? 'EDITAR TREINO' : 'NOVO TREINO',
      subtitle: widget.isEditing ? 'EDITAR PROTOCOLO' : 'CRIAR PROTOCOLO',
      leading: const SystemBackButton(),
      body: SystemPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SystemTextField(
              label: 'Nome do treino',
              controller: _nomeController,
              autofocus: !widget.isEditing,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _salvar(),
            ),
            const SizedBox(height: SystemSpacing.lg),
            SystemButton(
              label: widget.isEditing ? 'Salvar alterações' : 'Criar treino',
              variant: SystemButtonVariant.action,
              size: SystemButtonSize.lg,
              // Sem spinner: criar/renomear é uma escrita local quase
              // instantânea (SQLite em disco do próprio aparelho) — um
              // `CircularProgressIndicator` indeterminado aqui só giraria por
              // um instante imperceptível, sem ganho real de UX.
              onPressed: _nomeController.text.trim().isEmpty || _salvando
                  ? null
                  : _salvar,
            ),
          ],
        ),
      ),
    );
  }
}

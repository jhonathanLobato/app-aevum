import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/system_back_button.dart';
import '../../../design_system/system_button.dart';
import '../../../design_system/system_colors.dart';
import '../../../design_system/system_confirm_dialog.dart';
import '../../../design_system/system_empty_state.dart';
import '../../../design_system/system_panel.dart';
import '../../../design_system/system_scaffold.dart';
import '../../../design_system/system_spacing.dart';
import '../../../design_system/system_text_styles.dart';
import '../domain/workout_template.dart';
import '../domain/workout_template_repository.dart';
import 'exercise_picker_sheet.dart';
import 'exercise_position_sheet.dart';
import 'workout_session_providers.dart';
import 'workout_template_providers.dart';

/// Detalhe/gerenciamento do treino — continua sendo a tela de CRUD dos
/// exercícios do protocolo, não o carrossel da sessão ativa (esse é
/// [ActiveWorkoutScreen], iniciado a partir do botão "Iniciar treino" aqui).
/// Redesenhada na Fase 11 a partir da versão Material simples original.
class WorkoutTemplateDetailScreen extends ConsumerWidget {
  const WorkoutTemplateDetailScreen({required this.templateId, super.key});

  final int templateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(workoutTemplatesProvider);
    final repo = ref.read(workoutTemplateRepositoryProvider);

    return templatesAsync.when(
      data: (templates) {
        final template = _findTemplate(templates, templateId);
        if (template == null) {
          return const SystemScaffold(
            title: 'TREINO',
            body: SystemEmptyState(message: 'ESTE TREINO NÃO EXISTE MAIS'),
          );
        }

        final gruposMusculares = {
          for (final e in template.exercicios) e.grupoMuscular,
        }.toList();

        return SystemScaffold(
          title: template.nome.toUpperCase(),
          subtitle: 'PROTOCOLO DE TREINAMENTO',
          leading: const SystemBackButton(),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              iconSize: 18,
              color: SystemPalette.mutedForeground,
              tooltip: 'Editar treino',
              onPressed: () => context.push('/workouts/${template.id}/edit'),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              iconSize: 18,
              color: SystemPalette.mutedForeground,
              tooltip: 'Excluir treino',
              onPressed: () => _confirmarExclusao(context, repo, template),
            ),
          ],
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (gruposMusculares.isNotEmpty) ...[
                Text(
                  gruposMusculares.join(' + ').toUpperCase(),
                  style: SystemTextStyles.label
                      .copyWith(color: SystemPalette.violet),
                ),
                const SizedBox(height: SystemSpacing.lg),
              ],
              SystemPanel(
                title: '${template.exercicios.length} EXERCÍCIOS',
                child: template.exercicios.isEmpty
                    ? const SystemEmptyState(
                        icon: Icons.format_list_bulleted,
                        message: 'NENHUM EXERCÍCIO ADICIONADO',
                        detail:
                            'Adicione pelo menos um exercício para iniciar.',
                      )
                    : Column(
                        children: [
                          for (var i = 0;
                              i < template.exercicios.length;
                              i++) ...[
                            if (i > 0) const SizedBox(height: SystemSpacing.sm),
                            _ExerciseRow(
                              key: ValueKey(
                                  template.exercicios[i].templateExerciseId),
                              posicao: i + 1,
                              item: template.exercicios[i],
                              onEditar: () =>
                                  _editarPosicao(context, repo, template, i),
                              onRemover: () => repo.removeExercise(
                                  template.exercicios[i].templateExerciseId),
                            ),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: SystemSpacing.lg),
              SystemButton(
                label: 'Adicionar exercício',
                icon: const Icon(Icons.add,
                    size: 16, color: SystemPalette.foreground),
                onPressed: () async {
                  final exercise = await showExercisePickerSheet(context, ref);
                  if (exercise != null) {
                    await repo.addExercise(template.id, exercise.id);
                  }
                },
              ),
              const SizedBox(height: SystemSpacing.sm),
              SystemButton(
                label: 'Iniciar treino',
                variant: SystemButtonVariant.action,
                size: SystemButtonSize.lg,
                icon: const Icon(Icons.play_arrow,
                    size: 16, color: SystemPalette.foreground),
                onPressed: template.exercicios.isEmpty
                    ? null
                    : () async {
                        final sessionId = await ref
                            .read(workoutSessionRepositoryProvider)
                            .start(
                                templateId: template.id, nome: template.nome);
                        if (context.mounted) {
                          context.push('/sessions/$sessionId');
                        }
                      },
              ),
            ],
          ),
        );
      },
      error: (error, stackTrace) => const SystemScaffold(
        title: 'TREINO',
        body: SystemEmptyState(
          icon: Icons.error_outline,
          message: 'ERRO AO CARREGAR O TREINO',
        ),
      ),
      loading: () => const SystemScaffold(
        title: 'TREINO',
        body: Center(
          child: CircularProgressIndicator(color: SystemPalette.primary),
        ),
      ),
    );
  }

  Future<void> _confirmarExclusao(
    BuildContext context,
    WorkoutTemplateRepository repo,
    WorkoutTemplate template,
  ) async {
    final confirmar = await showSystemConfirmDialog(
      context,
      titulo: 'Excluir treino?',
      mensagem:
          'Isso remove "${template.nome}" e todos os seus exercícios cadastrados. Esta ação não pode ser desfeita.',
      confirmar: 'Excluir',
      icone: Icons.delete_outline,
      destrutivo: true,
    );
    if (!confirmar) return;

    await repo.delete(template.id);
    if (context.mounted) context.pop();
  }

  /// A posição só muda por aqui (editar o exercício no treino), nunca por
  /// arrastar — arrastar na lista conflitava com rolar a tela.
  Future<void> _editarPosicao(
    BuildContext context,
    WorkoutTemplateRepository repo,
    WorkoutTemplate template,
    int indice,
  ) async {
    final item = template.exercicios[indice];
    final novaPosicao = await showExercisePositionSheet(
      context,
      exerciseNome: item.exerciseNome,
      posicaoAtual: indice + 1,
      total: template.exercicios.length,
    );
    if (novaPosicao == null || novaPosicao == indice + 1) return;

    final ids = template.exercicios.map((e) => e.templateExerciseId).toList();
    final movedId = ids.removeAt(indice);
    ids.insert(novaPosicao - 1, movedId);
    await repo.reorderExercises(template.id, ids);
  }

  WorkoutTemplate? _findTemplate(List<WorkoutTemplate> templates, int id) {
    for (final template in templates) {
      if (template.id == id) return template;
    }
    return null;
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({
    super.key,
    required this.posicao,
    required this.item,
    required this.onEditar,
    required this.onRemover,
  });

  final int posicao;
  final WorkoutTemplateExerciseItem item;
  final VoidCallback onEditar;
  final VoidCallback onRemover;

  @override
  Widget build(BuildContext context) {
    final meta = (item.seriesAlvo != null && item.repeticoesAlvo != null)
        ? '${item.seriesAlvo} × ${item.repeticoesAlvo}'
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: SystemSpacing.md, vertical: SystemSpacing.sm),
      decoration: BoxDecoration(
        color:
            SystemPalette.surface2.withValues(alpha: SystemOpacities.surface2),
        border: Border(
          left: BorderSide(
              color: SystemPalette.primary.withValues(alpha: 0.5), width: 2),
        ),
      ),
      child: Row(
        children: [
          Text(
            posicao.toString().padLeft(2, '0'),
            style: const TextStyle(
              fontFamily: SystemFonts.display,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: SystemPalette.primary,
            ),
          ),
          const SizedBox(width: SystemSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.exerciseNome.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SystemTextStyles.displaySmall.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  item.grupoMuscular.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SystemTextStyles.label.copyWith(fontSize: 8.8),
                ),
              ],
            ),
          ),
          if (meta != null) ...[
            Text(meta, style: SystemTextStyles.bodySmall),
            const SizedBox(width: SystemSpacing.sm),
          ],
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                size: 20, color: SystemPalette.primary),
            tooltip: 'Editar exercício',
            onPressed: onEditar,
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline,
                size: 20, color: SystemPalette.destructive),
            tooltip: 'Remover exercício',
            onPressed: onRemover,
          ),
        ],
      ),
    );
  }
}

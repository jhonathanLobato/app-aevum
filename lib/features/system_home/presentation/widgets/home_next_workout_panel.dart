import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/system_colors.dart';
import '../../../../design_system/system_button.dart';
import '../../../../design_system/system_empty_state.dart';
import '../../../../design_system/system_panel.dart';
import '../../../../design_system/system_spacing.dart';
import '../../../../design_system/system_text_styles.dart';
import '../../../workouts/presentation/workout_template_providers.dart';

/// "PRÓXIMO TREINO", direto de `index.tsx` ("TREINO DE HOJE" no Lovable).
///
/// O app ainda não tem conceito de programação por dia da semana (seção 12
/// do CLAUDE.md, não implementada), então não existe um "treino de hoje"
/// real pra mostrar — renomeado para "PRÓXIMO TREINO" e preenchido com o
/// treino criado mais recentemente ([workoutTemplatesProvider] já ordena
/// por `criadoEm` decrescente), que é a melhor aproximação honesta
/// disponível hoje. Nada aqui é mockado: tanto o nome do treino quanto os
/// exercícios vêm do banco.
class HomeNextWorkoutPanel extends ConsumerWidget {
  const HomeNextWorkoutPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(workoutTemplatesProvider);

    return templatesAsync.when(
      data: (templates) {
        if (templates.isEmpty) {
          return SystemPanel(
            title: 'PRÓXIMO TREINO',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SystemEmptyState(
                  icon: Icons.fitness_center_outlined,
                  message: 'NENHUM TREINO CADASTRADO',
                  detail: 'Crie seu primeiro treino para começar.',
                ),
                const SizedBox(height: SystemSpacing.sm),
                SystemButton(
                  label: 'Criar treino',
                  onPressed: () => context.go('/workouts'),
                ),
              ],
            ),
          );
        }

        final template = templates.first;
        final preview = template.exercicios.take(3).toList();

        return SystemPanel(
          title: 'PRÓXIMO TREINO',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.nome.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SystemTextStyles.displayMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${template.exercicios.length} EXERCÍCIOS',
                          style: SystemTextStyles.label.copyWith(
                            fontSize: 8.8,
                            color: SystemPalette.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: SystemSpacing.sm),
                  SystemButton(
                    label: 'Abrir',
                    icon: const Icon(Icons.chevron_right,
                        size: 16, color: SystemPalette.foreground),
                    onPressed: () => context.push('/workouts/${template.id}'),
                  ),
                ],
              ),
              if (preview.isNotEmpty) ...[
                const SizedBox(height: SystemSpacing.md),
                const SystemDivider(),
                const SizedBox(height: SystemSpacing.md),
                Column(
                  children: [
                    for (var i = 0; i < preview.length; i++) ...[
                      if (i > 0) const SizedBox(height: SystemSpacing.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  (i + 1).toString().padLeft(2, '0'),
                                  style: const TextStyle(
                                    fontFamily: SystemFonts.display,
                                    fontSize: 9.6,
                                    color: Color(0xB300CDFD), // primary @ 70%
                                  ),
                                ),
                                const SizedBox(width: SystemSpacing.sm),
                                Expanded(
                                  child: Text(
                                    preview[i].exerciseNome,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: SystemTextStyles.body,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _targetText(preview[i].seriesAlvo,
                                preview[i].repeticoesAlvo),
                            style: SystemTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const SystemPanel(
        title: 'PRÓXIMO TREINO',
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: SystemSpacing.md),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: SystemPalette.primary),
            ),
          ),
        ),
      ),
      error: (error, stackTrace) => const SystemPanel(
        title: 'PRÓXIMO TREINO',
        child: SystemEmptyState(
          icon: Icons.error_outline,
          message: 'ERRO AO CARREGAR TREINOS',
        ),
      ),
    );
  }
}

String _targetText(int? series, int? repeticoes) {
  if (series == null || repeticoes == null) return '';
  return '$series×$repeticoes';
}

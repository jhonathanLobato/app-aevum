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
import '../../../design_system/system_stat_box.dart';
import '../../../design_system/system_text_styles.dart';
import '../domain/sport_activity.dart';
import 'activity_providers.dart';
import 'sport_activity_format.dart';

/// Detalhe de um registro: só as informações relevantes da modalidade, com
/// editar (reaproveita o formulário) e excluir (com confirmação).
class SportActivityDetailScreen extends ConsumerWidget {
  const SportActivityDetailScreen({
    required this.tipo,
    required this.activityId,
    super.key,
  });

  final SportType tipo;
  final int activityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final atividadeAsync = ref.watch(sportActivityProvider(activityId));

    return SystemScaffold(
      title: tipo.nome.toUpperCase(),
      subtitle: 'DETALHE DO REGISTRO',
      leading: const SystemBackButton(),
      body: atividadeAsync.when(
        data: (atividade) {
          if (atividade == null) {
            return const SystemEmptyState(
              icon: Icons.event_busy_outlined,
              message: 'ESTE REGISTRO NÃO EXISTE MAIS',
            );
          }
          return _Conteudo(atividade: atividade);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: SystemPalette.primary),
        ),
        error: (error, stackTrace) => const SystemEmptyState(
          icon: Icons.error_outline,
          message: 'ERRO AO CARREGAR REGISTRO',
        ),
      ),
    );
  }
}

class _Conteudo extends ConsumerWidget {
  const _Conteudo({required this.atividade});

  final SportActivity atividade;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ritmo = atividade.ritmoMinPorKm;
    final velocidade = atividade.velocidadeMediaKmh;

    final caixas = <Widget>[
      SystemStatBox(
        label: 'DATA',
        value: formatarDataCurta(atividade.data, comAno: true),
        icon: Icons.calendar_today,
      ),
      SystemStatBox(
        label: 'DURAÇÃO',
        value: formatarDuracao(atividade.duracaoMinutos),
        icon: Icons.schedule,
      ),
      if (atividade.distanciaKm != null)
        SystemStatBox(
          label: 'DISTÂNCIA',
          value: formatarDistancia(atividade.distanciaKm!),
          icon: Icons.straighten,
        ),
      if (ritmo != null)
        SystemStatBox(
          label: 'RITMO MÉDIO',
          value: formatarRitmo(ritmo),
          icon: Icons.speed,
        ),
      if (velocidade != null)
        SystemStatBox(
          label: 'VELOCIDADE MÉDIA',
          value: formatarVelocidade(velocidade),
          icon: Icons.speed,
        ),
      if (atividade.rounds != null)
        SystemStatBox(
          label: 'ROUNDS',
          value: '${atividade.rounds}',
          icon: Icons.repeat,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SystemPanel(
          title: 'REGISTRO',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < caixas.length; i += 2) ...[
                if (i > 0) const SizedBox(height: SystemSpacing.sm),
                Row(
                  children: [
                    Expanded(child: caixas[i]),
                    const SizedBox(width: SystemSpacing.sm),
                    Expanded(
                      child: i + 1 < caixas.length
                          ? caixas[i + 1]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ],
              if (atividade.observacoes != null) ...[
                const SizedBox(height: SystemSpacing.md),
                const Text('OBSERVAÇÃO', style: SystemTextStyles.label),
                const SizedBox(height: SystemSpacing.xs),
                Text(atividade.observacoes!, style: SystemTextStyles.body),
              ],
            ],
          ),
        ),
        const SizedBox(height: SystemSpacing.lg),
        SystemButton(
          label: 'Editar',
          variant: SystemButtonVariant.action,
          icon: const Icon(Icons.edit_outlined,
              size: 16, color: SystemPalette.foreground),
          onPressed: () => context
              .push('/activities/${atividade.tipo.name}/${atividade.id}/edit'),
        ),
        const SizedBox(height: SystemSpacing.sm),
        SystemButton(
          label: 'Excluir',
          variant: SystemButtonVariant.danger,
          icon: const Icon(Icons.delete_outline,
              size: 16, color: SystemPalette.destructive),
          onPressed: () => _excluir(context, ref),
        ),
      ],
    );
  }

  Future<void> _excluir(BuildContext context, WidgetRef ref) async {
    final confirmar = await showSystemConfirmDialog(
      context,
      titulo: 'Excluir registro?',
      mensagem:
          'Este registro de ${atividade.tipo.nome} será removido. Esta ação não pode ser desfeita.',
      confirmar: 'Excluir',
      icone: Icons.delete_outline,
      destrutivo: true,
    );
    if (!confirmar) return;

    await ref.read(sportActivityRepositoryProvider).delete(atividade.id);
    if (context.mounted) Navigator.of(context).maybePop();
  }
}

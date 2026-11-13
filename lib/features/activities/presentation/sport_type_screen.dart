import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/system_back_button.dart';
import '../../../design_system/system_button.dart';
import '../../../design_system/system_colors.dart';
import '../../../design_system/system_empty_state.dart';
import '../../../design_system/system_panel.dart';
import '../../../design_system/system_scaffold.dart';
import '../../../design_system/system_spacing.dart';
import '../domain/sport_activity.dart';
import 'activity_providers.dart';
import 'sport_activity_tile.dart';

/// Página de UMA modalidade: ações (adicionar/histórico) e só os 3 registros
/// mais recentes — o histórico completo fica em tela própria.
class SportTypeScreen extends ConsumerWidget {
  const SportTypeScreen({required this.tipo, super.key});

  final SportType tipo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentesAsync = ref.watch(recentSportActivitiesProvider(tipo));

    return SystemScaffold(
      title: tipo.nome.toUpperCase(),
      subtitle: 'REGISTRO ESPORTIVO',
      leading: const SystemBackButton(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: SystemButton(
                  label: 'Adicionar registro',
                  variant: SystemButtonVariant.action,
                  icon: const Icon(Icons.add,
                      size: 16, color: SystemPalette.foreground),
                  onPressed: () => context.push('/activities/${tipo.name}/new'),
                ),
              ),
              const SizedBox(width: SystemSpacing.sm),
              Expanded(
                child: SystemButton(
                  label: 'Histórico',
                  icon: const Icon(Icons.history,
                      size: 16, color: SystemPalette.foreground),
                  onPressed: () =>
                      context.push('/activities/${tipo.name}/history'),
                ),
              ),
            ],
          ),
          const SizedBox(height: SystemSpacing.lg),
          SystemPanel(
            title: 'ATIVIDADES RECENTES',
            child: recentesAsync.when(
              data: (recentes) {
                if (recentes.isEmpty) {
                  return SystemEmptyState(
                    icon: iconeVazio,
                    message: 'NENHUMA ATIVIDADE REGISTRADA',
                    detail: 'Seus registros de ${tipo.nome} aparecerão aqui.',
                  );
                }
                return Column(
                  children: [
                    for (var i = 0; i < recentes.length; i++) ...[
                      if (i > 0) const SizedBox(height: SystemSpacing.sm),
                      SportActivityTile(atividade: recentes[i]),
                    ],
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: SystemSpacing.md),
                  child:
                      CircularProgressIndicator(color: SystemPalette.primary),
                ),
              ),
              error: (error, stackTrace) => const SystemEmptyState(
                icon: Icons.error_outline,
                message: 'ERRO AO CARREGAR ATIVIDADES',
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const iconeVazio = Icons.event_note_outlined;
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/system_back_button.dart';
import '../../../design_system/system_colors.dart';
import '../../../design_system/system_empty_state.dart';
import '../../../design_system/system_panel.dart';
import '../../../design_system/system_scaffold.dart';
import '../../../design_system/system_spacing.dart';
import '../domain/sport_activity.dart';
import 'activity_providers.dart';
import 'sport_activity_tile.dart';

/// Histórico completo de UMA modalidade (a consulta já filtra por tipo).
class SportHistoryScreen extends ConsumerWidget {
  const SportHistoryScreen({required this.tipo, super.key});

  final SportType tipo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historicoAsync = ref.watch(sportActivityHistoryProvider(tipo));

    return SystemScaffold(
      title: tipo.nome.toUpperCase(),
      subtitle: 'HISTÓRICO COMPLETO',
      leading: const SystemBackButton(),
      body: historicoAsync.when(
        data: (registros) {
          if (registros.isEmpty) {
            return SystemPanel(
              child: SystemEmptyState(
                icon: Icons.event_note_outlined,
                message: 'NENHUMA ATIVIDADE REGISTRADA',
                detail: 'Seus registros de ${tipo.nome} aparecerão aqui.',
              ),
            );
          }
          return SystemPanel(
            title: '${registros.length} REGISTROS',
            child: Column(
              children: [
                for (var i = 0; i < registros.length; i++) ...[
                  if (i > 0) const SizedBox(height: SystemSpacing.sm),
                  SportActivityTile(atividade: registros[i], comAno: true),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: SystemPalette.primary),
        ),
        error: (error, stackTrace) => const SystemEmptyState(
          icon: Icons.error_outline,
          message: 'ERRO AO CARREGAR HISTÓRICO',
        ),
      ),
    );
  }
}

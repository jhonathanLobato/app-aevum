import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/system_colors.dart';
import '../../../design_system/system_empty_state.dart';
import '../../../design_system/system_entrance.dart';
import '../../../design_system/system_motion.dart';
import '../../../design_system/system_scaffold.dart';
import '../../../design_system/system_spacing.dart';
import '../../../design_system/system_text_styles.dart';
import '../../profile/presentation/profile_providers.dart';
import '../domain/mission.dart';
import 'mission_providers.dart';
import 'widgets/mission_card.dart';

/// Tela de Missões ("Quest Log"), redesenhada na Fase 7 a partir de
/// `missoes.tsx`. Agrupa por tipo (diária/semanal/desafios) e mostra
/// brevemente as concluídas recentemente — tudo com dados reais dos
/// providers já existentes (ver relatório da Fase 7 pra análise completa
/// do que já existia antes desta fase).
class MissionsScreen extends ConsumerWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAsync = ref.watch(activeMissionsProvider);
    final userRank = ref.watch(currentUserProvider).valueOrNull?.rank ?? 'F';

    return SystemScaffold(
      title: 'QUEST LOG',
      subtitle: 'MISSÕES DISPONÍVEIS',
      body: activeAsync.when(
        data: (missoes) => _MissionsList(missoes: missoes, userRank: userRank),
        loading: () => const Center(
          child: CircularProgressIndicator(color: SystemPalette.primary),
        ),
        error: (error, stackTrace) => const SystemEmptyState(
          icon: Icons.error_outline,
          message: 'ERRO AO CARREGAR MISSÕES',
        ),
      ),
    );
  }
}

class _MissionsList extends ConsumerWidget {
  const _MissionsList({required this.missoes, required this.userRank});

  final List<Mission> missoes;
  final String userRank;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (missoes.isEmpty) {
      return const SystemEmptyState(
        icon: Icons.flag_outlined,
        message: 'NENHUMA MISSÃO ATIVA',
        detail: 'Finalize um treino para gerar novas missões.',
      );
    }

    final diarias = missoes.where((m) => m.tipo == MissionType.diaria).toList();
    final semanais =
        missoes.where((m) => m.tipo == MissionType.semanal).toList();
    final desafios =
        missoes.where((m) => m.tipo == MissionType.desafio).toList();
    final historicoAsync = ref.watch(missionRecentHistoryProvider);
    final concluidas = historicoAsync.valueOrNull ?? const <Mission>[];

    // Fase 9: cada grupo visível entra com um stagger discreto. A chave de
    // cada bloco é o próprio grupo (não a posição), então se o histórico
    // aparecer depois (stream carregando) os blocos já na tela não têm sua
    // entrada replay-ada — só o bloco novo ganha um `State` novo.
    final blocos = <String, Widget>{
      if (diarias.isNotEmpty)
        'diarias': _MissionGroup('DIÁRIA', diarias, userRank),
      if (semanais.isNotEmpty)
        'semanais': _MissionGroup('SEMANAL', semanais, userRank),
      if (desafios.isNotEmpty)
        'desafios': _MissionGroup('DESAFIOS', desafios, userRank),
      if (concluidas.isNotEmpty)
        'historico':
            _MissionGroup('CONCLUÍDAS RECENTEMENTE', concluidas, userRank),
    };

    final blocosList = blocos.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < blocosList.length; i++)
          SystemEntrance(
            key: ValueKey(blocosList[i].key),
            delay: SystemDurations.staggerStep * i,
            child: blocosList[i].value,
          ),
      ],
    );
  }
}

class _MissionGroup extends StatelessWidget {
  const _MissionGroup(this.titulo, this.missoes, this.userRank);

  final String titulo;
  final List<Mission> missoes;
  final String userRank;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionLabel(titulo),
        for (final m in missoes) ...[
          MissionCard(mission: m, userRank: userRank),
          const SizedBox(height: SystemSpacing.md),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SystemSpacing.sm),
      child: Row(
        children: [
          Container(width: 2, height: 12, color: SystemPalette.primary),
          const SizedBox(width: SystemSpacing.sm),
          Text(label, style: SystemTextStyles.label),
        ],
      ),
    );
  }
}

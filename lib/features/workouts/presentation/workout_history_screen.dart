import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/system_back_button.dart';
import '../../../design_system/system_colors.dart';
import '../../../design_system/system_empty_state.dart';
import '../../../design_system/system_entrance.dart';
import '../../../design_system/system_motion.dart';
import '../../../design_system/system_panel.dart';
import '../../../design_system/system_scaffold.dart';
import '../../../design_system/system_spacing.dart';
import '../../../design_system/system_stat_box.dart';
import '../../../design_system/system_text_styles.dart';
import '../../activities/domain/sport_activity.dart';
import '../../activities/presentation/sport_activity_format.dart';
import '../domain/workout_session.dart';
import 'general_history.dart';

const _nomesDosMeses = [
  'JANEIRO',
  'FEVEREIRO',
  'MARÇO',
  'ABRIL',
  'MAIO',
  'JUNHO',
  'JULHO',
  'AGOSTO',
  'SETEMBRO',
  'OUTUBRO',
  'NOVEMBRO',
  'DEZEMBRO',
];

/// Histórico geral: treinos de musculação finalizados + registros esportivos
/// numa única linha do tempo, agrupada por mês/ano (mais recente primeiro).
/// Cada mês pode ser recolhido/expandido — estado só de tela, sem persistir.
class WorkoutHistoryScreen extends ConsumerStatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  ConsumerState<WorkoutHistoryScreen> createState() =>
      _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends ConsumerState<WorkoutHistoryScreen> {
  /// Chaves dos meses recolhidos. Por padrão todos começam expandidos.
  final _recolhidos = <String>{};

  void _alternar(String chave) {
    setState(() {
      if (!_recolhidos.remove(chave)) _recolhidos.add(chave);
    });
  }

  @override
  Widget build(BuildContext context) {
    final historicoAsync = ref.watch(generalHistoryProvider);

    return SystemScaffold(
      title: 'HISTÓRICO',
      subtitle: 'LINHA DO TEMPO',
      leading: const SystemBackButton(),
      body: historicoAsync.when(
        data: (meses) {
          if (meses.isEmpty) {
            return const SystemEmptyState(
              icon: Icons.history,
              message: 'NENHUM REGISTRO NO HISTÓRICO',
              detail: 'Finalize um treino ou registre uma atividade.',
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < meses.length; i++) ...[
                if (i > 0) const SizedBox(height: SystemSpacing.lg),
                SystemEntrance(
                  key: ValueKey('mes-${meses[i].chave}'),
                  delay: SystemDurations.staggerStep * (i < 4 ? i : 4),
                  child: _MesSection(
                    mes: meses[i],
                    expandido: !_recolhidos.contains(meses[i].chave),
                    onAlternar: () => _alternar(meses[i].chave),
                  ),
                ),
              ],
            ],
          );
        },
        error: (error, stackTrace) => const SystemEmptyState(
          icon: Icons.error_outline,
          message: 'ERRO AO CARREGAR HISTÓRICO',
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: SystemPalette.primary),
        ),
      ),
    );
  }
}

class _MesSection extends StatelessWidget {
  const _MesSection({
    required this.mes,
    required this.expandido,
    required this.onAlternar,
  });

  final HistoryMonth mes;
  final bool expandido;
  final VoidCallback onAlternar;

  @override
  Widget build(BuildContext context) {
    final total = mes.total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: expandido,
          label: '${_nomesDosMeses[mes.mes - 1]} ${mes.ano}',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onAlternar,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: SystemSpacing.md, vertical: SystemSpacing.md),
              decoration: BoxDecoration(
                color: SystemPalette.surface2
                    .withValues(alpha: SystemOpacities.surface2),
                border: Border.all(
                  color: SystemPalette.primary
                      .withValues(alpha: SystemOpacities.border),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    expandido
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    size: 22,
                    color: SystemPalette.primary,
                  ),
                  const SizedBox(width: SystemSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_nomesDosMeses[mes.mes - 1]} ${mes.ano}',
                          style: SystemTextStyles.displaySmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          total == 1 ? '1 REGISTRO' : '$total REGISTROS',
                          style: SystemTextStyles.label.copyWith(
                            fontSize: 8.8,
                            color: SystemPalette.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (expandido) ...[
          const SizedBox(height: SystemSpacing.md),
          for (var i = 0; i < mes.registros.length; i++) ...[
            if (i > 0) const SizedBox(height: SystemSpacing.md),
            switch (mes.registros[i]) {
              WorkoutHistoryEntry(:final sessao) =>
                _SessionCard(sessao: sessao),
              SportHistoryEntry(:final atividade) =>
                _SportCard(atividade: atividade),
            },
          ],
        ],
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.sessao});

  final WorkoutSessionSummary sessao;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/sessions/${sessao.id}'),
      child: SystemPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.fitness_center,
                    size: 16, color: SystemPalette.primary),
                const SizedBox(width: SystemSpacing.sm),
                Expanded(
                  child: Text(
                    sessao.nome.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SystemTextStyles.displaySmall,
                  ),
                ),
                const Icon(Icons.chevron_right,
                    size: 18, color: SystemPalette.mutedForeground),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              _formatarData(sessao.data),
              style: SystemTextStyles.label.copyWith(
                fontSize: 9.6,
                color: SystemPalette.violet,
              ),
            ),
            const SizedBox(height: SystemSpacing.md),
            Row(
              children: [
                Expanded(
                  child: SystemStatBox(
                    label: 'EXERCÍCIOS',
                    value: '${sessao.totalExercicios}',
                  ),
                ),
                const SizedBox(width: SystemSpacing.sm),
                Expanded(
                  child: SystemStatBox(
                    label: 'VOLUME',
                    value: '${sessao.volumeTotal.toStringAsFixed(0)} KG',
                  ),
                ),
                const SizedBox(width: SystemSpacing.sm),
                Expanded(
                  child: SystemStatBox(
                    label: 'DURAÇÃO',
                    value: sessao.duracaoSegundos == null
                        ? '—'
                        : _formatarDuracao(sessao.duracaoSegundos!),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  String _formatarDuracao(int segundosTotais) {
    final minutos = (segundosTotais ~/ 60).toString().padLeft(2, '0');
    final segundos = (segundosTotais % 60).toString().padLeft(2, '0');
    return '$minutos:$segundos';
  }
}

class _SportCard extends StatelessWidget {
  const _SportCard({required this.atividade});

  final SportActivity atividade;

  @override
  Widget build(BuildContext context) {
    final metrica = metricaDerivada(atividade);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () =>
          context.push('/activities/${atividade.tipo.name}/${atividade.id}'),
      child: SystemPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(iconeDaModalidade(atividade.tipo),
                    size: 16, color: SystemPalette.violet),
                const SizedBox(width: SystemSpacing.sm),
                Expanded(
                  child: Text(
                    atividade.tipo.nome.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SystemTextStyles.displaySmall,
                  ),
                ),
                const Icon(Icons.chevron_right,
                    size: 18, color: SystemPalette.mutedForeground),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              formatarDataCurta(atividade.data, comAno: true),
              style: SystemTextStyles.label.copyWith(
                fontSize: 9.6,
                color: SystemPalette.violet,
              ),
            ),
            const SizedBox(height: SystemSpacing.sm),
            Text(
              resumoDaAtividade(atividade),
              style: SystemTextStyles.displaySmall.copyWith(fontSize: 14),
            ),
            if (metrica != null) ...[
              const SizedBox(height: 2),
              Text(
                metrica,
                style: SystemTextStyles.label.copyWith(
                  fontSize: 9.6,
                  color: SystemPalette.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

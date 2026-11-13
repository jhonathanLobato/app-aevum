import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/system_colors.dart';
import '../../../design_system/system_empty_state.dart';
import '../../../design_system/system_entrance.dart';
import '../../../design_system/system_motion.dart';
import '../../../design_system/system_panel.dart';
import '../../../design_system/system_scaffold.dart';
import '../../../design_system/system_spacing.dart';
import '../../../design_system/system_text_styles.dart';
import '../../profile/presentation/profile_providers.dart';
import '../../daily/presentation/daily_providers.dart';
import '../../rank_exam/presentation/rank_exam_providers.dart';
import '../../rank_exam/presentation/widgets/rank_summary_card.dart';
import '../../system_home/presentation/widgets/home_daily_panel.dart';
import '../../rank_exam/domain/rank_exam.dart';
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
    final semanais =
        missoes.where((m) => m.tipo == MissionType.semanal).toList();
    final desafios =
        missoes.where((m) => m.tipo == MissionType.desafio).toList();
    final historicoAsync = ref.watch(missionRecentHistoryProvider);
    final concluidas = (historicoAsync.valueOrNull ?? const <Mission>[])
        .where((m) => m.tipo != MissionType.diaria)
        .toList();
    final penalidade = ref.watch(pendingPenaltyProvider).valueOrNull ?? 0;
    final faseExame = ref.watch(rankStatusProvider).valueOrNull?.fase;
    final temExame = faseExame == RankExamPhase.disponivel ||
        faseExame == RankExamPhase.emAndamento;

    // Cada bloco é chaveado pelo próprio grupo (não pela posição), então se o
    // histórico aparecer depois os blocos já na tela não repetem a entrada.
    final blocos = <String, Widget>{
      'diaria': const Padding(
        padding: EdgeInsets.only(bottom: SystemSpacing.md),
        child: HomeDailyPanel(),
      ),
      if (penalidade > 0)
        'penalidade': Padding(
          padding: const EdgeInsets.only(bottom: SystemSpacing.md),
          child: SystemPanel(
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: SystemPalette.destructive),
                const SizedBox(width: SystemSpacing.md),
                Expanded(
                  child: Text(
                    'PENALIDADE: -$penalidade XP por missão diária não cumprida.',
                    style: SystemTextStyles.label
                        .copyWith(color: SystemPalette.destructive),
                  ),
                ),
              ],
            ),
          ),
        ),
      if (semanais.isNotEmpty)
        'semanais': _MissionGroup('SEMANAL', semanais, userRank),
      if (semanais.isEmpty)
        'semanal_vazia': const Padding(
          padding: EdgeInsets.only(bottom: SystemSpacing.md),
          child: SystemEmptyState(
            icon: Icons.event_available_outlined,
            message: 'SEM MISSÃO SEMANAL',
            detail: 'Marque seus dias de treino em Treinos › Minha semana.',
          ),
        ),
      if (desafios.isNotEmpty)
        'desafios': _MissionGroup('DESAFIOS', desafios, userRank),
      if (temExame)
        'exame': const Padding(
          padding: EdgeInsets.only(bottom: SystemSpacing.md),
          child: RankSummaryCard(),
        ),
      if (concluidas.isNotEmpty)
        'historico':
            _MissionGroup('CONCLUÍDAS RECENTEMENTE', concluidas, userRank),
      'quadro': _MissionBoard(
        semanalAtiva: semanais.isNotEmpty,
        desafioAtivo: desafios.isNotEmpty,
        diariaCumprida:
            ref.watch(dailyTodayProvider).valueOrNull?.concluida ?? false,
        exame: ref.watch(rankStatusProvider).valueOrNull,
      ),
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

enum _EstadoMissao { ativa, cumprida, disponivel, bloqueada }

/// Todas as missões do Sistema com o estado atual de cada uma: o que já está
/// ativo e o que ainda está bloqueado (com o que falta para liberar).
class _MissionBoard extends StatelessWidget {
  const _MissionBoard({
    required this.semanalAtiva,
    required this.desafioAtivo,
    required this.diariaCumprida,
    required this.exame,
  });

  final bool semanalAtiva;
  final bool desafioAtivo;
  final bool diariaCumprida;
  final RankStatus? exame;

  @override
  Widget build(BuildContext context) {
    final linhas = <Widget>[
      _linha(
        icone: Icons.today,
        nome: 'Missão de hoje',
        estado: diariaCumprida ? _EstadoMissao.cumprida : _EstadoMissao.ativa,
        detalhe: diariaCumprida
            ? 'Cumprida hoje. Uma nova começa amanhã.'
            : '50 flexões, 50 abdominais e 2 km. Todos os dias.',
      ),
      _linha(
        icone: Icons.event_available,
        nome: 'Missão da semana',
        estado: semanalAtiva ? _EstadoMissao.ativa : _EstadoMissao.bloqueada,
        detalhe: semanalAtiva
            ? 'Conclua todos os treinos programados da semana.'
            : 'Marque seus dias de treino em Treinos › Minha semana.',
      ),
      _linha(
        icone: Icons.trending_up,
        nome: 'Desafio de carga',
        estado: desafioAtivo ? _EstadoMissao.ativa : _EstadoMissao.bloqueada,
        detalhe: desafioAtivo
            ? 'Supere seu recorde de carga no exercício.'
            : 'Bata um recorde de carga em um exercício para liberar o desafio dele.',
      ),
    ];

    final e = exame;
    if (e != null) {
      final _EstadoMissao estado;
      final String detalhe;
      switch (e.fase) {
        case RankExamPhase.maximo:
          estado = _EstadoMissao.cumprida;
          detalhe = 'Você já está no rank máximo.';
        case RankExamPhase.emAndamento:
          estado = _EstadoMissao.ativa;
          detalhe = 'Exame para o rank ${e.proximoRank} em andamento.';
        case RankExamPhase.disponivel:
          estado = _EstadoMissao.disponivel;
          detalhe =
              'Exame para o rank ${e.proximoRank} liberado. Inicie na tela de Rank.';
        case RankExamPhase.bloqueado:
          estado = _EstadoMissao.bloqueada;
          final faltas = [
            if (e.niveisFaltando > 0)
              '${e.niveisFaltando} ${e.niveisFaltando == 1 ? 'nível' : 'níveis'}',
            if (e.experienciaFaltando > 0)
              '${formatarExperiencia(e.experienciaFaltando)} pontos de experiência',
          ];
          detalhe = faltas.isEmpty
              ? 'Quase liberado.'
              : 'Para liberar faltam ${faltas.join(' e ')}.';
      }
      linhas.add(_linha(
        icone: Icons.military_tech,
        nome: 'Exame de rank',
        estado: estado,
        detalhe: detalhe,
      ));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: SystemSpacing.md),
      child: SystemPanel(
        title: 'TODAS AS MISSÕES',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < linhas.length; i++) ...[
              if (i > 0) const SizedBox(height: SystemSpacing.md),
              linhas[i],
            ],
          ],
        ),
      ),
    );
  }

  Widget _linha({
    required IconData icone,
    required String nome,
    required _EstadoMissao estado,
    required String detalhe,
  }) {
    final (rotulo, cor) = switch (estado) {
      _EstadoMissao.ativa => ('ATIVA', SystemPalette.primary),
      _EstadoMissao.cumprida => ('CUMPRIDA', SystemPalette.gold),
      _EstadoMissao.disponivel => ('LIBERADA', SystemPalette.gold),
      _EstadoMissao.bloqueada => ('BLOQUEADA', SystemPalette.mutedForeground),
    };
    final bloqueada = estado == _EstadoMissao.bloqueada;
    return Opacity(
      opacity: bloqueada ? 0.7 : 1,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(bloqueada ? Icons.lock_outline : icone, size: 20, color: cor),
          const SizedBox(width: SystemSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(nome.toUpperCase(),
                          style: SystemTextStyles.label),
                    ),
                    Text(rotulo,
                        style: SystemTextStyles.label.copyWith(color: cor)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(detalhe,
                    style: SystemTextStyles.body
                        .copyWith(color: SystemPalette.mutedForeground)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

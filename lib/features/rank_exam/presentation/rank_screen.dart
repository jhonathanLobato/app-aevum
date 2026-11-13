import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/rank_badge.dart';
import '../../../design_system/system_back_button.dart';
import '../../../design_system/system_button.dart';
import '../../../design_system/system_colors.dart';
import '../../../design_system/system_empty_state.dart';
import '../../../design_system/system_panel.dart';
import '../../../design_system/system_scaffold.dart';
import '../../../design_system/system_spacing.dart';
import '../../../design_system/system_text_styles.dart';
import '../../profile/domain/level_curve.dart';
import '../domain/rank_exam.dart';
import 'rank_exam_providers.dart';
import 'widgets/rank_exam_progress.dart';
import 'widgets/rank_summary_card.dart';

/// Tela de Rank: lugar único de tudo sobre rank e exame — como funciona,
/// o que falta para liberar o próximo exame, o progresso do exame em
/// andamento e o botão de iniciar.
class RankScreen extends ConsumerWidget {
  const RankScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(rankStatusProvider);

    return SystemScaffold(
      title: 'RANK',
      subtitle: 'EXAME DE REAVALIAÇÃO',
      leading: const SystemBackButton(),
      body: statusAsync.when(
        data: (status) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (status != null) ...[
              _Situacao(status: status),
              const SizedBox(height: SystemSpacing.lg),
            ],
            const _ComoFunciona(),
          ],
        ),
        loading: () => const Center(
            child: CircularProgressIndicator(color: SystemPalette.primary)),
        error: (error, stackTrace) => const SystemEmptyState(
            icon: Icons.error_outline, message: 'ERRO AO CARREGAR O RANK'),
      ),
    );
  }
}

class _Situacao extends ConsumerWidget {
  const _Situacao({required this.status});

  final RankStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SystemPanel(
      glow: true,
      title: 'SUA SITUAÇÃO',
      action: RankBadge(rank: status.rankAtual, size: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('RANK ${status.rankAtual} · NÍVEL ${status.nivel}',
              style: SystemTextStyles.displaySmall),
          const SizedBox(height: SystemSpacing.md),
          switch (status.fase) {
            RankExamPhase.maximo => Text(
                'Você alcançou o rank máximo.',
                style: SystemTextStyles.body
                    .copyWith(color: SystemPalette.mutedForeground),
              ),
            RankExamPhase.bloqueado => _Bloqueado(status: status),
            RankExamPhase.disponivel => _Disponivel(status: status),
            RankExamPhase.emAndamento => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('EXAME PARA ${status.proximoRank} EM ANDAMENTO',
                      style: SystemTextStyles.label
                          .copyWith(color: SystemPalette.primary)),
                  const SizedBox(height: SystemSpacing.md),
                  RankExamProgress(exame: status.exame!),
                ],
              ),
          },
        ],
      ),
    );
  }
}

class _Bloqueado extends StatelessWidget {
  const _Bloqueado({required this.status});

  final RankStatus status;

  @override
  Widget build(BuildContext context) {
    final dias = status.diasParaLiberarPorTempo(DateTime.now());
    final nivelOk = status.niveisFaltando == 0;
    final tempoOk = dias == 0;
    Widget linha(bool ok, String texto) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(ok ? Icons.check_circle : Icons.lock_outline,
                  size: 16,
                  color: ok ? SystemPalette.success : SystemPalette.gold),
              const SizedBox(width: SystemSpacing.sm),
              Expanded(child: Text(texto, style: SystemTextStyles.body)),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('PRÓXIMO EXAME (${status.proximoRank}) BLOQUEADO',
            style: SystemTextStyles.label
                .copyWith(color: SystemPalette.mutedForeground)),
        const SizedBox(height: SystemSpacing.sm),
        linha(
            nivelOk,
            nivelOk
                ? 'Nível ${status.nivelMinimo} atingido.'
                : 'Faltam ${status.niveisFaltando} ${status.niveisFaltando == 1 ? 'nível' : 'níveis'} (precisa do nível ${status.nivelMinimo}; você está no ${status.nivel}).'),
        linha(
            tempoOk,
            tempoOk
                ? 'Tempo mínimo no rank ${status.rankAtual} cumprido (${status.mesesMinimos} meses).'
                : 'Faltam $dias dias no rank ${status.rankAtual} (mínimo de ${status.mesesMinimos} meses; liberado em ${formatarDiaMes(status.liberaPorTempoEm)}).'),
        const SizedBox(height: 2),
        Text('O exame libera quando o nível E o tempo forem cumpridos.',
            style: SystemTextStyles.body
                .copyWith(color: SystemPalette.mutedForeground)),
      ],
    );
  }
}

class _Disponivel extends ConsumerWidget {
  const _Disponivel({required this.status});

  final RankStatus status;

  Future<void> _iniciar(BuildContext context, WidgetRef ref) async {
    final spec = status.spec!;
    final escolha = await escolherAtividadesExtras(
      context,
      quantidade: spec.modalidades,
      registrosPorModalidade: spec.registrosPorModalidade,
    );
    if (escolha == null || !context.mounted) return;
    final resultado =
        await ref.read(rankExamRepositoryProvider).iniciarExame(escolha);
    if (!context.mounted) return;
    final mensagem = switch (resultado) {
      IniciarExameResultado.iniciado => 'Exame iniciado. Boa sorte!',
      IniciarExameResultado.precisaProgramar =>
        'Programe pelo menos ${RankExamValues.minDiasProgramados} dias de treino por semana em Treinos › Minha semana.',
      IniciarExameResultado.modalidadesInvalidas =>
        'Escolha exatamente ${spec.modalidades} atividades extras.',
      IniciarExameResultado.indisponivel => 'O exame não está mais disponível.',
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spec = status.spec!;
    final ultimoDia =
        status.inicioAutomaticoEm!.subtract(const Duration(days: 1));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('EXAME PARA ${status.proximoRank} DISPONÍVEL',
            style: SystemTextStyles.label.copyWith(color: SystemPalette.gold)),
        const SizedBox(height: SystemSpacing.sm),
        Text(
          'Inicie até ${formatarDiaMes(ultimoDia)} escolhendo ${spec.modalidades} atividades extras. '
          'Se não iniciar, ele começa sozinho em ${formatarDiaMes(status.inicioAutomaticoEm!)}, '
          'com as atividades que você mais registrou. O prazo de ${spec.prazoDias} dias conta a partir do início.',
          style: SystemTextStyles.body,
        ),
        if (status.precisaProgramar) ...[
          const SizedBox(height: SystemSpacing.sm),
          Text(
            'Para iniciar é preciso ter pelo menos ${RankExamValues.minDiasProgramados} dias de treino programados por semana (hoje: ${status.diasProgramadosPorSemana}). Ajuste em Treinos › Minha semana.',
            style: SystemTextStyles.body.copyWith(color: SystemPalette.gold),
          ),
        ],
        const SizedBox(height: SystemSpacing.md),
        SystemButton(
          key: const Key('iniciar_exame'),
          label: 'Iniciar exame',
          variant: SystemButtonVariant.action,
          size: SystemButtonSize.lg,
          icon: const Icon(Icons.play_arrow,
              size: 16, color: SystemPalette.foreground),
          onPressed:
              status.precisaProgramar ? null : () => _iniciar(context, ref),
        ),
        if (status.precisaProgramar) ...[
          const SizedBox(height: SystemSpacing.sm),
          SystemButton(
            label: 'Ajustar minha semana',
            onPressed: () => context.push('/week'),
          ),
        ],
      ],
    );
  }
}

class _ComoFunciona extends StatelessWidget {
  const _ComoFunciona();

  @override
  Widget build(BuildContext context) {
    const ordem = ['E', 'D', 'C', 'B', 'A', 'S'];
    final anterior = {
      for (var i = 0; i < ordem.length; i++)
        ordem[i]: i == 0 ? 'F' : ordem[i - 1],
    };
    const mesesPorRank = RankExamValues.mesesMinimosNoRank;

    return SystemPanel(
      title: 'COMO FUNCIONA',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'O nível sobe com o XP, mas o rank só sobe ao passar no exame de '
            'reavaliação. O exame libera quando você cumpre o nível mínimo E o '
            'tempo mínimo no rank atual.',
            style: SystemTextStyles.body,
          ),
          const SizedBox(height: SystemSpacing.md),
          Text('RANKS E EXAMES',
              style: SystemTextStyles.label
                  .copyWith(color: SystemPalette.primary)),
          const SizedBox(height: SystemSpacing.sm),
          for (final rank in ordem) ...[
            _LinhaRank(
              rank: rank,
              de: anterior[rank]!,
              meses: mesesPorRank[anterior[rank]]!,
              spec: RankExamValues.specs[rank]!,
            ),
            const SizedBox(height: SystemSpacing.sm),
          ],
          const SizedBox(height: SystemSpacing.xs),
          Text('REGRAS',
              style: SystemTextStyles.label
                  .copyWith(color: SystemPalette.primary)),
          const SizedBox(height: SystemSpacing.sm),
          for (final regra in const [
            'Janela de ${RankExamValues.janelaParaIniciarDias} dias: ao ser liberado, você tem ${RankExamValues.janelaParaIniciarDias} dias para iniciar o exame e escolher as atividades extras. No dia seguinte ele começa sozinho, com as atividades que você mais registrou.',
            'O prazo do exame conta a partir do início. Para iniciar é preciso ter ${RankExamValues.minDiasProgramados}+ dias de treino programados por semana.',
            'Treinos: meta = % dos treinos programados no período, arredondada para cima, mostrada em número absoluto.',
            'Missão diária: % dos dias do período cumpridos. Folga tira o dia do cálculo e, se era dia de treino, tira aquele treino da meta.',
            'Atividades extras: modalidades escolhidas, registros de 30+ min, na quantidade indicada.',
            'Durante o exame a programação semanal pode ganhar dias, mas não perder.',
            'Reinício: se a meta de treinos ou de missões ficar matematicamente impossível, ou o prazo acabar incompleto, o progresso zera e abre uma nova janela de ${RankExamValues.janelaParaIniciarDias} dias para iniciar de novo.',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: SystemSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6, right: 8),
                    child: Icon(Icons.circle,
                        size: 5, color: SystemPalette.primary),
                  ),
                  Expanded(child: Text(regra, style: SystemTextStyles.body)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LinhaRank extends StatelessWidget {
  const _LinhaRank({
    required this.rank,
    required this.de,
    required this.meses,
    required this.spec,
  });

  final String rank;
  final String de;
  final int meses;
  final RankExamSpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SystemSpacing.md),
      decoration: BoxDecoration(
        color:
            SystemPalette.surface2.withValues(alpha: SystemOpacities.surface2),
        border: Border(
          left: BorderSide(
              color: SystemPalette.primary.withValues(alpha: 0.5), width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$de → $rank',
              style: SystemTextStyles.displaySmall.copyWith(fontSize: 14)),
          const SizedBox(height: 2),
          Text(
            'NÍVEL ${nivelMinimoDoRank(rank)} · $meses MESES NO RANK $de',
            style: SystemTextStyles.label.copyWith(color: SystemPalette.gold),
          ),
          const SizedBox(height: 2),
          Text(
            'Prazo ${spec.prazoDias} dias · treinos ${(spec.fracaoTreinos * 100).round()}% · '
            'missão diária ${(spec.fracaoMissaoDiaria * 100).round()}% · '
            'extras ${spec.modalidades} atividades × ${spec.registrosPorModalidade}',
            style: SystemTextStyles.body,
          ),
        ],
      ),
    );
  }
}

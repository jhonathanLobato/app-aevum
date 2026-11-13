import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/rank_badge.dart';
import '../../../design_system/system_back_button.dart';
import '../../../design_system/system_button.dart';
import '../../../design_system/system_colors.dart';
import '../../../design_system/system_empty_state.dart';
import '../../../design_system/system_notice_dialog.dart';
import '../../../design_system/system_panel.dart';
import '../../../design_system/system_scaffold.dart';
import '../../../design_system/system_spacing.dart';
import '../../../design_system/system_text_styles.dart';
import '../../profile/domain/level_curve.dart';
import '../domain/rank_exam.dart';
import 'rank_exam_providers.dart';
import 'widgets/hunter_experience_bar.dart';
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
          Text(_resumo(status),
              key: const Key('rank_resumo'), style: SystemTextStyles.body),
          const SizedBox(height: SystemSpacing.md),
          Text('RANK ${status.rankAtual} · NÍVEL ${status.nivel}',
              style: SystemTextStyles.displaySmall),
          const SizedBox(height: SystemSpacing.md),
          if (status.proximoRank != null) ...[
            HunterExperienceBar(status: status),
            const SizedBox(height: SystemSpacing.md),
            _BotaoExame(status: status),
            const SizedBox(height: SystemSpacing.md),
          ],
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

String _plural(int n, String singular, String plural) =>
    '$n ${n == 1 ? singular : plural}';

String _pontos(double p) =>
    '${formatarExperiencia(p)} ${p == 1 ? 'ponto' : 'pontos'} de experiência';

/// O que falta (em números) para liberar o exame; vazio se nada falta.
List<String> _faltas(RankStatus s) => [
      if (s.niveisFaltando > 0) _plural(s.niveisFaltando, 'nível', 'níveis'),
      if (s.experienciaFaltando > 0) _pontos(s.experienciaFaltando),
    ];

String _juntar(List<String> itens) => itens.length <= 1
    ? itens.join()
    : '${itens.sublist(0, itens.length - 1).join(', ')} e ${itens.last}';

int _diasParaIniciar(RankStatus s) {
  final auto = s.inicioAutomaticoEm;
  if (auto == null) return 0;
  final dias =
      (auto.difference(apenasDataLocal(DateTime.now())).inHours / 24).round();
  return dias < 0 ? 0 : dias;
}

/// Frase única com o status do jogador, no topo da tela.
String _resumo(RankStatus s) {
  final inicio = 'Você é Rank ${s.rankAtual}.';
  switch (s.fase) {
    case RankExamPhase.maximo:
      return '$inicio Você alcançou o rank máximo do Sistema.';
    case RankExamPhase.bloqueado:
      final faltas = _faltas(s);
      return faltas.isEmpty
          ? '$inicio O exame para ${s.proximoRank} está quase liberado.'
          : '$inicio Para liberar o exame faltam ${_juntar(faltas)}.';
    case RankExamPhase.disponivel:
      final dias = _diasParaIniciar(s);
      return '$inicio O exame para ${s.proximoRank} está liberado. '
          'Você tem ${_plural(dias, 'dia', 'dias')} para iniciar.';
    case RankExamPhase.emAndamento:
      final dias = s.exame!.diasRestantes;
      return '$inicio O exame para ${s.proximoRank} está em andamento: '
          '${dias == 1 ? 'resta 1 dia' : 'restam $dias dias'}.';
  }
}

/// Botão "Iniciar exame": sempre visível; só ativo na janela de início.
class _BotaoExame extends ConsumerWidget {
  const _BotaoExame({required this.status});

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
    if (resultado == IniciarExameResultado.iniciado) {
      await showSystemNoticeDialog(
        context,
        titulo: 'Exame iniciado',
        icone: Icons.play_circle_outline,
        cor: SystemPalette.gold,
        mensagem:
            '[SISTEMA] O exame para o rank ${spec.rankAlvo} começou. Cumpra treinos, missões diárias e atividades extras dentro do prazo.',
        destaque: '${spec.prazoDias} DIAS',
      );
      return;
    }
    final mensagem = switch (resultado) {
      IniciarExameResultado.iniciado => '',
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
    final fase = status.fase;
    final emAndamento = fase == RankExamPhase.emAndamento;
    final ativo = fase == RankExamPhase.disponivel && !status.precisaProgramar;

    final String? motivo;
    if (emAndamento) {
      motivo = null;
    } else if (fase == RankExamPhase.bloqueado) {
      final faltas = _faltas(status);
      final partes = [
        if (faltas.isNotEmpty) 'faltam ${_juntar(faltas)}',
        if (status.precisaProgramar)
          'você tem menos de ${RankExamValues.minDiasProgramados} dias de treino programados por semana (hoje: ${status.diasProgramadosPorSemana})',
      ];
      motivo = partes.isEmpty
          ? 'Exame ainda não liberado.'
          : 'Exame bloqueado: ${_juntar(partes)}.';
    } else if (status.precisaProgramar) {
      motivo =
          'Programe pelo menos ${RankExamValues.minDiasProgramados} dias de treino por semana para iniciar (hoje: ${status.diasProgramadosPorSemana}).';
    } else {
      final dias = _diasParaIniciar(status);
      motivo = 'Restam ${_plural(dias, 'dia', 'dias')} para iniciar.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SystemButton(
          key: const Key('iniciar_exame'),
          label: emAndamento ? 'Exame em andamento' : 'Iniciar exame',
          variant: SystemButtonVariant.action,
          size: SystemButtonSize.lg,
          icon: Icon(emAndamento ? Icons.hourglass_top : Icons.play_arrow,
              size: 16, color: SystemPalette.foreground),
          onPressed: ativo ? () => _iniciar(context, ref) : null,
        ),
        if (motivo != null) ...[
          const SizedBox(height: SystemSpacing.sm),
          Text(
            motivo,
            key: const Key('iniciar_exame_motivo'),
            textAlign: TextAlign.center,
            style: SystemTextStyles.body.copyWith(
                color:
                    ativo ? SystemPalette.gold : SystemPalette.mutedForeground),
          ),
        ],
      ],
    );
  }
}

class _Bloqueado extends StatelessWidget {
  const _Bloqueado({required this.status});

  final RankStatus status;

  @override
  Widget build(BuildContext context) {
    final nivelOk = status.niveisFaltando == 0;
    final experienciaOk = status.experienciaFaltando == 0;
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
            experienciaOk,
            experienciaOk
                ? 'Experiência mínima atingida (${status.experienciaMinima} pontos).'
                : 'Faltam ${formatarExperiencia(status.experienciaFaltando)} pontos de experiência (precisa de ${status.experienciaMinima}; você tem ${formatarExperiencia(status.experiencia)}).'),
        const SizedBox(height: 2),
        Text('O exame libera quando o nível E a experiência forem cumpridos.',
            style: SystemTextStyles.body
                .copyWith(color: SystemPalette.mutedForeground)),
      ],
    );
  }
}

class _Disponivel extends ConsumerWidget {
  const _Disponivel({required this.status});

  final RankStatus status;

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

/// Explicação do rank em seções recolhíveis, em linguagem simples.
class _ComoFunciona extends StatelessWidget {
  const _ComoFunciona();

  @override
  Widget build(BuildContext context) {
    const ordem = ['E', 'D', 'C', 'B', 'A', 'S'];
    final anterior = {
      for (var i = 0; i < ordem.length; i++)
        ordem[i]: i == 0 ? 'F' : ordem[i - 1],
    };
    const experienciaPorRank = RankExamValues.experienciaMinimaNoRank;
    const janela = RankExamValues.janelaParaIniciarDias;

    return SystemPanel(
      title: 'COMO FUNCIONA',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Secao(
            id: 'o_que_e',
            titulo: 'O QUE É O RANK',
            textos: [
              'O rank é a sua patente de caçador. Ele vai de F (a mais baixa) até S (a mais alta).',
              'O nível sobe sozinho, com o XP que você ganha treinando.',
              'O rank é diferente: ele só sobe quando você passa no exame de reavaliação do Sistema.',
              'Por isso você pode ter nível alto e continuar no mesmo rank, até provar que está pronto.',
            ],
          ),
          const _Secao(
            id: 'como_subir',
            titulo: 'COMO SUBIR DE RANK',
            textos: [
              '1. Nível mínimo: chegue ao nível exigido pelo próximo rank (veja a tabela mais abaixo).',
              '2. Experiência de caçador: junte os pontos mínimos do seu rank atual.',
              '3. Exame: com os dois cumpridos, o Sistema libera o exame. Passe nele e o rank sobe.',
            ],
          ),
          const _Secao(
            id: 'experiencia',
            titulo: 'EXPERIÊNCIA DE CAÇADOR',
            textos: [
              'É uma pontuação à parte do XP. Mostra o quanto você realmente treinou dentro do rank.',
              'Treino de academia concluído: +1 ponto (no máximo um por dia).',
              'Atividade extra de ${RankExamValues.minutosMinimos}+ min: +0,5 ponto, contando no máximo ${RankExamValues.maxAtividadesPorSemana} por semana (segunda a domingo).',
              'A missão diária não dá experiência — ela já é exigida no exame.',
              'Ao subir de rank os pontos zeram e você começa de novo. O que passar do mínimo não é guardado.',
              'Se você editar ou excluir um registro, os pontos se ajustam sozinhos.',
            ],
          ),
          const _Secao(
            id: 'exame',
            titulo: 'O EXAME',
            textos: [
              'Quando o exame é liberado, você tem $janela dias para iniciar e escolher suas atividades extras. No 8º dia ele começa sozinho, com as atividades que você mais registrou.',
              'Para iniciar, é preciso ter ${RankExamValues.minDiasProgramados} ou mais dias de treino programados por semana.',
              'O prazo do exame (de 35 a 140 dias, conforme o rank) conta a partir do início.',
              'Para passar, cumpra tudo dentro do prazo:',
              'Treinos programados: uma porcentagem dos treinos marcados no período (arredondada para cima). A tela mostra a meta em número.',
              'Missão diária: uma porcentagem dos dias do período com a missão cumprida.',
              'Atividades extras: registros de ${RankExamValues.minutosMinimos}+ min nas modalidades escolhidas.',
              'Folgas: um dia de folga sai do cálculo da missão diária. Se era dia de treino, aquele treino também sai da meta.',
              'Durante o exame você pode adicionar dias de treino na semana, mas não pode tirar.',
            ],
          ),
          const _Secao(
            id: 'falhar',
            titulo: 'SE FALHAR',
            textos: [
              'O exame reinicia se a meta de treinos ou de missões ficar impossível de alcançar, ou se o prazo acabar com algo incompleto.',
              'Ao reiniciar, o progresso do exame zera e abre uma nova janela de $janela dias para iniciar de novo. Você escolhe as atividades extras outra vez.',
              'Você não perde rank, nível nem experiência por falhar. Só precisa tentar de novo.',
            ],
          ),
          _Secao(
            id: 'tabela',
            titulo: 'TABELA DE RANKS',
            filhos: [
              for (final rank in ordem) ...[
                _LinhaRank(
                  rank: rank,
                  de: anterior[rank]!,
                  experiencia: experienciaPorRank[anterior[rank]]!,
                  spec: RankExamValues.specs[rank]!,
                ),
                const SizedBox(height: SystemSpacing.sm),
              ],
            ],
          ),
          const _Secao(
            id: 'perguntas',
            titulo: 'PERGUNTAS RÁPIDAS',
            textos: [
              'Posso perder o rank? Não. O rank nunca cai.',
              'A missão diária conta como treino? Não. Ela é separada dos treinos de academia e não conta para a missão semanal, para o exame nem para a experiência.',
              'E se eu ficar doente? Marque uma folga (são 4 por mês). O dia sai da conta da missão diária e, se era dia de treino, o treino sai da meta.',
              'E se eu não iniciar o exame? Ele começa sozinho no 8º dia depois de liberado.',
              'Posso mudar meus dias de treino durante o exame? Pode adicionar dias, mas não tirar.',
              'Treinei mais de uma vez no mesmo dia. Conta tudo? Só um treino de academia por dia conta para a experiência e para o exame.',
            ],
            ultima: true,
          ),
        ],
      ),
    );
  }
}

/// Seção recolhível (fechada por padrão).
class _Secao extends StatefulWidget {
  const _Secao({
    required this.id,
    required this.titulo,
    this.textos = const [],
    this.filhos = const [],
    this.ultima = false,
  });

  final String id;
  final String titulo;
  final List<String> textos;
  final List<Widget> filhos;
  final bool ultima;

  @override
  State<_Secao> createState() => _SecaoState();
}

class _SecaoState extends State<_Secao> {
  bool _aberta = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: widget.ultima
              ? BorderSide.none
              : BorderSide(color: SystemPalette.primary.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: Key('rank_secao_${widget.id}'),
            onTap: () => setState(() => _aberta = !_aberta),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.titulo,
                        style: SystemTextStyles.label
                            .copyWith(color: SystemPalette.primary)),
                  ),
                  Icon(_aberta ? Icons.expand_less : Icons.expand_more,
                      color: SystemPalette.primary),
                ],
              ),
            ),
          ),
          if (_aberta) ...[
            for (final t in widget.textos) _Marcador(texto: t),
            ...widget.filhos,
          ],
        ],
      ),
    );
  }
}

class _Marcador extends StatelessWidget {
  const _Marcador({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SystemSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 8),
            child: Icon(Icons.circle, size: 5, color: SystemPalette.primary),
          ),
          Expanded(child: Text(texto, style: SystemTextStyles.body)),
        ],
      ),
    );
  }
}

class _LinhaRank extends StatelessWidget {
  const _LinhaRank({
    required this.rank,
    required this.de,
    required this.experiencia,
    required this.spec,
  });

  final String rank;
  final String de;
  final int experiencia;
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
            'NÍVEL ${nivelMinimoDoRank(rank)} · $experiencia DE EXPERIÊNCIA NO RANK $de',
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

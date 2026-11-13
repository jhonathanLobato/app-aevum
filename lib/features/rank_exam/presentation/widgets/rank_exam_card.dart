import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/rank_badge.dart';
import '../../../../design_system/system_button.dart';
import '../../../../design_system/system_colors.dart';
import '../../../../design_system/system_panel.dart';
import '../../../../design_system/system_progress_bar.dart';
import '../../../../design_system/system_spacing.dart';
import '../../../../design_system/system_text_styles.dart';
import '../../../activities/domain/sport_activity.dart';
import '../../domain/rank_exam.dart';
import '../rank_exam_providers.dart';

/// Card do exame de rank ativo: progresso de cada requisito e dias
/// restantes. [compacto] (tela Sistema) mostra só o resumo; o completo
/// (aba Missões) inclui a escolha das atividades extras.
class RankExamCard extends ConsumerWidget {
  const RankExamCard({super.key, this.compacto = false, this.onAbrir});

  final bool compacto;
  final VoidCallback? onAbrir;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exame = ref.watch(rankExamProvider).valueOrNull;
    if (exame == null) return const SizedBox.shrink();

    final card = SystemPanel(
      glow: true,
      title: 'EXAME DE RANK',
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RankBadge(rank: exame.rankAtual, size: 22),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.arrow_forward,
                size: 12, color: SystemPalette.primary),
          ),
          RankBadge(rank: exame.rankAlvo, size: 22),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            exame.diasRestantes == 1
                ? '1 DIA RESTANTE'
                : '${exame.diasRestantes} DIAS RESTANTES',
            style: SystemTextStyles.label.copyWith(color: SystemPalette.gold),
          ),
          const SizedBox(height: SystemSpacing.md),
          _Requisito(
            titulo: 'TREINOS DE ACADEMIA',
            atual: exame.treinosFeitos,
            total: exame.treinosNecessarios,
          ),
          const SizedBox(height: SystemSpacing.sm),
          _Requisito(
            titulo: 'MISSÕES DIÁRIAS (75%)',
            atual: exame.missoesCumpridas,
            total: exame.missoesNecessarias,
          ),
          const SizedBox(height: SystemSpacing.sm),
          _Requisito(
            titulo:
                'ATIVIDADES EXTRAS (${exame.registrosPorModalidade}× CADA, 30+ MIN)',
            atual: exame.modalidadesCumpridas,
            total: exame.modalidadesNecessarias,
          ),
          if (!compacto) ...[
            const SizedBox(height: SystemSpacing.md),
            if (exame.modalidades.isNotEmpty)
              for (final m in exame.modalidades)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      Icon(
                        m.cumprida
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 14,
                        color: m.cumprida
                            ? SystemPalette.success
                            : SystemPalette.mutedForeground,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                          child:
                              Text(m.tipo.nome, style: SystemTextStyles.body)),
                      Text('${m.registros}/${m.necessarios}',
                          style: SystemTextStyles.label),
                    ],
                  ),
                ),
            const SizedBox(height: SystemSpacing.sm),
            SystemButton(
              label: exame.modalidadesEscolhidas
                  ? 'Trocar atividades extras'
                  : 'Escolher ${exame.modalidadesNecessarias} atividades extras',
              variant: exame.modalidadesEscolhidas
                  ? SystemButtonVariant.ghost
                  : SystemButtonVariant.action,
              onPressed: () => _escolher(context, ref, exame),
            ),
          ],
        ],
      ),
    );

    if (onAbrir == null) return card;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onAbrir,
      child: card,
    );
  }

  Future<void> _escolher(
      BuildContext context, WidgetRef ref, RankExamState exame) async {
    final escolha = await showModalBottomSheet<List<SportType>>(
      context: context,
      backgroundColor: SystemPalette.background,
      isScrollControlled: true,
      builder: (_) => _EscolherModalidades(
        quantidade: exame.modalidadesNecessarias,
        inicial: [for (final m in exame.modalidades) m.tipo],
      ),
    );
    if (escolha != null) {
      await ref.read(rankExamRepositoryProvider).escolherModalidades(escolha);
    }
  }
}

class _Requisito extends StatelessWidget {
  const _Requisito(
      {required this.titulo, required this.atual, required this.total});

  final String titulo;
  final int atual;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ok = atual >= total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
                child: Text(titulo,
                    style: SystemTextStyles.label.copyWith(fontSize: 8.5))),
            Text('$atual / $total',
                style: SystemTextStyles.label.copyWith(
                    fontSize: 9,
                    color: ok ? SystemPalette.success : SystemPalette.primary)),
          ],
        ),
        const SizedBox(height: 4),
        SystemProgressBar(value: atual, max: total),
      ],
    );
  }
}

class _EscolherModalidades extends StatefulWidget {
  const _EscolherModalidades({required this.quantidade, required this.inicial});

  final int quantidade;
  final List<SportType> inicial;

  @override
  State<_EscolherModalidades> createState() => _EscolherModalidadesState();
}

class _EscolherModalidadesState extends State<_EscolherModalidades> {
  late final Set<SportType> _escolhidas = {...widget.inicial};

  @override
  Widget build(BuildContext context) {
    final completo = _escolhidas.length == widget.quantidade;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(SystemSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'ESCOLHA ${widget.quantidade} ATIVIDADES (${_escolhidas.length}/${widget.quantidade})',
              style: SystemTextStyles.displaySmall,
            ),
            const SizedBox(height: SystemSpacing.md),
            for (final tipo in SportType.values)
              CheckboxListTile(
                key: Key('exame_${tipo.name}'),
                value: _escolhidas.contains(tipo),
                title: Text(tipo.nome, style: SystemTextStyles.body),
                activeColor: SystemPalette.primary,
                dense: true,
                onChanged: (marcada) => setState(() {
                  if (marcada ?? false) {
                    if (_escolhidas.length < widget.quantidade) {
                      _escolhidas.add(tipo);
                    }
                  } else {
                    _escolhidas.remove(tipo);
                  }
                }),
              ),
            const SizedBox(height: SystemSpacing.md),
            SystemButton(
              label: 'Confirmar',
              variant: SystemButtonVariant.action,
              onPressed: completo
                  ? () => Navigator.of(context).pop(_escolhidas.toList())
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

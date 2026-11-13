import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/rank_badge.dart';
import '../../../../design_system/system_colors.dart';
import '../../../../design_system/system_panel.dart';
import '../../../../design_system/system_spacing.dart';
import '../../../../design_system/system_text_styles.dart';
import '../../domain/rank_exam.dart';
import '../rank_exam_providers.dart';

String formatarDiaMes(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

/// Resumo do rank e do estado do próximo exame em 1–2 linhas. Tocar abre a
/// tela de Rank. Com [somenteComExame] (Sistema/Missões) o card só aparece
/// quando há exame disponível ou em andamento.
class RankSummaryCard extends ConsumerWidget {
  const RankSummaryCard({super.key, this.somenteComExame = false});

  final bool somenteComExame;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(rankStatusProvider).valueOrNull;
    if (status == null) return const SizedBox.shrink();
    if (somenteComExame &&
        status.fase != RankExamPhase.disponivel &&
        status.fase != RankExamPhase.emAndamento) {
      return const SizedBox.shrink();
    }

    final (linha1, linha2, cor) = _textos(status);

    return GestureDetector(
      key: const Key('rank_card'),
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/rank'),
      child: SystemPanel(
        glow: status.fase == RankExamPhase.disponivel,
        title: 'RANK',
        action: const Icon(Icons.chevron_right,
            size: 18, color: SystemPalette.mutedForeground),
        child: Row(
          children: [
            RankBadge(rank: status.rankAtual, size: 44),
            const SizedBox(width: SystemSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('RANK ${status.rankAtual} · NÍVEL ${status.nivel}',
                      style: SystemTextStyles.displaySmall),
                  const SizedBox(height: 2),
                  Text(linha1,
                      style: SystemTextStyles.label
                          .copyWith(fontSize: 9, color: cor)),
                  if (linha2 != null)
                    Text(linha2,
                        style: SystemTextStyles.body
                            .copyWith(color: SystemPalette.mutedForeground)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String, String?, Color) _textos(RankStatus s) {
    switch (s.fase) {
      case RankExamPhase.maximo:
        return ('RANK MÁXIMO', null, SystemPalette.gold);
      case RankExamPhase.emAndamento:
        final e = s.exame!;
        return (
          'EXAME PARA ${s.proximoRank} EM ANDAMENTO',
          '${e.diasRestantes} dias restantes · treinos ${e.treinosFeitos}/${e.treinosNecessarios}',
          SystemPalette.primary,
        );
      case RankExamPhase.disponivel:
        final inicio = s.inicioAutomaticoEm!;
        return (
          'EXAME PARA ${s.proximoRank} DISPONÍVEL',
          'Inicie até ${formatarDiaMes(inicio.subtract(const Duration(days: 1)))}; depois ele começa sozinho.',
          SystemPalette.gold,
        );
      case RankExamPhase.bloqueado:
        final partes = <String>[
          if (s.niveisFaltando > 0)
            'faltam ${s.niveisFaltando} ${s.niveisFaltando == 1 ? 'nível' : 'níveis'} (nível ${s.nivelMinimo})',
          if (s.diasParaLiberarPorTempo(DateTime.now()) > 0)
            'faltam ${s.diasParaLiberarPorTempo(DateTime.now())} dias no rank',
        ];
        return (
          'PRÓXIMO EXAME (${s.proximoRank}) BLOQUEADO',
          partes.isEmpty ? 'Será liberado ao abrir o app.' : partes.join(' · '),
          SystemPalette.mutedForeground,
        );
    }
  }
}

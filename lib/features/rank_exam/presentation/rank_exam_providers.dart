import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../database/database_provider.dart';
import '../../../design_system/system_confirm_dialog.dart';
import '../../achievements/presentation/achievement_providers.dart';
import '../../achievements/presentation/achievement_unlocked_dialog.dart';
import '../../profile/presentation/level_up_overlay.dart';
import '../../profile/presentation/profile_providers.dart';
import '../data/rank_exam_repository_impl.dart';
import '../domain/rank_exam.dart';
import '../domain/rank_exam_repository.dart';

final rankExamRepositoryProvider = Provider<RankExamRepository>((ref) {
  return DriftRankExamRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(profileRepositoryProvider),
  );
});

/// Situação do jogador diante do próximo rank/exame.
final rankStatusProvider = StreamProvider<RankStatus?>((ref) {
  return ref.watch(rankExamRepositoryProvider).watchStatus();
});

/// Sincroniza o exame de rank (libera, inicia sozinho, aprova ou reinicia) e
/// avisa o usuário com mensagens no estilo Sistema / overlay de RANK UP.
Future<void> sincronizarExame(BuildContext context, WidgetRef ref) async {
  final eventos = await ref.read(rankExamRepositoryProvider).sincronizar();
  for (final evento in eventos) {
    if (!context.mounted) return;
    switch (evento.tipo) {
      case RankExamEventType.aprovado:
        await showLevelUpOverlay(
          context,
          nivelAnterior: 0,
          novoNivel: 0,
          rankAnterior: evento.rankAnterior,
          novoRank: evento.rankAlvo,
          rankUp: true,
        );
        await ref
            .read(rankExamRepositoryProvider)
            .confirmarRankUp(evento.rankAlvo);
        final conquistas =
            await ref.read(achievementRepositoryProvider).verificarRank();
        if (conquistas.isNotEmpty && context.mounted) {
          await showAchievementsUnlockedDialog(context, conquistas);
        }
      case RankExamEventType.liberado:
        final ver = await showSystemConfirmDialog(
          context,
          titulo: '[SISTEMA] Exame de reavaliação disponível',
          mensagem:
              'O exame para o rank ${evento.rankAlvo} foi liberado. Você tem ${RankExamValues.janelaParaIniciarDias} dias para iniciá-lo, escolhendo suas atividades extras. Depois disso ele começa sozinho.',
          confirmar: 'Ver exame',
          cancelar: 'Depois',
          icone: Icons.military_tech_outlined,
        );
        if (ver && context.mounted) await context.push('/rank');
      case RankExamEventType.iniciadoAutomaticamente:
        await showSystemConfirmDialog(
          context,
          titulo: '[SISTEMA] Exame iniciado',
          mensagem:
              'A janela de ${RankExamValues.janelaParaIniciarDias} dias acabou e o exame para o rank ${evento.rankAlvo} começou. Atividades extras escolhidas automaticamente (as que você mais registrou): ${evento.modalidades.map((m) => m.nome).join(', ')}.',
          confirmar: 'Entendi',
          cancelar: 'Fechar',
          icone: Icons.play_circle_outline,
        );
      case RankExamEventType.reiniciado:
        final motivo = switch (evento.motivo) {
          RankExamResetReason.prazo =>
            'O prazo do exame acabou com requisitos incompletos.',
          RankExamResetReason.treinosImpossivel =>
            'Ficou impossível cumprir a meta de treinos programados neste período.',
          _ =>
            'Ficou impossível cumprir a meta de missões diárias neste período.',
        };
        await showSystemConfirmDialog(
          context,
          titulo: '[SISTEMA] Exame reiniciado',
          mensagem:
              '$motivo O progresso foi zerado e abriu uma nova janela de ${RankExamValues.janelaParaIniciarDias} dias para você iniciar o exame de novo.',
          confirmar: 'Entendi',
          cancelar: 'Fechar',
          icone: Icons.refresh,
          destrutivo: true,
        );
    }
  }
}

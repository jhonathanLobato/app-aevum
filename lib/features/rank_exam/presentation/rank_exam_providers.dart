import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/system_confirm_dialog.dart';
import '../../../database/database_provider.dart';
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

final rankExamProvider = StreamProvider<RankExamState?>((ref) {
  return ref.watch(rankExamRepositoryProvider).watchAtivo();
});

/// Sincroniza o exame de rank (libera, aprova ou reinicia) e avisa o usuário
/// com mensagens no estilo Sistema / overlay de RANK UP.
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
        final conquistas =
            await ref.read(achievementRepositoryProvider).verificarRank();
        if (conquistas.isNotEmpty && context.mounted) {
          await showAchievementsUnlockedDialog(context, conquistas);
        }
      case RankExamEventType.liberado:
        await showSystemConfirmDialog(
          context,
          titulo: 'Exame de rank liberado',
          mensagem:
              'O Sistema abriu o exame para o rank ${evento.rankAlvo}. Veja os requisitos na aba Missões e escolha suas atividades extras.',
          confirmar: 'Entendi',
          cancelar: 'Depois',
          icone: Icons.military_tech_outlined,
        );
      case RankExamEventType.reiniciado:
        await showSystemConfirmDialog(
          context,
          titulo: 'Exame reiniciado',
          mensagem: evento.motivo == RankExamResetReason.prazo
              ? 'O prazo do exame acabou com requisitos incompletos. O progresso foi zerado e um novo período começou agora.'
              : 'Ficou impossível cumprir 75% das missões diárias neste período. O progresso foi zerado e um novo período começou agora.',
          confirmar: 'Entendi',
          cancelar: 'Fechar',
          icone: Icons.refresh,
          destrutivo: true,
        );
    }
  }
}

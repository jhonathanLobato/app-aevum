import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'achievement_providers.dart';
import 'achievement_unlocked_dialog.dart';

/// Reavalia todas as conquistas (concedendo o XP das novas) e mostra o aviso
/// se alguma desbloqueou. Chamado depois de ações fora do treino: atividade,
/// registro corporal, missão diária e virada do dia.
Future<void> conferirConquistas(BuildContext context, WidgetRef ref) async {
  try {
    final novas = await ref.read(achievementRepositoryProvider).verificarTudo();
    if (novas.isNotEmpty && context.mounted) {
      await showAchievementsUnlockedDialog(context, novas);
    }
  } catch (_) {
    // Conquistas nunca devem atrapalhar a ação principal.
  }
}

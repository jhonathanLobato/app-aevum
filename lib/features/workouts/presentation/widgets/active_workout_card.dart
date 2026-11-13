import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/system_button.dart';
import '../../../../design_system/system_colors.dart';
import '../../../../design_system/system_confirm_dialog.dart';
import '../../../../design_system/system_panel.dart';
import '../../../../design_system/system_spacing.dart';
import '../../../../design_system/system_text_styles.dart';
import '../../domain/workout_session.dart';
import '../workout_session_providers.dart';

/// Cartão "TREINO EM ANDAMENTO": aparece (Home e aba Treinos) enquanto existir
/// uma sessão não finalizada. Continuar reabre a sessão com tudo que já foi
/// registrado; descartar pede confirmação. Some sozinho quando não há treino
/// em andamento (e já inclui o espaçamento de baixo, pra não deixar um vão).
class ActiveWorkoutCard extends ConsumerWidget {
  const ActiveWorkoutCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ativo = ref.watch(activeWorkoutProvider).valueOrNull;
    if (ativo == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: SystemSpacing.lg),
      child: SystemPanel(
        glow: true,
        title: 'TREINO EM ANDAMENTO',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ativo.nome.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SystemTextStyles.displayMedium,
            ),
            const SizedBox(height: 2),
            Text(
              '${_iniciadoEm(ativo.data)} · ${_series(ativo.totalSeries)}',
              style: SystemTextStyles.label.copyWith(
                fontSize: 9.6,
                color: SystemPalette.primary,
              ),
            ),
            const SizedBox(height: SystemSpacing.md),
            SystemButton(
              label: 'Continuar treino',
              variant: SystemButtonVariant.action,
              icon: const Icon(Icons.play_arrow,
                  size: 16, color: SystemPalette.foreground),
              onPressed: () => context.push('/sessions/${ativo.id}'),
            ),
            const SizedBox(height: SystemSpacing.sm),
            SystemButton(
              label: 'Descartar treino',
              icon: const Icon(Icons.delete_outline,
                  size: 16, color: SystemPalette.foreground),
              onPressed: () => descartarTreino(context, ref, ativo),
            ),
          ],
        ),
      ),
    );
  }

  static String _series(int total) =>
      total == 1 ? '1 SÉRIE REGISTRADA' : '$total SÉRIES REGISTRADAS';

  /// "INICIADO HOJE" ou "INICIADO EM 04/10" (treino esquecido de outro dia).
  static String _iniciadoEm(DateTime data) => formatarInicio(data);
}

String formatarInicio(DateTime data, {DateTime? agora}) {
  final hoje = agora ?? DateTime.now();
  final mesmoDia = data.year == hoje.year &&
      data.month == hoje.month &&
      data.day == hoje.day;
  if (mesmoDia) return 'INICIADO HOJE';
  return 'INICIADO EM ${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}';
}

/// Confirma e descarta o treino em andamento (apaga as séries dele). O XP
/// e os recordes já concedidos não são desfeitos.
Future<bool> descartarTreino(
  BuildContext context,
  WidgetRef ref,
  ActiveWorkoutInfo ativo,
) async {
  final confirmar = await showSystemConfirmDialog(
    context,
    titulo: 'Descartar treino?',
    mensagem:
        'As séries deste treino em andamento serão apagadas. O XP e os recordes que você já ganhou nele continuam. Esta ação não pode ser desfeita.',
    confirmar: 'Descartar',
    icone: Icons.delete_outline,
    destrutivo: true,
  );
  if (!confirmar) return false;

  ref.read(workoutDraftsProvider).limparSessao(ativo.id);
  await ref.read(workoutSessionRepositoryProvider).discard(ativo.id);
  return true;
}

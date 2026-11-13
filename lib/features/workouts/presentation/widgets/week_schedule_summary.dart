import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/system_colors.dart';
import '../../../../design_system/system_panel.dart';
import '../../../../design_system/system_spacing.dart';
import '../../../../design_system/system_text_styles.dart';
import '../../../daily/presentation/daily_providers.dart';

const nomesCurtosDosDias = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

/// "Seg · Qua · Sex" (ou "Nenhum dia marcado").
String resumoDosDias(Set<int> dias) {
  final ordenados = dias.toList()..sort();
  if (ordenados.isEmpty) return 'Nenhum dia marcado';
  return ordenados.map((d) => nomesCurtosDosDias[d - 1]).join(' · ');
}

/// "MINHA SEMANA" na aba Treinos: só mostra os dias marcados, sem edição
/// direta (evita toques acidentais). Tocar abre a tela de edição.
class WeekScheduleSummary extends ConsumerWidget {
  const WeekScheduleSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dias = ref.watch(scheduleProvider).valueOrNull ?? const <int>{};

    return GestureDetector(
      key: const Key('week_summary'),
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/week'),
      child: SystemPanel(
        title: 'MINHA SEMANA',
        action: const Icon(Icons.edit_outlined,
            size: 16, color: SystemPalette.mutedForeground),
        child: Row(
          children: [
            const Icon(Icons.event_repeat,
                size: 20, color: SystemPalette.primary),
            const SizedBox(width: SystemSpacing.md),
            Expanded(
              child: Text(
                resumoDosDias(dias),
                style: SystemTextStyles.displaySmall.copyWith(
                    color: dias.isEmpty
                        ? SystemPalette.mutedForeground
                        : SystemPalette.foreground),
              ),
            ),
            Text(
              '${dias.length} TREINO${dias.length == 1 ? '' : 'S'}',
              style: SystemTextStyles.label
                  .copyWith(fontSize: 8.5, color: SystemPalette.gold),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/system_colors.dart';
import '../../../design_system/system_entrance.dart';
import '../../../design_system/system_motion.dart';
import '../../../design_system/system_panel.dart';
import '../../../design_system/system_scaffold.dart';
import '../../../design_system/system_spacing.dart';
import '../../../design_system/system_text_styles.dart';
import '../domain/sport_activity.dart';
import 'sport_activity_format.dart';

/// Aba ATIVIDADES — as 8 modalidades fixas. Independente de Treinos e sem
/// nenhuma gamificação (registro esportivo manual).
class ActivitiesScreen extends StatelessWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const tipos = SportType.values;

    return SystemScaffold(
      title: 'ATIVIDADES',
      subtitle: 'REGISTRO ESPORTIVO',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < tipos.length; i += 2) ...[
            if (i > 0) const SizedBox(height: SystemSpacing.md),
            SystemEntrance(
              delay: SystemDurations.staggerStep * (i ~/ 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _SportCard(tipo: tipos[i])),
                  const SizedBox(width: SystemSpacing.md),
                  Expanded(
                    child: i + 1 < tipos.length
                        ? _SportCard(tipo: tipos[i + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SportCard extends StatelessWidget {
  const _SportCard({required this.tipo});

  final SportType tipo;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tipo.nome,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push('/activities/${tipo.name}'),
        child: SystemPanel(
          padding: const EdgeInsets.symmetric(
              horizontal: SystemSpacing.md, vertical: SystemSpacing.lg),
          child: Column(
            children: [
              Icon(iconeDaModalidade(tipo),
                  size: 32, color: SystemPalette.primary),
              const SizedBox(height: SystemSpacing.sm),
              Text(
                tipo.nome.toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SystemTextStyles.displaySmall.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

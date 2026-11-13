import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../profile/presentation/profile_providers.dart';

import '../../../../design_system/system_colors.dart';
import '../../../../design_system/system_empty_state.dart';
import '../../../../design_system/system_entrance.dart';
import '../../../../design_system/system_motion.dart';
import '../../../../design_system/system_panel.dart';
import '../../../../design_system/system_spacing.dart';
import '../../../../design_system/system_text_styles.dart';
import '../../domain/workout_session.dart';

/// "SÉRIES REGISTRADAS" do exercício atual, direto de `treinos.tsx`.
///
/// Lista as séries já registradas (reais, vindas da sessão).
///
/// Feedback de série: quando uma nova série real é registrada, sua
/// linha entra com um fade+slide curto (via [SystemEntrance], chaveado pelo
/// `id` da série — só a linha nova de fato monta um `State` novo) e fica com
/// a borda em destaque por [SystemDurations.setHighlight] antes de voltar ao
/// visual normal. Trocar de exercício no carrossel (lista size volta a
/// zero/outro conjunto) não reaproveita esses ids, então não há highlight
/// falso ao navegar.
class WorkoutSetsPanel extends StatefulWidget {
  const WorkoutSetsPanel({
    super.key,
    required this.series,
  });

  final List<SetEntryRecord> series;

  @override
  State<WorkoutSetsPanel> createState() => _WorkoutSetsPanelState();
}

class _WorkoutSetsPanelState extends State<WorkoutSetsPanel> {
  int? _destacarSetId;
  Timer? _timer;

  @override
  void didUpdateWidget(WorkoutSetsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.series.length > oldWidget.series.length) {
      final novaSerie = widget.series.last;
      setState(() => _destacarSetId = novaSerie.id);
      _timer?.cancel();
      _timer = Timer(SystemDurations.setHighlight, () {
        if (mounted) setState(() => _destacarSetId = null);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final series = widget.series;

    return SystemPanel(
      title: 'SÉRIES REGISTRADAS',
      child: series.isEmpty
          ? const SystemEmptyState(
              message: 'NENHUMA SÉRIE REGISTRADA NESTE EXERCÍCIO')
          : Column(
              children: [
                for (var i = 0; i < series.length; i++) ...[
                  if (i > 0) const SizedBox(height: SystemSpacing.xs),
                  SystemEntrance(
                    key: ValueKey('set-${series[i].id}'),
                    child: Consumer(
                      builder: (context, ref, _) => _SetRow(
                        numero: series[i].serie,
                        texto:
                            '${ref.watch(unitsProvider).formatarPeso(series[i].carga)} × ${series[i].repeticoes}',
                        registrada: true,
                        destacada: series[i].id == _destacarSetId,
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.numero,
    required this.texto,
    required this.registrada,
    required this.destacada,
  });

  final int numero;
  final String texto;
  final bool registrada;

  /// Série recém-registrada — borda verde momentânea (Fase 9, seção 11).
  final bool destacada;

  @override
  Widget build(BuildContext context) {
    final destaque =
        registrada ? SystemPalette.success : SystemPalette.mutedForeground;

    return AnimatedContainer(
      duration: SystemDurations.setHighlight,
      curve: SystemCurves.easeOut,
      padding: const EdgeInsets.symmetric(
          horizontal: SystemSpacing.md, vertical: SystemSpacing.sm),
      decoration: BoxDecoration(
        color: destacada
            ? SystemPalette.success.withValues(alpha: 0.12)
            : SystemPalette.surface2
                .withValues(alpha: SystemOpacities.surface2),
        border: Border(
          top: _bordaEnvolta(destacada),
          right: _bordaEnvolta(destacada),
          bottom: _bordaEnvolta(destacada),
          left: BorderSide(
            color: destaque.withValues(
                alpha: destacada ? 1 : (registrada ? 0.8 : 0.4)),
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'SÉRIE ${numero.toString().padLeft(2, '0')}',
            style: SystemTextStyles.label.copyWith(fontSize: 8.8),
          ),
          const Spacer(),
          Text(
            texto,
            style: TextStyle(
              fontFamily: SystemFonts.display,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: registrada
                  ? SystemPalette.foreground
                  : SystemPalette.mutedForeground,
            ),
          ),
          const SizedBox(width: SystemSpacing.sm),
          Icon(
            registrada ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: destaque.withValues(alpha: registrada ? 1 : 0.4),
          ),
        ],
      ),
    );
  }
}

BorderSide _bordaEnvolta(bool destacada) {
  return BorderSide(
    color: destacada
        ? SystemPalette.success.withValues(alpha: 0.9)
        : Colors.transparent,
    width: destacada ? 1.5 : 0,
  );
}

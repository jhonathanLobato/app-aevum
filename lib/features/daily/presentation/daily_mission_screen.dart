import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/system_back_button.dart';
import '../../../design_system/system_button.dart';
import '../../../design_system/system_colors.dart';
import '../../../design_system/system_empty_state.dart';
import '../../../design_system/system_panel.dart';
import '../../../design_system/system_scaffold.dart';
import '../../../design_system/system_spacing.dart';
import '../../../design_system/system_text_field.dart';
import '../../../design_system/system_text_styles.dart';
import '../../profile/presentation/level_up_overlay.dart';
import '../../rank_exam/presentation/rank_exam_providers.dart';
import '../domain/daily_models.dart';
import '../domain/daily_values.dart';
import 'daily_providers.dart';
import 'widgets/daily_part_bar.dart';
import 'widgets/week_strip.dart';

/// Missão Diária: 50 flexões, 50 abdominais e 2 km de caminhada/corrida,
/// todos os dias (inclusive de descanso). Os valores de cada parte são
/// somados ao longo do dia e a missão só vale XP quando as 3 partes estão
/// completas. Separada dos treinos de academia e das atividades.
class DailyMissionScreen extends ConsumerStatefulWidget {
  const DailyMissionScreen({super.key});

  @override
  ConsumerState<DailyMissionScreen> createState() => _DailyMissionScreenState();
}

class _DailyMissionScreenState extends ConsumerState<DailyMissionScreen> {
  final _campos = {
    for (final p in DailyPart.values) p: TextEditingController(),
  };

  @override
  void dispose() {
    for (final c in _campos.values) {
      c.dispose();
    }
    super.dispose();
  }

  double? _ler(DailyPart parte) {
    final texto = _campos[parte]!.text.trim().replaceAll(',', '.');
    final valor = double.tryParse(texto);
    return valor != null && valor > 0 ? valor : null;
  }

  Future<void> _adicionar(DailyPart parte, double valor) async {
    final resultado =
        await ref.read(dailyRepositoryProvider).adicionar(parte, valor);
    _campos[parte]!.clear();
    if (!mounted) return;

    if (resultado.completouAgora) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
            content:
                Text('MISSÃO DIÁRIA CUMPRIDA  +${DailyValues.xpMissao} XP')));
      final xp = resultado.xpGanho!;
      if (xp.subiuDeNivel) {
        await showLevelUpOverlay(
          context,
          nivelAnterior: xp.nivelAnterior,
          novoNivel: xp.novoNivel,
          rankAnterior: xp.rankAnterior,
          novoRank: xp.novoRank,
        );
      }
    }
    if (mounted) await sincronizarExame(context, ref);
  }

  @override
  Widget build(BuildContext context) {
    final progressoAsync = ref.watch(dailyTodayProvider);

    return SystemScaffold(
      title: 'MISSÃO DIÁRIA',
      subtitle: 'VÁLIDA TODOS OS DIAS',
      leading: const SystemBackButton(),
      body: progressoAsync.when(
        data: _conteudo,
        loading: () => const Center(
            child: CircularProgressIndicator(color: SystemPalette.primary)),
        error: (error, stackTrace) => const SystemEmptyState(
            icon: Icons.error_outline,
            message: 'ERRO AO CARREGAR A MISSÃO DIÁRIA'),
      ),
    );
  }

  Widget _conteudo(DailyProgress p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Estado(progresso: p),
        const SizedBox(height: SystemSpacing.lg),
        for (final parte in DailyPart.values) ...[
          _PartePanel(
            parte: parte,
            progresso: p,
            controller: _campos[parte]!,
            onAdicionar: (v) => _adicionar(parte, v),
            onDesfazer: () =>
                ref.read(dailyRepositoryProvider).desfazerUltimo(parte),
            lerCampo: () => _ler(parte),
          ),
          const SizedBox(height: SystemSpacing.lg),
        ],
        SystemPanel(
          title: 'FOLGA',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const WeekStrip(),
              const SizedBox(height: SystemSpacing.md),
              SystemButton(
                label: p.folga ? 'Desfazer folga de hoje' : 'Usar folga hoje',
                icon: const Icon(Icons.pause_circle_outline,
                    size: 16, color: SystemPalette.foreground),
                onPressed: p.concluida && !p.folga
                    ? null
                    : () => alternarFolgaDoDia(context, ref, p.dia),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Estado extends StatelessWidget {
  const _Estado({required this.progresso});

  final DailyProgress progresso;

  @override
  Widget build(BuildContext context) {
    final String texto;
    final IconData icone;
    final Color cor;
    if (progresso.folga) {
      texto = 'DIA DE FOLGA — A MISSÃO NÃO SERÁ COBRADA';
      icone = Icons.pause_circle_filled;
      cor = SystemPalette.primary;
    } else if (progresso.concluida) {
      texto = 'MISSÃO CUMPRIDA  +${DailyValues.xpMissao} XP';
      icone = Icons.check_circle;
      cor = SystemPalette.success;
    } else {
      texto =
          'COMPLETE AS 3 PARTES HOJE. PARCIAL NÃO GANHA XP NEM EVITA A PENALIDADE (-${DailyValues.penalidadeXp} XP).';
      icone = Icons.flag_outlined;
      cor = SystemPalette.gold;
    }
    return SystemPanel(
      glow: progresso.concluida,
      child: Row(
        children: [
          Icon(icone, color: cor, size: 20),
          const SizedBox(width: SystemSpacing.md),
          Expanded(
            child:
                Text(texto, style: SystemTextStyles.label.copyWith(color: cor)),
          ),
        ],
      ),
    );
  }
}

class _PartePanel extends StatelessWidget {
  const _PartePanel({
    required this.parte,
    required this.progresso,
    required this.controller,
    required this.onAdicionar,
    required this.onDesfazer,
    required this.lerCampo,
  });

  final DailyPart parte;
  final DailyProgress progresso;
  final TextEditingController controller;
  final void Function(double valor) onAdicionar;
  final VoidCallback onDesfazer;
  final double? Function() lerCampo;

  @override
  Widget build(BuildContext context) {
    final km = parte == DailyPart.km;
    final bloqueado = progresso.concluida;
    final nome = parte.name;

    return SystemPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DailyPartBar(parte: parte, progresso: progresso),
          const SizedBox(height: SystemSpacing.md),
          if (!km) ...[
            Row(
              children: [
                for (final passo in const [10, 25]) ...[
                  Expanded(
                    child: SystemButton(
                      key: Key('daily_${nome}_mais_$passo'),
                      label: '+$passo',
                      onPressed: bloqueado
                          ? null
                          : () => onAdicionar(passo.toDouble()),
                    ),
                  ),
                  const SizedBox(width: SystemSpacing.sm),
                ],
                Expanded(
                  child: SystemButton(
                    key: Key('daily_${nome}_desfazer'),
                    label: 'Desfazer',
                    icon: const Icon(Icons.undo,
                        size: 14, color: SystemPalette.foreground),
                    onPressed: bloqueado ? null : onDesfazer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: SystemSpacing.sm),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: SystemTextField(
                  key: Key('daily_${nome}_campo'),
                  label: km ? 'Distância' : 'Quantidade',
                  controller: controller,
                  suffix: km ? 'KM' : null,
                  enabled: !bloqueado,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: SystemSpacing.sm),
              SystemButton(
                key: Key('daily_${nome}_registrar'),
                label: 'Registrar',
                variant: SystemButtonVariant.action,
                onPressed: bloqueado
                    ? null
                    : () {
                        final v = lerCampo();
                        if (v != null) onAdicionar(v);
                      },
              ),
            ],
          ),
          if (km) ...[
            const SizedBox(height: SystemSpacing.sm),
            SystemButton(
              key: Key('daily_${nome}_desfazer'),
              label: 'Desfazer último registro',
              icon: const Icon(Icons.undo,
                  size: 14, color: SystemPalette.foreground),
              onPressed: bloqueado ? null : onDesfazer,
            ),
          ],
        ],
      ),
    );
  }
}

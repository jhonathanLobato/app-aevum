import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/system_back_button.dart';
import '../../../design_system/system_button.dart';
import '../../../design_system/system_colors.dart';
import '../../../design_system/system_panel.dart';
import '../../../design_system/system_scaffold.dart';
import '../../../design_system/system_spacing.dart';
import '../../../design_system/system_text_styles.dart';
import '../../daily/presentation/daily_providers.dart';
import '../../rank_exam/domain/rank_exam.dart';
import '../../rank_exam/presentation/rank_exam_providers.dart';
import 'widgets/week_schedule_summary.dart';

/// Edição da programação semanal: marque os dias de treino e confirme em
/// "Salvar". Sair sem salvar descarta as mudanças. Com um exame de rank em
/// andamento dá para adicionar dias, mas não remover os já salvos.
class WeekScheduleScreen extends ConsumerStatefulWidget {
  const WeekScheduleScreen({super.key});

  @override
  ConsumerState<WeekScheduleScreen> createState() => _WeekScheduleScreenState();
}

class _WeekScheduleScreenState extends ConsumerState<WeekScheduleScreen> {
  /// Rascunho local; `null` até os dias salvos chegarem do banco.
  Set<int>? _rascunho;
  bool _salvando = false;

  Future<void> _salvar(Set<int> rascunho) async {
    setState(() => _salvando = true);
    final ok =
        await ref.read(dailyRepositoryProvider).salvarProgramacao(rascunho);
    if (!mounted) return;
    setState(() => _salvando = false);
    if (!ok) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
            content: Text(
                'Com o exame de rank em andamento você pode adicionar dias de treino, mas não remover.')));
      return;
    }
    // Garante que os quadros que mostram a programação releiam o banco.
    ref.invalidate(scheduleProvider);
    ref.invalidate(weekStripProvider);
    // Salvar pode ser o que faltava para iniciar/liberar o exame.
    await sincronizarExame(context, ref);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Programação salva.')));
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final salvos = ref.watch(scheduleProvider).valueOrNull;
    final status = ref.watch(rankStatusProvider).valueOrNull;
    final exameEmAndamento = status?.fase == RankExamPhase.emAndamento;
    final exameDisponivel = status?.fase == RankExamPhase.disponivel;

    if (salvos != null && _rascunho == null) _rascunho = {...salvos};
    final rascunho = _rascunho;

    final mudou = rascunho != null &&
        salvos != null &&
        !(rascunho.length == salvos.length && rascunho.containsAll(salvos));

    return SystemScaffold(
      title: 'MINHA SEMANA',
      subtitle: 'DIAS DE TREINO',
      leading: const SystemBackButton(),
      body: rascunho == null
          ? const Center(
              child: CircularProgressIndicator(color: SystemPalette.primary))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SystemPanel(
                  title: 'ESCOLHA OS DIAS',
                  action: Text(
                    '${rascunho.length} TREINO${rascunho.length == 1 ? '' : 'S'} · ${7 - rascunho.length} DESCANSO${7 - rascunho.length == 1 ? '' : 'S'}',
                    style: SystemTextStyles.label
                        .copyWith(fontSize: 8.5, color: SystemPalette.gold),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          for (var dia = 1; dia <= 7; dia++)
                            Expanded(
                              child: _Dia(
                                sigla:
                                    nomesCurtosDosDias[dia - 1].toUpperCase(),
                                treino: rascunho.contains(dia),
                                travado: exameEmAndamento &&
                                    salvos != null &&
                                    salvos.contains(dia),
                                chave: Key('schedule_day_$dia'),
                                onTap: () => setState(() {
                                  if (rascunho.contains(dia)) {
                                    rascunho.remove(dia);
                                  } else {
                                    rascunho.add(dia);
                                  }
                                }),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: SystemSpacing.sm),
                      Text(
                        'Toque nos dias de treino; os demais são descanso programado. '
                        'Nada é salvo até você tocar em "Salvar".',
                        style: SystemTextStyles.body
                            .copyWith(color: SystemPalette.mutedForeground),
                      ),
                      if (exameEmAndamento) ...[
                        const SizedBox(height: SystemSpacing.sm),
                        Row(
                          children: [
                            const Icon(Icons.lock_outline,
                                size: 14, color: SystemPalette.gold),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'EXAME DE RANK EM ANDAMENTO: você pode adicionar dias de treino, mas não remover.',
                                style: SystemTextStyles.label.copyWith(
                                    fontSize: 8.5, color: SystemPalette.gold),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (exameDisponivel && rascunho.length < 2) ...[
                        const SizedBox(height: SystemSpacing.sm),
                        Text(
                          'Seu exame de rank está disponível: marque pelo menos ${RankExamValues.minDiasProgramados} dias de treino para poder iniciá-lo.',
                          style: SystemTextStyles.label.copyWith(
                              fontSize: 8.5, color: SystemPalette.gold),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: SystemSpacing.lg),
                SystemButton(
                  key: const Key('salvar_programacao'),
                  label: 'Salvar',
                  variant: SystemButtonVariant.action,
                  size: SystemButtonSize.lg,
                  onPressed:
                      mudou && !_salvando ? () => _salvar(rascunho) : null,
                ),
              ],
            ),
    );
  }
}

class _Dia extends StatelessWidget {
  const _Dia({
    required this.sigla,
    required this.treino,
    required this.chave,
    required this.onTap,
    required this.travado,
  });

  final String sigla;
  final bool treino;
  final bool travado;
  final Key chave;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: treino,
      label: '$sigla: ${treino ? 'treino' : 'descanso'}',
      child: GestureDetector(
        key: chave,
        behavior: HitTestBehavior.opaque,
        // Dia salvo durante o exame não pode ser removido.
        onTap: travado ? null : onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: SystemSpacing.md),
          decoration: BoxDecoration(
            color:
                treino ? SystemPalette.primary.withValues(alpha: 0.15) : null,
            border: Border.all(
              color: treino
                  ? SystemPalette.primary
                  : SystemPalette.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            children: [
              Text(sigla,
                  style: SystemTextStyles.label.copyWith(
                      fontSize: 9,
                      color: treino
                          ? SystemPalette.primary
                          : SystemPalette.mutedForeground)),
              const SizedBox(height: 4),
              Icon(
                travado
                    ? Icons.lock_outline
                    : (treino ? Icons.fitness_center : Icons.bedtime_outlined),
                size: 16,
                color: treino
                    ? SystemPalette.primary
                    : SystemPalette.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

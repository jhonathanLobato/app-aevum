import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/system_button.dart';
import '../../../design_system/system_confirm_dialog.dart';
import '../../../design_system/system_colors.dart';
import '../../../design_system/system_empty_state.dart';
import '../../../design_system/system_panel.dart';
import '../../../design_system/system_text_styles.dart';
import '../../../design_system/system_scaffold.dart';
import '../../../design_system/system_spacing.dart';
import '../../achievements/presentation/achievement_unlocked_dialog.dart';
import '../../missions/presentation/mission_completed_dialog.dart';
import '../../profile/presentation/level_up_overlay.dart';
import '../domain/workout_session.dart';
import '../domain/workout_template.dart';
import 'pr_detected_dialog.dart';
import 'widgets/workout_exercise_header.dart';
import 'widgets/workout_new_set_panel.dart';
import 'widgets/workout_sets_panel.dart';
import 'workout_session_providers.dart';
import 'workout_template_providers.dart';

/// Treino ativo — carrossel de um exercício por vez (Fase 6), direto de
/// `treinos.tsx`. Continua rota secundária fullscreen (Fase 4): sem
/// `SystemNavigationBar`.
///
/// Toda a lógica de negócio (registrar série, finalizar treino, PR,
/// missões, conquistas, XP) é exatamente a mesma de antes da Fase 6 — só a
/// apresentação mudou. "Finalizar exercício" não tem estado persistente
/// próprio (não existe no schema), então é só navegação: avança o
/// carrossel pro próximo exercício, igual ao `treinos.tsx` original.
class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({required this.sessionId, super.key});

  final int sessionId;

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  Timer? _ticker;
  Duration _elapsed = Duration.zero;

  /// `true` quando ESTA tela acabou de finalizar a sessão — só nesse caso
  /// oferecemos "Retornar treino" (o histórico continua somente leitura).
  bool _finalizouAqui = false;

  /// Depois de "Retornar treino", a duração continua da que já estava
  /// gravada em vez de contar o tempo em que o treino ficou finalizado.
  DateTime? _retomadoEm;
  Duration _duracaoAoRetomar = Duration.zero;
  final _inputs = <int, _SetInputControllers>{};
  int _currentIndex = 0;

  _SetInputControllers _controllersFor(int exerciseId) {
    return _inputs.putIfAbsent(exerciseId, _SetInputControllers.new);
  }

  void _startTicker(DateTime inicio) {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed = _calcularElapsed(inicio));
    });
  }

  Duration _calcularElapsed(DateTime inicio) {
    final retomadoEm = _retomadoEm;
    if (retomadoEm == null) return DateTime.now().difference(inicio);
    return _duracaoAoRetomar + DateTime.now().difference(retomadoEm);
  }

  Future<void> _retornarTreino(WorkoutSession session) async {
    await ref.read(workoutSessionRepositoryProvider).reopen(session.id);
    if (!mounted) return;
    setState(() {
      _finalizouAqui = false;
      _duracaoAoRetomar = Duration(seconds: session.duracaoSegundos ?? 0);
      _retomadoEm = DateTime.now();
      _elapsed = _duracaoAoRetomar;
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    for (final controllers in _inputs.values) {
      controllers.dispose();
    }
    super.dispose();
  }

  void _irPara(int index, int total) {
    final clamped = index.clamp(0, total - 1);
    if (clamped == _currentIndex) return;
    setState(() => _currentIndex = clamped);
  }

  Future<void> _registrarSerie(
    int sessionId,
    int exerciseId,
    String exerciseNome,
  ) async {
    final controllers = _controllersFor(exerciseId);
    final repeticoes = int.tryParse(controllers.repsController.text);
    final carga =
        double.tryParse(controllers.cargaController.text.replaceAll(',', '.'));
    if (repeticoes == null || repeticoes <= 0 || carga == null || carga <= 0) {
      return;
    }

    final resultado = await ref.read(workoutSessionRepositoryProvider).logSet(
          sessionId: sessionId,
          exerciseId: exerciseId,
          repeticoes: repeticoes,
          carga: carga,
        );
    controllers.repsController.clear();
    controllers.cargaController.clear();

    if (resultado.prsBatidos.isNotEmpty && mounted) {
      await showPrDetectedDialog(
        context,
        exerciseNome: exerciseNome,
        prs: resultado.prsBatidos,
        xpGanho: resultado.xpGanho?.xpGanho,
      );
    }

    final desafioConcluido = resultado.desafioConcluido;
    if (desafioConcluido != null && mounted) {
      await showMissionsCompletedDialog(context, [desafioConcluido]);
    }

    if (resultado.conquistasDesbloqueadas.isNotEmpty && mounted) {
      await showAchievementsUnlockedDialog(
          context, resultado.conquistasDesbloqueadas);
    }

    final xpGanho = resultado.xpGanho;
    if (xpGanho != null && xpGanho.subiuDeNivel && mounted) {
      await showLevelUpOverlay(
        context,
        nivelAnterior: xpGanho.nivelAnterior,
        novoNivel: xpGanho.novoNivel,
        rankAnterior: xpGanho.rankAnterior,
        novoRank: xpGanho.novoRank,
      );
    }
  }

  Future<void> _confirmarEFinalizarTreino(WorkoutSession session) async {
    final confirmar = await showSystemConfirmDialog(
      context,
      titulo: 'Encerrar treino?',
      mensagem:
          'Isso encerra a sessão inteira, não só o exercício atual. Deseja continuar?',
      confirmar: 'Finalizar',
      icone: Icons.flag_outlined,
    );
    if (!confirmar || !mounted) return;

    final resultado = await ref
        .read(workoutSessionRepositoryProvider)
        .finish(session.id, duracao: _elapsed);
    _ticker?.cancel();
    _ticker = null;
    if (mounted) setState(() => _finalizouAqui = true);

    if (resultado != null &&
        resultado.missoesConcluidas.isNotEmpty &&
        mounted) {
      await showMissionsCompletedDialog(context, resultado.missoesConcluidas);
    }
    if (resultado != null &&
        resultado.conquistasDesbloqueadas.isNotEmpty &&
        mounted) {
      await showAchievementsUnlockedDialog(
          context, resultado.conquistasDesbloqueadas);
    }
    if ((resultado?.xpGanho.subiuDeNivel ?? false) && mounted) {
      await showLevelUpOverlay(
        context,
        nivelAnterior: resultado!.xpGanho.nivelAnterior,
        novoNivel: resultado.xpGanho.novoNivel,
        rankAnterior: resultado.xpGanho.rankAnterior,
        novoRank: resultado.xpGanho.novoRank,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(workoutSessionProvider(widget.sessionId));

    return sessionAsync.when(
      data: (session) {
        if (session == null) {
          return const SystemScaffold(
            title: 'TREINO',
            header: _Header(title: 'TREINO'),
            body: SystemEmptyState(message: 'ESTA SESSÃO NÃO EXISTE MAIS'),
          );
        }

        final emAndamento = session.status == WorkoutSessionStatus.emAndamento;
        if (emAndamento) {
          _startTicker(session.data);
        }
        final duracao = emAndamento
            ? _elapsed
            : Duration(seconds: session.duracaoSegundos ?? 0);

        WorkoutTemplate? template;
        if (session.templateId != null) {
          final templatesAsync = ref.watch(workoutTemplatesProvider);
          final templates = templatesAsync.valueOrNull;
          if (templates != null) {
            template = _findTemplate(templates, session.templateId!);
          }
        }

        final exercicios = template != null
            ? template.exercicios
                .map((e) => _ExercisePlan(
                      id: e.exerciseId,
                      nome: e.exerciseNome,
                      grupoMuscular: e.grupoMuscular,
                      seriesAlvo: e.seriesAlvo,
                      repeticoesAlvo: e.repeticoesAlvo,
                    ))
                .toList()
            : _exerciciosUnicos(session.series)
                .map((e) =>
                    _ExercisePlan(id: e.exerciseId, nome: e.exerciseNome))
                .toList();

        return SystemScaffold(
          title: session.nome,
          header: _Header(
            title: session.nome,
            subtitle: 'DURAÇÃO: ${_formatarDuracao(duracao)}',
          ),
          navigationBar: emAndamento
              ? SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(SystemSpacing.lg),
                    child: SystemButton(
                      label: 'Finalizar treino',
                      variant: SystemButtonVariant.danger,
                      size: SystemButtonSize.lg,
                      onPressed: () => _confirmarEFinalizarTreino(session),
                    ),
                  ),
                )
              : _finalizouAqui
                  ? SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.all(SystemSpacing.lg),
                        child: SystemButton(
                          label: 'Retornar treino',
                          variant: SystemButtonVariant.action,
                          size: SystemButtonSize.lg,
                          icon: const Icon(Icons.undo,
                              size: 16, color: SystemPalette.foreground),
                          onPressed: () => _retornarTreino(session),
                        ),
                      ),
                    )
                  : null,
          body: exercicios.isEmpty
              ? const SystemEmptyState(
                  message: 'ESTE TREINO NÃO TEM EXERCÍCIOS CADASTRADOS')
              : _buildCarousel(session, exercicios, emAndamento),
        );
      },
      error: (error, stackTrace) => const SystemScaffold(
        title: 'TREINO',
        header: _Header(title: 'TREINO'),
        body: SystemEmptyState(
          icon: Icons.error_outline,
          message: 'ERRO AO CARREGAR O TREINO',
        ),
      ),
      loading: () => const SystemScaffold(
        title: 'TREINO',
        header: _Header(title: 'TREINO'),
        body: Center(
          child: CircularProgressIndicator(color: SystemPalette.primary),
        ),
      ),
    );
  }

  Widget _buildCarousel(
    WorkoutSession session,
    List<_ExercisePlan> exercicios,
    bool emAndamento,
  ) {
    final total = exercicios.length;
    final index = _currentIndex.clamp(0, total - 1);
    final exercicio = exercicios[index];
    final seriesDoExercicio = session.seriesDoExercicio(exercicio.id);
    final hasSeries = [
      for (final e in exercicios) session.seriesDoExercicio(e.id).isNotEmpty,
    ];
    final controllers = _controllersFor(exercicio.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WorkoutExerciseHeader(
          exerciseId: exercicio.id,
          exerciseNome: exercicio.nome,
          grupoMuscular: exercicio.grupoMuscular,
          index: index,
          total: total,
          hasSeries: hasSeries,
          seriesAlvo: exercicio.seriesAlvo,
          repeticoesAlvo: exercicio.repeticoesAlvo,
          onAnterior: index > 0 ? () => _irPara(index - 1, total) : null,
          onProximo: index < total - 1 ? () => _irPara(index + 1, total) : null,
        ),
        const SizedBox(height: SystemSpacing.lg),
        WorkoutSetsPanel(
            series: seriesDoExercicio, seriesAlvo: exercicio.seriesAlvo),
        const SizedBox(height: SystemSpacing.lg),
        if (emAndamento)
          WorkoutNewSetPanel(
            cargaController: controllers.cargaController,
            repsController: controllers.repsController,
            enabled: true,
            onRegistrar: () =>
                _registrarSerie(session.id, exercicio.id, exercicio.nome),
            onFinalizarExercicio: () => _irPara(index + 1, total),
          )
        else
          const _TreinoFinalizadoBanner(),
      ],
    );
  }

  WorkoutTemplate? _findTemplate(List<WorkoutTemplate> templates, int id) {
    for (final template in templates) {
      if (template.id == id) return template;
    }
    return null;
  }

  List<SetEntryRecord> _exerciciosUnicos(List<SetEntryRecord> series) {
    final vistos = <int>{};
    final unicos = <SetEntryRecord>[];
    for (final entry in series) {
      if (vistos.add(entry.exerciseId)) unicos.add(entry);
    }
    return unicos;
  }

  String _formatarDuracao(Duration d) {
    final minutos = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final segundos = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final horas = d.inHours;
    return horas > 0 ? '$horas:$minutos:$segundos' : '$minutos:$segundos';
  }
}

/// Cabeçalho com botão de voltar — a sessão ativa é uma rota secundária
/// (Fase 4), sem navigation bar nem AppBar padrão, então precisa do seu
/// próprio jeito de voltar.
class _Header extends StatelessWidget {
  const _Header({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return SystemHeader(
      title: title,
      subtitle: subtitle,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        color: SystemPalette.mutedForeground,
        onPressed: () => context.pop(),
        tooltip: 'Voltar',
      ),
    );
  }
}

/// Substitui o painel "Nova série" quando a sessão está finalizada.
class _TreinoFinalizadoBanner extends StatelessWidget {
  const _TreinoFinalizadoBanner();

  @override
  Widget build(BuildContext context) {
    return const SystemPanel(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 18, color: SystemPalette.success),
          SizedBox(width: SystemSpacing.sm),
          Text(
            'TREINO FINALIZADO',
            style: SystemTextStyles.label,
          ),
        ],
      ),
    );
  }
}

class _ExercisePlan {
  const _ExercisePlan({
    required this.id,
    required this.nome,
    this.grupoMuscular = '',
    this.seriesAlvo,
    this.repeticoesAlvo,
  });

  final int id;
  final String nome;
  final String grupoMuscular;
  final int? seriesAlvo;
  final int? repeticoesAlvo;
}

class _SetInputControllers {
  final repsController = TextEditingController();
  final cargaController = TextEditingController();

  void dispose() {
    repsController.dispose();
    cargaController.dispose();
  }
}

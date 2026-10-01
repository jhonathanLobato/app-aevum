import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../achievements/presentation/achievement_unlocked_dialog.dart';
import '../../missions/presentation/mission_completed_dialog.dart';
import '../../profile/presentation/level_up_dialog.dart';
import '../domain/workout_session.dart';
import '../domain/workout_template.dart';
import 'pr_detected_dialog.dart';
import 'workout_session_providers.dart';
import 'workout_template_providers.dart';

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
  final _inputs = <int, _SetInputControllers>{};

  _SetInputControllers _controllersFor(int exerciseId) {
    return _inputs.putIfAbsent(exerciseId, _SetInputControllers.new);
  }

  void _startTicker(DateTime inicio) {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed = DateTime.now().difference(inicio));
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
      );
    }

    final desafioConcluido = resultado.desafioConcluido;
    if (desafioConcluido != null && mounted) {
      await showMissionsCompletedDialog(context, [desafioConcluido]);
    }

    if (resultado.conquistasDesbloqueadas.isNotEmpty && mounted) {
      await showAchievementsUnlockedDialog(
        context,
        resultado.conquistasDesbloqueadas,
      );
    }

    final xpGanho = resultado.xpGanho;
    if (xpGanho != null && xpGanho.subiuDeNivel && mounted) {
      await showLevelUpDialog(
        context,
        nivelAnterior: xpGanho.nivelAnterior,
        novoNivel: xpGanho.novoNivel,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(workoutSessionProvider(widget.sessionId));

    return sessionAsync.when(
      data: (session) {
        if (session == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Treino')),
            body: const Center(child: Text('Esta sessão não existe mais.')),
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

        final exerciciosOrdenados = template != null
            ? template.exercicios
                .map((e) =>
                    _ExercisePlan(id: e.exerciseId, nome: e.exerciseNome))
                .toList()
            : _exerciciosUnicos(session.series)
                .map((e) =>
                    _ExercisePlan(id: e.exerciseId, nome: e.exerciseNome))
                .toList();

        return Scaffold(
          appBar: AppBar(title: Text(session.nome)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Duração: ${_formatarDuracao(duracao)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              if (exerciciosOrdenados.isEmpty)
                const Text('Este treino não tem exercícios cadastrados.'),
              for (final exercicio in exerciciosOrdenados)
                _ExerciseSetsCard(
                  exerciseId: exercicio.id,
                  exerciseNome: exercicio.nome,
                  series: session.seriesDoExercicio(exercicio.id),
                  controllers: _controllersFor(exercicio.id),
                  habilitado: emAndamento,
                  onRegistrar: () => _registrarSerie(
                    session.id,
                    exercicio.id,
                    exercicio.nome,
                  ),
                ),
            ],
          ),
          bottomNavigationBar: emAndamento
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton(
                      onPressed: () async {
                        final resultado = await ref
                            .read(workoutSessionRepositoryProvider)
                            .finish(session.id, duracao: _elapsed);

                        if (resultado != null &&
                            resultado.missoesConcluidas.isNotEmpty &&
                            context.mounted) {
                          await showMissionsCompletedDialog(
                            context,
                            resultado.missoesConcluidas,
                          );
                        }
                        if (resultado != null &&
                            resultado.conquistasDesbloqueadas.isNotEmpty &&
                            context.mounted) {
                          await showAchievementsUnlockedDialog(
                            context,
                            resultado.conquistasDesbloqueadas,
                          );
                        }
                        if ((resultado?.xpGanho.subiuDeNivel ?? false) &&
                            context.mounted) {
                          await showLevelUpDialog(
                            context,
                            nivelAnterior: resultado!.xpGanho.nivelAnterior,
                            novoNivel: resultado.xpGanho.novoNivel,
                          );
                        }
                        if (context.mounted) context.pop();
                      },
                      child: const Text('Finalizar treino'),
                    ),
                  ),
                )
              : null,
        );
      },
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: const Text('Treino')),
        body: Center(child: Text('Erro: $error')),
      ),
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Treino')),
        body: const Center(child: CircularProgressIndicator()),
      ),
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

class _ExercisePlan {
  const _ExercisePlan({required this.id, required this.nome});

  final int id;
  final String nome;
}

class _SetInputControllers {
  final repsController = TextEditingController();
  final cargaController = TextEditingController();

  void dispose() {
    repsController.dispose();
    cargaController.dispose();
  }
}

class _ExerciseSetsCard extends StatelessWidget {
  const _ExerciseSetsCard({
    required this.exerciseId,
    required this.exerciseNome,
    required this.series,
    required this.controllers,
    required this.habilitado,
    required this.onRegistrar,
  });

  final int exerciseId;
  final String exerciseNome;
  final List<SetEntryRecord> series;
  final _SetInputControllers controllers;
  final bool habilitado;
  final VoidCallback onRegistrar;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(exerciseNome, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final serie in series)
              Text(
                  'Série ${serie.serie}: ${serie.repeticoes} × ${serie.carga}kg'),
            if (habilitado) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controllers.repsController,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Repetições'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: controllers.cargaController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          const InputDecoration(labelText: 'Carga (kg)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline),
                    onPressed: onRegistrar,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

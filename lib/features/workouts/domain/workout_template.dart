class WorkoutTemplateExerciseItem {
  const WorkoutTemplateExerciseItem({
    required this.templateExerciseId,
    required this.exerciseId,
    required this.exerciseNome,
    required this.grupoMuscular,
    required this.ordem,
    this.seriesAlvo,
    this.repeticoesAlvo,
  });

  final int templateExerciseId;
  final int exerciseId;
  final String exerciseNome;
  final String grupoMuscular;
  final int ordem;
  final int? seriesAlvo;
  final int? repeticoesAlvo;
}

class WorkoutTemplate {
  const WorkoutTemplate({
    required this.id,
    required this.nome,
    required this.criadoEm,
    required this.exercicios,
  });

  final int id;
  final String nome;
  final DateTime criadoEm;
  final List<WorkoutTemplateExerciseItem> exercicios;
}

class WorkoutTemplateExerciseItem {
  const WorkoutTemplateExerciseItem({
    required this.templateExerciseId,
    required this.exerciseId,
    required this.exerciseNome,
    required this.grupoMuscular,
    required this.ordem,
  });

  final int templateExerciseId;
  final int exerciseId;
  final String exerciseNome;
  final String grupoMuscular;
  final int ordem;
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

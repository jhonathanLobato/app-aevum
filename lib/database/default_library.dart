import 'app_database.dart';

/// Biblioteca padrão: 6 treinos (Push/Pull/Legs) só com os exercícios, sem
/// séries/repetições-alvo. Tudo editável e apagável como qualquer treino.
const kDefaultWorkoutLibrary = <String, List<(String, String)>>{
  'A — Push 1': [
    ('Supino reto com barra', 'Peito'),
    ('Supino inclinado com halteres', 'Peito'),
    ('Crucifixo na máquina/Peck Deck', 'Peito'),
    ('Desenvolvimento com halteres', 'Ombros'),
    ('Elevação lateral', 'Ombros'),
    ('Tríceps na polia', 'Tríceps'),
    ('Tríceps francês', 'Tríceps'),
  ],
  'B — Pull 1': [
    ('Puxada alta aberta', 'Costas'),
    ('Remada baixa', 'Costas'),
    ('Puxada unilateral', 'Costas'),
    ('Crucifixo inverso', 'Ombros'),
    ('Rosca direta', 'Bíceps'),
    ('Rosca martelo', 'Bíceps'),
  ],
  'C — Legs 1': [
    ('Agachamento', 'Pernas'),
    ('Leg press', 'Pernas'),
    ('Cadeira extensora', 'Pernas'),
    ('Mesa flexora', 'Pernas'),
    ('Elevação pélvica', 'Glúteos'),
    ('Panturrilha em pé', 'Panturrilha'),
    ('Abdominal', 'Abdômen'),
  ],
  'D — Push 2': [
    ('Desenvolvimento na máquina', 'Ombros'),
    ('Supino inclinado na máquina', 'Peito'),
    ('Crossover na polia', 'Peito'),
    ('Elevação lateral na polia', 'Ombros'),
    ('Elevação lateral máquina', 'Ombros'),
    ('Tríceps testa', 'Tríceps'),
    ('Tríceps corda', 'Tríceps'),
  ],
  'E — Pull 2': [
    ('Remada articulada/máquina', 'Costas'),
    ('Remada unilateral com halter', 'Costas'),
    ('Puxada neutra', 'Costas'),
    ('Face pull', 'Ombros'),
    ('Rosca Scott', 'Bíceps'),
    ('Rosca inclinada com halteres', 'Bíceps'),
  ],
  'F — Legs 2': [
    ('Stiff/RDL', 'Pernas'),
    ('Hack squat', 'Pernas'),
    ('Mesa flexora', 'Pernas'),
    ('Elevação pélvica', 'Glúteos'),
    ('Cadeira extensora', 'Pernas'),
    ('Panturrilha sentado', 'Panturrilha'),
    ('Abdominal', 'Abdômen'),
  ],
};

/// Cria a biblioteca padrão se NÃO existir nenhum treino. Exercícios com o
/// mesmo nome são o mesmo registro (reaproveita os já cadastrados).
Future<void> seedDefaultLibraryIfEmpty(AppDatabase db) async {
  await db.transaction(() async {
    final existentes = await db.select(db.workoutTemplates).get();
    if (existentes.isNotEmpty) return;

    final idsPorNome = <String, int>{
      for (final e in await db.select(db.exercises).get())
        e.nome.toLowerCase(): e.id,
    };

    for (final entrada in kDefaultWorkoutLibrary.entries) {
      final templateId = await db
          .into(db.workoutTemplates)
          .insert(WorkoutTemplatesCompanion.insert(nome: entrada.key));
      var ordem = 0;
      for (final (nome, grupo) in entrada.value) {
        var exerciseId = idsPorNome[nome.toLowerCase()];
        exerciseId ??= idsPorNome[nome.toLowerCase()] = await db
            .into(db.exercises)
            .insert(
                ExercisesCompanion.insert(nome: nome, grupoMuscular: grupo));
        await db.into(db.workoutTemplateExercises).insert(
              WorkoutTemplateExercisesCompanion.insert(
                templateId: templateId,
                exerciseId: exerciseId,
                ordem: ordem++,
              ),
            );
      }
    }
  });
}

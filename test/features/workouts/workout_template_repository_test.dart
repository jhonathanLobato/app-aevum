import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/database/app_database.dart';
import 'package:gym_system/features/workouts/data/workout_template_repository_impl.dart';

void main() {
  late AppDatabase db;
  late DriftWorkoutTemplateRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftWorkoutTemplateRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> criarExercicio(String nome, String grupo) {
    return db
        .into(db.exercises)
        .insert(ExercisesCompanion.insert(nome: nome, grupoMuscular: grupo));
  }

  test('cria um treino e adiciona exercícios em ordem', () async {
    final supinoId = await criarExercicio('Supino reto', 'Peito');
    final crucifixoId = await criarExercicio('Crucifixo', 'Peito');

    final treinoId = await repo.create('Treino A');
    await repo.addExercise(treinoId, supinoId);
    await repo.addExercise(treinoId, crucifixoId);

    final templates = await repo.watchAll().first;
    final treino = templates.single;

    expect(treino.nome, 'Treino A');
    expect(treino.exercicios.map((e) => e.exerciseNome),
        ['Supino reto', 'Crucifixo']);
  });

  test('reordena os exercícios de um treino', () async {
    final supinoId = await criarExercicio('Supino reto', 'Peito');
    final crucifixoId = await criarExercicio('Crucifixo', 'Peito');

    final treinoId = await repo.create('Treino A');
    await repo.addExercise(treinoId, supinoId);
    await repo.addExercise(treinoId, crucifixoId);

    final antes = (await repo.watchAll().first).single;
    final idsInvertidos = antes.exercicios
        .map((e) => e.templateExerciseId)
        .toList()
        .reversed
        .toList();
    await repo.reorderExercises(treinoId, idsInvertidos);

    final depois = (await repo.watchAll().first).single;
    expect(depois.exercicios.map((e) => e.exerciseNome),
        ['Crucifixo', 'Supino reto']);
  });

  test('remove um exercício do treino', () async {
    final supinoId = await criarExercicio('Supino reto', 'Peito');
    final treinoId = await repo.create('Treino A');
    await repo.addExercise(treinoId, supinoId);

    final antes = (await repo.watchAll().first).single;
    await repo.removeExercise(antes.exercicios.single.templateExerciseId);

    final depois = (await repo.watchAll().first).single;
    expect(depois.exercicios, isEmpty);
  });

  test('renomeia um treino', () async {
    final treinoId = await repo.create('Treino A');
    await repo.rename(treinoId, 'Treino B');

    final templates = await repo.watchAll().first;
    expect(templates.single.nome, 'Treino B');
  });

  test('excluir um treino remove também seus exercícios (cascade)', () async {
    final supinoId = await criarExercicio('Supino reto', 'Peito');
    final treinoId = await repo.create('Treino A');
    await repo.addExercise(treinoId, supinoId);

    await repo.delete(treinoId);

    expect(await repo.watchAll().first, isEmpty);
    expect(await db.select(db.workoutTemplateExercises).get(), isEmpty);
  });
}

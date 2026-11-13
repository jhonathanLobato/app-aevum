import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/database/app_database.dart';
import 'package:gym_system/database/default_library.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('cria os 6 treinos A–F com os exercícios, compartilhando repetidos',
      () async {
    await seedDefaultLibraryIfEmpty(db);

    final treinos = await db.select(db.workoutTemplates).get();
    expect(treinos.map((t) => t.nome), kDefaultWorkoutLibrary.keys);
    expect(treinos, hasLength(6));

    final ligacoes = await db.select(db.workoutTemplateExercises).get();
    final total =
        kDefaultWorkoutLibrary.values.fold<int>(0, (s, l) => s + l.length);
    expect(ligacoes, hasLength(total));

    final exercicios = await db.select(db.exercises).get();
    final nomes = exercicios.map((e) => e.nome.toLowerCase()).toSet();
    expect(nomes.length, exercicios.length); // sem duplicados
    // Exercícios repetidos entre treinos são o MESMO registro.
    final abdominal = exercicios.singleWhere((e) => e.nome == 'Abdominal');
    expect(ligacoes.where((l) => l.exerciseId == abdominal.id), hasLength(2));
  });

  test('não recria nada se já existe algum treino', () async {
    await db
        .into(db.workoutTemplates)
        .insert(WorkoutTemplatesCompanion.insert(nome: 'Meu treino'));

    await seedDefaultLibraryIfEmpty(db);

    expect(await db.select(db.workoutTemplates).get(), hasLength(1));
    expect(await db.select(db.exercises).get(), isEmpty);
  });
}

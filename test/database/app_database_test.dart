import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/database/app_database.dart';
import 'package:gym_system/features/missions/domain/mission.dart';
import 'package:gym_system/features/profile/domain/player_class.dart';
import 'package:gym_system/features/progression/domain/personal_record.dart';
import 'package:gym_system/features/workouts/domain/workout_session.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('grava e lê um usuário', () async {
    final id = await db.into(db.users).insert(
          UsersCompanion.insert(nome: 'Jogador', classe: PlayerClass.guerreiro),
        );
    final user =
        await (db.select(db.users)..where((u) => u.id.equals(id))).getSingle();

    expect(user.nome, 'Jogador');
    expect(user.xp, 0);
    expect(user.nivel, 1);
    expect(user.rank, 'F');
  });

  test('cria um treino com exercícios em ordem', () async {
    final exercicioId = await db.into(db.exercises).insert(
          ExercisesCompanion.insert(
              nome: 'Supino reto', grupoMuscular: 'Peito'),
        );
    final treinoId = await db.into(db.workoutTemplates).insert(
          WorkoutTemplatesCompanion.insert(nome: 'Treino A'),
        );
    await db.into(db.workoutTemplateExercises).insert(
          WorkoutTemplateExercisesCompanion.insert(
            templateId: treinoId,
            exerciseId: exercicioId,
            ordem: 0,
          ),
        );

    final itens = await db.select(db.workoutTemplateExercises).get();
    expect(itens, hasLength(1));
    expect(itens.single.templateId, treinoId);
  });

  test('registra uma sessão de treino e suas séries, ligadas ao treino',
      () async {
    final exercicioId = await db.into(db.exercises).insert(
          ExercisesCompanion.insert(
              nome: 'Supino reto', grupoMuscular: 'Peito'),
        );
    final treinoId = await db.into(db.workoutTemplates).insert(
          WorkoutTemplatesCompanion.insert(nome: 'Treino A'),
        );
    final sessaoId = await db.into(db.workoutSessions).insert(
          WorkoutSessionsCompanion.insert(
            templateId: Value(treinoId),
            nome: 'Treino A',
            status: WorkoutSessionStatus.emAndamento,
          ),
        );

    await db.into(db.setEntries).insert(
          SetEntriesCompanion.insert(
            sessionId: sessaoId,
            exerciseId: exercicioId,
            serie: 1,
            repeticoes: 10,
            carga: 30,
            volume: 300,
          ),
        );

    final series = await db.select(db.setEntries).get();
    expect(series, hasLength(1));
    expect(series.single.volume, 300);
  });

  test('registra um PR', () async {
    final exercicioId = await db.into(db.exercises).insert(
          ExercisesCompanion.insert(
              nome: 'Supino reto', grupoMuscular: 'Peito'),
        );

    await db.into(db.personalRecords).insert(
          PersonalRecordsCompanion.insert(
            exerciseId: exercicioId,
            tipo: PersonalRecordType.carga,
            valor: 32,
          ),
        );

    final prs = await db.select(db.personalRecords).get();
    expect(prs, hasLength(1));
  });

  test('cria uma missão e uma conquista', () async {
    await db.into(db.missions).insert(
          MissionsCompanion.insert(
            tipo: MissionType.diaria,
            nome: 'Complete seu treino',
            descricao: 'Finalize um treino hoje',
            recompensaXp: 50,
            objetivo: 1,
          ),
        );
    await db.into(db.achievements).insert(
          AchievementsCompanion.insert(
            chave: 'primeiros_passos',
            nome: 'Primeiros Passos',
            descricao: 'Complete seu primeiro treino',
            requisito: 'treinos_concluidos >= 1',
          ),
        );

    expect(await db.select(db.missions).get(), hasLength(1));
    expect(await db.select(db.achievements).get(), hasLength(1));
  });
}

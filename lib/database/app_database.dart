import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../features/achievements/data/tables/achievement_table.dart';
import '../features/activities/data/tables/sport_activity_table.dart';
import '../features/activities/domain/sport_activity.dart';
import '../features/achievements/domain/achievement.dart';
import '../features/exercises/data/tables/exercise_table.dart';
import '../features/missions/data/tables/mission_table.dart';
import '../features/missions/domain/mission.dart';
import '../features/profile/data/tables/user_table.dart';
import '../features/profile/domain/app_theme.dart';
import '../features/profile/domain/player_class.dart';
import '../features/progression/data/tables/personal_record_table.dart';
import '../features/progression/domain/personal_record.dart';
import '../features/workouts/data/tables/finished_exercise_table.dart';
import '../features/workouts/data/tables/set_draft_table.dart';
import '../features/workouts/data/tables/set_entry_table.dart';
import '../features/workouts/data/tables/workout_session_table.dart';
import '../features/workouts/data/tables/workout_template_exercise_table.dart';
import '../features/workouts/data/tables/workout_template_table.dart';
import '../features/workouts/domain/workout_session.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Users,
  Exercises,
  WorkoutTemplates,
  WorkoutTemplateExercises,
  WorkoutSessions,
  SetEntries,
  PersonalRecords,
  Missions,
  Achievements,
  SportActivities,
  FinishedExercises,
  SetDrafts,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        // v2: tabela de atividades esportivas (módulo Atividades). Só cria
        // a tabela nova — nenhuma tabela existente é alterada.
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.createTable(sportActivities);
          // v3: exercícios finalizados dentro de uma sessão de treino.
          if (from < 3) await m.createTable(finishedExercises);
          // v4: rascunhos de carga/repetições do treino em andamento.
          if (from < 4) await m.createTable(setDrafts);
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'gym_system.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

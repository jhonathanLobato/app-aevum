import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../features/achievements/data/tables/achievement_table.dart';
import '../features/daily/data/tables/daily_tables.dart';
import '../features/daily/domain/daily_values.dart';
import '../features/rank_exam/data/tables/rank_exam_table.dart';
import 'default_library.dart';
import '../features/activities/data/tables/sport_activity_table.dart';
import '../features/activities/domain/sport_activity.dart';
import '../features/achievements/domain/achievement.dart';
import '../features/exercises/data/tables/exercise_table.dart';
import '../features/missions/data/tables/mission_table.dart';
import '../features/missions/domain/mission.dart';
import '../features/profile/data/tables/user_table.dart';
import '../features/profile/domain/app_theme.dart';
import '../features/profile/domain/level_curve.dart';
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
  ScheduleDays,
  DailyEntries,
  DailyDays,
  RankExams,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase()
      : _semearBiblioteca = true,
        super(_openConnection());

  AppDatabase.forTesting(super.executor) : _semearBiblioteca = false;

  /// Só o app real cria a biblioteca padrão (os testes começam vazios).
  final bool _semearBiblioteca;

  @override
  int get schemaVersion => 7;

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
          if (from < 5) {
            // v5: modalidades unificadas e fim da meta de séries/reps.
            await customStatement(
                "UPDATE sport_activities SET tipo = 'corridaCaminhada' WHERE tipo IN ('corrida', 'caminhada')");
            await customStatement(
                "UPDATE sport_activities SET tipo = 'muayThaiBoxe' WHERE tipo IN ('boxe', 'muayThai')");
            await m.alterTable(TableMigration(workoutTemplateExercises));
            // Missão diária nova (flexões/abdominais/km), programação
            // semanal e exame de rank. A missão diária antiga ("complete seu
            // treino") deixa de existir.
            await m.createTable(scheduleDays);
            await m.createTable(dailyEntries);
            await m.createTable(dailyDays);
            await m.createTable(rankExams);
            await customStatement(
                "UPDATE missions SET status = 'expirada' WHERE tipo = 'diaria' AND status = 'ativa'");
          }
          if (from < 6) {
            // v6: XP por atividade extra, rank-up pendente e nova curva de
            // nível (480 + 10 × nível).
            await m.addColumn(sportActivities, sportActivities.xpConcedido);
            if (from >= 5) await m.addColumn(rankExams, rankExams.visto);
            await _recalcularNivelDosUsuarios();
          }
          if (from < 7) {
            // v7: tempo mínimo por rank e exame iniciado pelo usuário.
            if (await _tabelaExiste('users')) {
              await m.addColumn(users, users.rankDesde);
              // Quem já existe conta o tempo no rank a partir de hoje.
              await customStatement(
                  'UPDATE users SET rank_desde = ${DateTime.now().millisecondsSinceEpoch ~/ 1000}');
            }
            if (await _tabelaExiste('rank_exams')) {
              await customStatement(
                  "UPDATE rank_exams SET status = 'disponivel' WHERE status = 'aguardando'");
            }
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          if (_semearBiblioteca && (details.wasCreated || details.hadUpgrade)) {
            await seedDefaultLibraryIfEmpty(this);
          }
        },
      );
}

extension on AppDatabase {
  /// Recalcula o nível pelo XP total com a curva atual (o rank não muda).
  Future<bool> _tabelaExiste(String nome) async {
    final r = await customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
        variables: [Variable.withString(nome)]).get();
    return r.isNotEmpty;
  }

  Future<void> _recalcularNivelDosUsuarios() async {
    if (!await _tabelaExiste('users')) return;
    for (final u in await select(users).get()) {
      final nivel = const LevelCurve().calcularNivel(u.xp).nivel;
      if (nivel != u.nivel) {
        await (update(users)..where((x) => x.id.equals(u.id)))
            .write(UsersCompanion(nivel: Value(nivel)));
      }
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'gym_system.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/database/app_database.dart';
import 'package:gym_system/features/activities/domain/sport_activity.dart';
import 'package:gym_system/features/progression/domain/personal_record.dart';
import 'package:gym_system/features/statistics/data/statistics_repository_impl.dart';
import 'package:gym_system/features/workouts/domain/workout_session.dart';

void main() {
  late AppDatabase db;
  late DriftStatisticsRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftStatisticsRepository(db);
  });

  tearDown(() => db.close());

  test('semana atual sempre aparece, mesmo sem registros', () async {
    final lista = await repo.watchWeeklyReports().first;
    expect(lista, hasLength(1));
    expect(lista.single.vazio, isTrue);
    expect(lista.single.inicio.weekday, DateTime.monday);
  });

  test(
      'agrupa treinos, atividades e recordes por semana, mais recente primeiro',
      () async {
    final exId = await db.into(db.exercises).insert(
        ExercisesCompanion.insert(nome: 'Supino', grupoMuscular: 'Peito'));
    Future<void> treino(DateTime d, {bool concluido = true}) =>
        db.into(db.workoutSessions).insert(WorkoutSessionsCompanion.insert(
              nome: 'T',
              status: concluido
                  ? WorkoutSessionStatus.concluido
                  : WorkoutSessionStatus.emAndamento,
              data: Value(d),
            ));

    // Semana de 02/03/2026 (seg) a 08/03: 2 treinos (1 em andamento ignorado
    // → conta só concluídos), 1 atividade, 2 recordes.
    await treino(DateTime(2026, 3, 2, 8));
    await treino(DateTime(2026, 3, 8, 20));
    await treino(DateTime(2026, 3, 4), concluido: false);
    await db.into(db.sportActivities).insert(SportActivitiesCompanion.insert(
        tipo: SportType.skate, data: DateTime(2026, 3, 5), duracaoMinutos: 40));
    for (final t in [PersonalRecordType.carga, PersonalRecordType.volume]) {
      await db.into(db.personalRecords).insert(PersonalRecordsCompanion.insert(
          exerciseId: exId,
          tipo: t,
          valor: 10,
          data: Value(DateTime(2026, 3, 3))));
    }
    // Semana anterior (23/02): 1 treino.
    await treino(DateTime(2026, 2, 25));

    final lista = await repo.watchWeeklyReports().first;
    final marco = lista.firstWhere((r) => r.inicio == DateTime(2026, 3, 2));
    final fev = lista.firstWhere((r) => r.inicio == DateTime(2026, 2, 23));

    expect([marco.treinos, marco.atividades, marco.recordes], [2, 1, 2]);
    expect([fev.treinos, fev.atividades, fev.recordes], [1, 0, 0]);
    expect(marco.fim, DateTime(2026, 3, 8));
    final datas = lista.map((r) => r.inicio).toList();
    expect(datas, [...datas]..sort((a, b) => b.compareTo(a)));
  });
}

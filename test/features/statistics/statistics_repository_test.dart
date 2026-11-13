import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/database/app_database.dart';
import 'package:gym_system/features/profile/data/profile_repository_impl.dart';
import 'package:gym_system/features/progression/domain/personal_record.dart';
import 'package:gym_system/features/statistics/data/statistics_repository_impl.dart';
import 'package:gym_system/features/workouts/domain/workout_session.dart';

void main() {
  late AppDatabase db;
  late DriftStatisticsRepository repo;
  late int supinoId;
  late int roscaId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftStatisticsRepository(db);

    supinoId = await db.into(db.exercises).insert(
          ExercisesCompanion.insert(
              nome: 'Supino reto', grupoMuscular: 'Peito'),
        );
    roscaId = await db.into(db.exercises).insert(
          ExercisesCompanion.insert(
              nome: 'Rosca direta', grupoMuscular: 'Bíceps'),
        );
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> criarSessaoConcluida({
    required DateTime data,
    int duracaoSegundos = 600,
  }) async {
    final id = await db.into(db.workoutSessions).insert(
          WorkoutSessionsCompanion.insert(
            nome: 'Treino',
            status: WorkoutSessionStatus.concluido,
          ),
        );
    await (db.update(db.workoutSessions)..where((s) => s.id.equals(id))).write(
      WorkoutSessionsCompanion(
        data: Value(data),
        duracaoSegundos: Value(duracaoSegundos),
      ),
    );
    return id;
  }

  Future<void> registrarSerie({
    required int sessionId,
    required int exerciseId,
    required int serie,
    required int repeticoes,
    required double carga,
    DateTime? data,
  }) {
    return db.into(db.setEntries).insert(
          SetEntriesCompanion.insert(
            sessionId: sessionId,
            exerciseId: exerciseId,
            serie: serie,
            repeticoes: repeticoes,
            carga: carga,
            volume: carga * repeticoes,
            data: data == null ? const Value.absent() : Value(data),
          ),
        );
  }

  test('estatísticas globais agregam treinos, volume, PRs e perfil', () async {
    final sessao1 = await criarSessaoConcluida(
        data: DateTime(2026, 1, 1), duracaoSegundos: 1800);
    await registrarSerie(
        sessionId: sessao1,
        exerciseId: supinoId,
        serie: 1,
        repeticoes: 10,
        carga: 30);
    await registrarSerie(
        sessionId: sessao1,
        exerciseId: roscaId,
        serie: 1,
        repeticoes: 12,
        carga: 10);

    final sessao2 = await criarSessaoConcluida(
        data: DateTime(2026, 1, 2), duracaoSegundos: 1200);
    await registrarSerie(
        sessionId: sessao2,
        exerciseId: supinoId,
        serie: 1,
        repeticoes: 10,
        carga: 32);

    await db.into(db.personalRecords).insert(
          PersonalRecordsCompanion.insert(
              exerciseId: supinoId, tipo: PersonalRecordType.carga, valor: 32),
        );

    await DriftProfileRepository(db).addXp(60);

    final stats = await repo.watchGlobal().first;

    expect(stats.treinosRealizados, 2);
    expect(stats.tempoTotalTreinando, const Duration(seconds: 3000));
    expect(stats.exerciciosRealizados, 2);
    expect(stats.totalPRs, 1);
    expect(stats.volumeTotal, 300 + 120 + 320);
    expect(stats.totalRepeticoes, 10 + 12 + 10);
    expect(stats.xpAcumulado, 60);
    expect(stats.nivelAtual, 1);
  });

  test('sessões em andamento ou canceladas não entram nas estatísticas',
      () async {
    final emAndamentoId = await db.into(db.workoutSessions).insert(
          WorkoutSessionsCompanion.insert(
            nome: 'Treino',
            status: WorkoutSessionStatus.emAndamento,
          ),
        );
    await registrarSerie(
        sessionId: emAndamentoId,
        exerciseId: supinoId,
        serie: 1,
        repeticoes: 10,
        carga: 30);

    final stats = await repo.watchGlobal().first;

    expect(stats.treinosRealizados, 0);
    expect(stats.volumeTotal, 0);
    expect(stats.exerciciosRealizados, 0);
  });

  test('maior sequência conta dias consecutivos com treino concluído',
      () async {
    await criarSessaoConcluida(data: DateTime(2026, 1, 1));
    await criarSessaoConcluida(data: DateTime(2026, 1, 2));
    await criarSessaoConcluida(data: DateTime(2026, 1, 3));
    // Furo no dia 4.
    await criarSessaoConcluida(data: DateTime(2026, 1, 5));

    final stats = await repo.watchGlobal().first;

    expect(stats.maiorSequenciaDias, 3);
  });

  test('sequência usa o dia local: treino às 22h em Brasília não pula de dia',
      () async {
    final brasilia = DriftStatisticsRepository(db,
        deslocamento: (_) => const Duration(hours: -3));
    // 22h de 10/03 e 10h de 11/03 em Brasília (01h e 13h de 11/03 em UTC).
    await criarSessaoConcluida(data: DateTime.utc(2026, 3, 11, 1));
    await criarSessaoConcluida(data: DateTime.utc(2026, 3, 11, 13));

    final stats = await brasilia.watchGlobal().first;

    expect(stats.maiorSequenciaDias, 2);
  });

  test('estatísticas por exercício calculam máximos e intervalo de datas',
      () async {
    final sessao1 = await criarSessaoConcluida(data: DateTime(2026, 1, 1));
    await registrarSerie(
        sessionId: sessao1,
        exerciseId: supinoId,
        serie: 1,
        repeticoes: 10,
        carga: 30,
        data: DateTime(2026, 1, 1));

    final sessao2 = await criarSessaoConcluida(data: DateTime(2026, 1, 10));
    await registrarSerie(
        sessionId: sessao2,
        exerciseId: supinoId,
        serie: 1,
        repeticoes: 8,
        carga: 32,
        data: DateTime(2026, 1, 10));
    await registrarSerie(
        sessionId: sessao2,
        exerciseId: supinoId,
        serie: 2,
        repeticoes: 12,
        carga: 28,
        data: DateTime(2026, 1, 10));

    final porExercicio = await repo.watchPerExercise().first;
    final supino = porExercicio.single;

    expect(supino.exerciseNome, 'Supino reto');
    expect(supino.maiorCarga, 32);
    expect(supino.maiorRepeticao, 12);
    expect(supino.maiorVolume, 28 * 12); // 336: maior volume que maior carga
    expect(supino.treinosRealizados, 2);
    expect(supino.primeiroRegistro, DateTime(2026, 1, 1));
    expect(supino.ultimoRegistro, DateTime(2026, 1, 10));
  });
}

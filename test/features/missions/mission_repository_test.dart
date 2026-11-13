import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/database/app_database.dart';
import 'package:gym_system/features/missions/data/mission_repository_impl.dart';
import 'package:gym_system/features/missions/domain/mission.dart';

void main() {
  late AppDatabase db;
  late DriftMissionRepository repo;
  late int exercicioId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftMissionRepository(db);
    exercicioId = await db.into(db.exercises).insert(
          ExercisesCompanion.insert(
              nome: 'Supino reto', grupoMuscular: 'Peito'),
        );
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> programar(int treinos) async {
    await db.delete(db.scheduleDays).go();
    for (var dia = 1; dia <= treinos; dia++) {
      await db
          .into(db.scheduleDays)
          .insert(ScheduleDaysCompanion.insert(weekday: Value(dia)));
    }
  }

  test('sem treinos programados não há missão semanal nem diária antiga',
      () async {
    await repo.ensureRecurringMissions();

    expect(await repo.watchActive().first, isEmpty);
    expect(await repo.registrarTreinoConcluido(), isEmpty);
    expect(
        await (db.select(db.missions)
              ..where((m) => m.tipo.equalsValue(MissionType.diaria)))
            .get(),
        isEmpty);
  });

  test('a missão semanal segue a programação: objetivo e XP da tabela',
      () async {
    const esperado = {1: 50, 2: 100, 3: 150, 4: 250, 5: 300, 6: 350, 7: 400};
    for (final e in esperado.entries) {
      await db.delete(db.missions).go();
      await programar(e.key);
      await repo.ensureRecurringMissions();

      final semanal = (await repo.watchActive().first).single;
      expect(semanal.tipo, MissionType.semanal);
      expect(semanal.objetivo, e.key, reason: '${e.key} treinos');
      expect(semanal.recompensaXp, e.value, reason: '${e.key} treinos');
    }
  });

  test('não duplica a missão semanal da mesma semana', () async {
    await programar(3);
    await repo.ensureRecurringMissions();
    await repo.ensureRecurringMissions();

    final ativas = await repo.watchActive().first;
    expect(ativas.where((m) => m.tipo == MissionType.semanal), hasLength(1));
  });

  test('tudo ou nada: só conclui ao fechar todos os treinos programados',
      () async {
    await programar(3);
    for (var i = 0; i < 2; i++) {
      expect(await repo.registrarTreinoConcluido(), isEmpty);
    }
    final parcial = (await repo.watchActive().first).single;
    expect(parcial.progresso, 2);

    final concluidas = await repo.registrarTreinoConcluido();
    expect(concluidas, hasLength(1));
    expect(concluidas.single.tipo, MissionType.semanal);
    expect(concluidas.single.status, MissionStatus.concluida);
    expect(concluidas.single.recompensaXp, 150);
  });

  test('treinos além do programado não concedem o XP da semanal de novo',
      () async {
    await programar(2);
    await repo.registrarTreinoConcluido();
    expect(await repo.registrarTreinoConcluido(), hasLength(1));
    expect(await repo.registrarTreinoConcluido(), isEmpty);

    final semanais = await (db.select(db.missions)
          ..where((m) => m.tipo.equalsValue(MissionType.semanal)))
        .get();
    expect(semanais, hasLength(1));
    expect(semanais.single.status, MissionStatus.concluida);
  });

  test('mudar a programação no meio da semana ajusta objetivo e XP', () async {
    await programar(4);
    await repo.ensureRecurringMissions();
    await programar(6);
    await repo.ensureRecurringMissions();

    final semanal = (await repo.watchActive().first).single;
    expect(semanal.objetivo, 6);
    expect(semanal.recompensaXp, 350);
  });

  test('primeiro recorde de carga cria um desafio para o próximo', () async {
    final concluido = await repo.registrarNovoRecordeDeCarga(
      exerciseId: exercicioId,
      exerciseNome: 'Supino reto',
      novoRecorde: 30,
    );

    expect(concluido, isNull);

    final ativas = await repo.watchActive().first;
    final desafio = ativas.single;
    expect(desafio.tipo, MissionType.desafio);
    expect(desafio.exerciseId, exercicioId);
    expect(desafio.objetivo, 32);
  });

  test('watchRecentHistory mostra missões concluídas, não as ainda ativas',
      () async {
    await programar(1);
    await repo.registrarTreinoConcluido();

    final historico = await repo.watchRecentHistory().first;
    expect(historico, hasLength(1));
    expect(historico.single.tipo, MissionType.semanal);
    expect(historico.single.status, MissionStatus.concluida);

    final ativas = await repo.watchActive().first;
    expect(ativas.any((m) => m.tipo == MissionType.semanal), isFalse);
  });

  test('bater a meta do desafio conclui e cria o próximo', () async {
    await repo.registrarNovoRecordeDeCarga(
      exerciseId: exercicioId,
      exerciseNome: 'Supino reto',
      novoRecorde: 30,
    );

    final concluido = await repo.registrarNovoRecordeDeCarga(
      exerciseId: exercicioId,
      exerciseNome: 'Supino reto',
      novoRecorde: 32,
    );

    expect(concluido, isNotNull);
    expect(concluido!.status, MissionStatus.concluida);
    expect(concluido.objetivo, 32);

    final ativas = await repo.watchActive().first;
    final proximo = ativas.single;
    expect(proximo.tipo, MissionType.desafio);
    expect(proximo.objetivo, 34);
  });
}

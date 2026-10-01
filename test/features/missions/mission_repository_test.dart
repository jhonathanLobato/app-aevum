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

  test('cria a missão diária e a semanal na primeira vez', () async {
    await repo.ensureRecurringMissions();

    final ativas = await repo.watchActive().first;
    expect(ativas.map((m) => m.tipo).toSet(), {
      MissionType.diaria,
      MissionType.semanal,
    });
    expect(ativas.firstWhere((m) => m.tipo == MissionType.diaria).objetivo, 1);
    expect(ativas.firstWhere((m) => m.tipo == MissionType.semanal).objetivo, 4);
  });

  test('não duplica missões já ativas no mesmo período', () async {
    await repo.ensureRecurringMissions();
    await repo.ensureRecurringMissions();

    final ativas = await repo.watchActive().first;
    expect(ativas.where((m) => m.tipo == MissionType.diaria), hasLength(1));
    expect(ativas.where((m) => m.tipo == MissionType.semanal), hasLength(1));
  });

  test('completar um treino avança a missão diária até concluí-la', () async {
    final concluidas = await repo.registrarTreinoConcluido();

    expect(concluidas, hasLength(1));
    expect(concluidas.single.tipo, MissionType.diaria);
    expect(concluidas.single.status, MissionStatus.concluida);
  });

  test('missão semanal só conclui depois do número necessário de treinos',
      () async {
    for (var i = 0; i < 3; i++) {
      final concluidas = await repo.registrarTreinoConcluido();
      expect(concluidas.any((m) => m.tipo == MissionType.semanal), isFalse);
    }

    final ativas = await repo.watchActive().first;
    final semanal = ativas.firstWhere((m) => m.tipo == MissionType.semanal);
    expect(semanal.progresso, 3);
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

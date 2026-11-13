import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/database/app_database.dart';
import 'package:gym_system/features/activities/data/sport_activity_repository_impl.dart';
import 'package:gym_system/features/activities/domain/sport_activity.dart';

SportActivityInput _input(
  SportType tipo, {
  DateTime? data,
  int duracao = 30,
  double? distancia,
  int? rounds,
  String? observacoes,
}) {
  return SportActivityInput(
    tipo: tipo,
    data: data ?? DateTime(2026, 10, 4),
    duracaoMinutos: duracao,
    distanciaKm: distancia,
    rounds: rounds,
    observacoes: observacoes,
  );
}

void main() {
  late AppDatabase db;
  late DriftSportActivityRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftSportActivityRepository(db);
  });

  tearDown(() async => db.close());

  test('persiste um registro com todos os campos', () async {
    final id = await repo.create(_input(
      SportType.corrida,
      distancia: 5.2,
      duracao: 31,
      observacoes: '  Sol forte  ',
    ));

    final lista = await repo.watchAll().first;
    expect(lista, hasLength(1));
    final a = lista.single;
    expect(a.id, id);
    expect(a.tipo, SportType.corrida);
    expect(a.data, DateTime(2026, 10, 4));
    expect(a.duracaoMinutos, 31);
    expect(a.distanciaKm, 5.2);
    expect(a.observacoes, 'Sol forte');
    expect(a.rounds, isNull);
  });

  test('campos que não fazem sentido pra modalidade não são gravados',
      () async {
    await repo.create(_input(SportType.basquete, distancia: 3, rounds: 4));
    await repo.create(_input(SportType.boxe, distancia: 3, rounds: 4));

    final lista = await repo.watchAll().first;
    final basquete = lista.firstWhere((a) => a.tipo == SportType.basquete);
    final boxe = lista.firstWhere((a) => a.tipo == SportType.boxe);
    expect(basquete.distanciaKm, isNull);
    expect(basquete.rounds, isNull);
    expect(boxe.distanciaKm, isNull);
    expect(boxe.rounds, 4);
  });

  test('edita um registro existente', () async {
    final id = await repo.create(_input(SportType.ciclismo, distancia: 20));

    await repo.update(
        id, _input(SportType.ciclismo, distancia: 25, duracao: 60));

    final a = (await repo.watchAll().first).single;
    expect(a.distanciaKm, 25);
    expect(a.duracaoMinutos, 60);
    expect((await repo.watchAll().first), hasLength(1));
  });

  test('exclui um registro', () async {
    final id = await repo.create(_input(SportType.skate));
    await repo.create(_input(SportType.skate, data: DateTime(2026, 9, 1)));

    await repo.delete(id);

    final lista = await repo.watchAll().first;
    expect(lista, hasLength(1));
    expect(lista.single.id, isNot(id));
  });

  test('filtra por modalidade (nada de outra modalidade aparece)', () async {
    await repo.create(_input(SportType.corrida));
    await repo.create(_input(SportType.corrida));
    await repo.create(_input(SportType.ciclismo));
    await repo.create(_input(SportType.boxe));

    final corridas = await repo.watchByType(SportType.corrida).first;
    final boxe = await repo.watchByType(SportType.boxe).first;
    final skate = await repo.watchByType(SportType.skate).first;

    expect(corridas, hasLength(2));
    expect(corridas.every((a) => a.tipo == SportType.corrida), isTrue);
    expect(boxe, hasLength(1));
    expect(skate, isEmpty);
  });

  test('limite devolve só os mais recentes, em ordem de data decrescente',
      () async {
    for (var dia = 1; dia <= 10; dia++) {
      await repo.create(_input(SportType.corrida,
          data: DateTime(2026, 9, dia), duracao: dia));
    }

    final recentes = await repo.watchByType(SportType.corrida, limite: 3).first;
    expect(recentes.map((a) => a.data.day), [10, 9, 8]);

    final completo = await repo.watchByType(SportType.corrida).first;
    expect(completo, hasLength(10));
  });

  test(
      'watchAll junta todas as modalidades ordenadas por data (base da Fase 2)',
      () async {
    await repo.create(_input(SportType.skate, data: DateTime(2026, 6, 1)));
    await repo.create(_input(SportType.corrida, data: DateTime(2026, 10, 1)));
    await repo.create(_input(SportType.boxe, data: DateTime(2026, 8, 1)));

    final lista = await repo.watchAll().first;
    expect(lista.map((a) => a.tipo),
        [SportType.corrida, SportType.boxe, SportType.skate]);
  });

  group('validações', () {
    test('duração zero ou negativa é recusada', () async {
      expect(() => repo.create(_input(SportType.corrida, duracao: 0)),
          throwsA(isA<SportActivityValidationException>()));
      expect(() => repo.create(_input(SportType.corrida, duracao: -5)),
          throwsA(isA<SportActivityValidationException>()));
      expect(await repo.watchAll().first, isEmpty);
    });

    test('distância negativa é recusada', () {
      expect(() => repo.create(_input(SportType.corrida, distancia: -1)),
          throwsA(isA<SportActivityValidationException>()));
    });

    test('rounds negativo é recusado', () {
      expect(() => repo.create(_input(SportType.boxe, rounds: -2)),
          throwsA(isA<SportActivityValidationException>()));
    });

    test('edição também valida', () async {
      final id = await repo.create(_input(SportType.corrida));
      expect(() => repo.update(id, _input(SportType.corrida, duracao: 0)),
          throwsA(isA<SportActivityValidationException>()));
    });

    test('distância e rounds são opcionais (nulos/zero passam)', () async {
      await repo.create(_input(SportType.corrida));
      await repo.create(_input(SportType.boxe, rounds: 0));
      expect(await repo.watchAll().first, hasLength(2));
    });
  });

  group('métricas derivadas', () {
    SportActivity ativ(SportType tipo, int min, double? km) => SportActivity(
          id: 1,
          tipo: tipo,
          data: DateTime(2026, 10, 4),
          duracaoMinutos: min,
          distanciaKm: km,
          criadoEm: DateTime(2026, 10, 4),
        );

    test('ritmo médio da corrida (min/km)', () {
      final ritmo = ativ(SportType.corrida, 31, 5.2).ritmoMinPorKm!;
      expect(ritmo, closeTo(31 / 5.2, 1e-9));
      expect(ativ(SportType.corrida, 31, 5.2).velocidadeMediaKmh, isNull);
    });

    test('caminhada também calcula ritmo', () {
      expect(ativ(SportType.caminhada, 60, 5).ritmoMinPorKm, 12);
    });

    test('velocidade média do ciclismo (km/h)', () {
      expect(ativ(SportType.ciclismo, 60, 25).velocidadeMediaKmh, 25);
      expect(ativ(SportType.ciclismo, 30, 15).velocidadeMediaKmh, 30);
      expect(ativ(SportType.ciclismo, 30, 15).ritmoMinPorKm, isNull);
    });

    test('sem distância (ou distância 0) não há métrica', () {
      expect(ativ(SportType.corrida, 30, null).ritmoMinPorKm, isNull);
      expect(ativ(SportType.corrida, 30, 0).ritmoMinPorKm, isNull);
      expect(ativ(SportType.ciclismo, 30, null).velocidadeMediaKmh, isNull);
    });

    test('modalidades sem distância nunca têm métrica', () {
      expect(ativ(SportType.futebol, 90, 5).ritmoMinPorKm, isNull);
      expect(ativ(SportType.futebol, 90, 5).velocidadeMediaKmh, isNull);
    });
  });

  test('registrar atividades não gera nenhum XP/gamificação', () async {
    await repo.create(_input(SportType.corrida, distancia: 5, duracao: 30));
    await repo.create(_input(SportType.futebol, duracao: 90));
    await repo.create(_input(SportType.boxe, rounds: 6));
    final id = await repo.create(_input(SportType.skate));
    await repo.update(id, _input(SportType.skate, duracao: 45));
    await repo.delete(id);

    expect(await db.select(db.users).get(), isEmpty);
    expect(await db.select(db.personalRecords).get(), isEmpty);
    expect(await db.select(db.missions).get(), isEmpty);
    expect(await db.select(db.achievements).get(), isEmpty);
    expect(await db.select(db.workoutSessions).get(), isEmpty);
    expect(await db.select(db.setEntries).get(), isEmpty);
  });

  test('migration v1 -> v2 cria a tabela de atividades', () async {
    final antigo = AppDatabase.forTesting(
      NativeDatabase.memory(
          setup: (raw) => raw.execute('PRAGMA user_version = 1')),
    );
    addTearDown(antigo.close);

    final antigoRepo = DriftSportActivityRepository(antigo);
    await antigoRepo.create(_input(SportType.corrida));

    expect(await antigoRepo.watchAll().first, hasLength(1));
  });
}

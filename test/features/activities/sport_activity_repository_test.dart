import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/features/profile/domain/units.dart';
import 'package:gym_system/database/app_database.dart';
import 'package:gym_system/features/activities/data/sport_activity_repository_impl.dart';
import 'package:gym_system/features/activities/domain/sport_activity.dart';
import 'package:gym_system/features/rank_exam/data/tables/rank_exam_table.dart';

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
      SportType.corridaCaminhada,
      distancia: 5.2,
      duracao: 31,
      observacoes: '  Sol forte  ',
    ));

    final lista = await repo.watchAll().first;
    expect(lista, hasLength(1));
    final a = lista.single;
    expect(a.id, id);
    expect(a.tipo, SportType.corridaCaminhada);
    expect(a.data, DateTime(2026, 10, 4));
    expect(a.duracaoMinutos, 31);
    expect(a.distanciaKm, 5.2);
    expect(a.observacoes, 'Sol forte');
    expect(a.rounds, isNull);
  });

  test('campos que não fazem sentido pra modalidade não são gravados',
      () async {
    await repo.create(_input(SportType.basquete, distancia: 3, rounds: 4));
    await repo.create(_input(SportType.muayThaiBoxe, distancia: 3, rounds: 4));

    final lista = await repo.watchAll().first;
    final basquete = lista.firstWhere((a) => a.tipo == SportType.basquete);
    final boxe = lista.firstWhere((a) => a.tipo == SportType.muayThaiBoxe);
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
    await repo.create(_input(SportType.corridaCaminhada));
    await repo.create(_input(SportType.corridaCaminhada));
    await repo.create(_input(SportType.ciclismo));
    await repo.create(_input(SportType.muayThaiBoxe));

    final corridas = await repo.watchByType(SportType.corridaCaminhada).first;
    final boxe = await repo.watchByType(SportType.muayThaiBoxe).first;
    final skate = await repo.watchByType(SportType.skate).first;

    expect(corridas, hasLength(2));
    expect(corridas.every((a) => a.tipo == SportType.corridaCaminhada), isTrue);
    expect(boxe, hasLength(1));
    expect(skate, isEmpty);
  });

  test('limite devolve só os mais recentes, em ordem de data decrescente',
      () async {
    for (var dia = 1; dia <= 10; dia++) {
      await repo.create(_input(SportType.corridaCaminhada,
          data: DateTime(2026, 9, dia), duracao: dia));
    }

    final recentes =
        await repo.watchByType(SportType.corridaCaminhada, limite: 3).first;
    expect(recentes.map((a) => a.data.day), [10, 9, 8]);

    final completo = await repo.watchByType(SportType.corridaCaminhada).first;
    expect(completo, hasLength(10));
  });

  test(
      'watchAll junta todas as modalidades ordenadas por data (base da Fase 2)',
      () async {
    await repo.create(_input(SportType.skate, data: DateTime(2026, 6, 1)));
    await repo.create(
        _input(SportType.corridaCaminhada, data: DateTime(2026, 10, 1)));
    await repo
        .create(_input(SportType.muayThaiBoxe, data: DateTime(2026, 8, 1)));

    final lista = await repo.watchAll().first;
    expect(lista.map((a) => a.tipo),
        [SportType.corridaCaminhada, SportType.muayThaiBoxe, SportType.skate]);
  });

  group('validações', () {
    test('duração zero ou negativa é recusada', () async {
      expect(() => repo.create(_input(SportType.corridaCaminhada, duracao: 0)),
          throwsA(isA<SportActivityValidationException>()));
      expect(() => repo.create(_input(SportType.corridaCaminhada, duracao: -5)),
          throwsA(isA<SportActivityValidationException>()));
      expect(await repo.watchAll().first, isEmpty);
    });

    test('distância negativa é recusada', () {
      expect(
          () => repo.create(_input(SportType.corridaCaminhada, distancia: -1)),
          throwsA(isA<SportActivityValidationException>()));
    });

    test('rounds negativo é recusado', () {
      expect(() => repo.create(_input(SportType.muayThaiBoxe, rounds: -2)),
          throwsA(isA<SportActivityValidationException>()));
    });

    test('edição também valida', () async {
      final id = await repo.create(_input(SportType.corridaCaminhada));
      expect(
          () => repo.update(id, _input(SportType.corridaCaminhada, duracao: 0)),
          throwsA(isA<SportActivityValidationException>()));
    });

    test('distância e rounds são opcionais (nulos/zero passam)', () async {
      await repo.create(_input(SportType.corridaCaminhada));
      await repo.create(_input(SportType.muayThaiBoxe, rounds: 0));
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
      final ritmo = ativ(SportType.corridaCaminhada, 31, 5.2).ritmoMinPorKm!;
      expect(ritmo, closeTo(31 / 5.2, 1e-9));
      expect(
          ativ(SportType.corridaCaminhada, 31, 5.2).velocidadeMediaKmh, isNull);
    });

    test('caminhada também calcula ritmo', () {
      expect(ativ(SportType.corridaCaminhada, 60, 5).ritmoMinPorKm, 12);
    });

    test('velocidade média do ciclismo (km/h)', () {
      expect(ativ(SportType.ciclismo, 60, 25).velocidadeMediaKmh, 25);
      expect(ativ(SportType.ciclismo, 30, 15).velocidadeMediaKmh, 30);
      expect(ativ(SportType.ciclismo, 30, 15).ritmoMinPorKm, isNull);
    });

    test('sem distância (ou distância 0) não há métrica', () {
      expect(ativ(SportType.corridaCaminhada, 30, null).ritmoMinPorKm, isNull);
      expect(ativ(SportType.corridaCaminhada, 30, 0).ritmoMinPorKm, isNull);
      expect(ativ(SportType.ciclismo, 30, null).velocidadeMediaKmh, isNull);
    });

    test('modalidades sem distância nunca têm métrica', () {
      expect(ativ(SportType.futebol, 90, 5).ritmoMinPorKm, isNull);
      expect(ativ(SportType.futebol, 90, 5).velocidadeMediaKmh, isNull);
    });
  });

  group('XP de atividades extras', () {
    // Semana de segunda 02/03/2026 a domingo 08/03/2026.
    DateTime dia(int d) => DateTime(2026, 3, d);

    Future<int> xp() async {
      final u = await db.select(db.users).getSingleOrNull();
      return u?.xp ?? 0;
    }

    test('30+ min vale 30 XP; menos de 30 min não vale nada', () async {
      await repo.create(_input(SportType.skate, data: dia(2), duracao: 29));
      expect(await xp(), 0);
      await repo.create(_input(SportType.skate, data: dia(2), duracao: 30));
      expect(await xp(), 30);
    });

    test('no máximo 3 por semana (seg–dom); a semana seguinte zera', () async {
      for (var d = 2; d <= 5; d++) {
        await repo.create(_input(SportType.futebol, data: dia(d), duracao: 60));
      }
      expect(await xp(), 90); // o 4º da semana não vale
      await repo.create(_input(SportType.futebol, data: dia(9), duracao: 60));
      expect(await xp(), 120); // segunda seguinte: nova semana
    });

    test('domingo e segunda ficam em semanas diferentes', () async {
      for (final d in [2, 3, 4]) {
        await repo.create(_input(SportType.skate, data: dia(d)));
      }
      await repo.create(_input(SportType.skate, data: dia(8))); // domingo: 4º
      expect(await xp(), 90);
      await repo.create(_input(SportType.skate, data: dia(9))); // segunda
      expect(await xp(), 120);
    });

    test('editar a duração para menos de 30 min tira o XP; voltar devolve',
        () async {
      final id = await repo.create(_input(SportType.skate, data: dia(3)));
      expect(await xp(), 30);
      await repo.update(id, _input(SportType.skate, data: dia(3), duracao: 20));
      expect(await xp(), 0);
      await repo.update(id, _input(SportType.skate, data: dia(3), duracao: 45));
      expect(await xp(), 30);
    });

    test('excluir tira o XP e promove o 4º registro da semana', () async {
      final ids = <int>[];
      for (var d = 2; d <= 5; d++) {
        ids.add(await repo.create(_input(SportType.skate, data: dia(d))));
      }
      expect(await xp(), 90);
      await repo.delete(ids.first);
      // Perde 30 do excluído e ganha 30 do que entrou no limite de 3.
      expect(await xp(), 90);
      await repo.delete(ids[1]);
      expect(await xp(), 60);
    });

    test('mudar a data para outra semana move o XP entre as semanas', () async {
      for (var d = 2; d <= 4; d++) {
        await repo.create(_input(SportType.skate, data: dia(d)));
      }
      final extra =
          await repo.create(_input(SportType.skate, data: dia(5))); // 4º: 0 XP
      expect(await xp(), 90);
      await repo.update(extra, _input(SportType.skate, data: dia(11)));
      expect(await xp(), 120); // agora é o 1º da semana seguinte
    });

    test('continua sem PR, missão, conquista nem treino', () async {
      await repo.create(
          _input(SportType.corridaCaminhada, distancia: 5, duracao: 30));
      expect(await db.select(db.personalRecords).get(), isEmpty);
      expect(await db.select(db.missions).get(), isEmpty);
      expect(await db.select(db.achievements).get(), isEmpty);
      expect(await db.select(db.workoutSessions).get(), isEmpty);
      expect(await db.select(db.setEntries).get(), isEmpty);
    });
  });

  test('migration v4 -> v5 unifica modalidades e remove metas do treino',
      () async {
    final antigo = AppDatabase.forTesting(
      NativeDatabase.memory(setup: (raw) {
        raw.execute('PRAGMA user_version = 4');
        raw.execute(
            'CREATE TABLE sport_activities (id INTEGER PRIMARY KEY AUTOINCREMENT, tipo TEXT NOT NULL, data INTEGER NOT NULL, duracao_minutos INTEGER NOT NULL, distancia_km REAL NULL, rounds INTEGER NULL, observacoes TEXT NULL, criado_em INTEGER NOT NULL DEFAULT 0)');
        raw.execute(
            "INSERT INTO sport_activities (tipo, data, duracao_minutos) VALUES ('corrida', 0, 30), ('caminhada', 0, 40), ('boxe', 0, 50), ('muayThai', 0, 60), ('skate', 0, 20)");
        raw.execute(
            'CREATE TABLE workout_template_exercises (id INTEGER PRIMARY KEY AUTOINCREMENT, template_id INTEGER NOT NULL, exercise_id INTEGER NOT NULL, ordem INTEGER NOT NULL, series_alvo INTEGER NULL, repeticoes_alvo INTEGER NULL)');
        raw.execute(
            'CREATE TABLE missions (id INTEGER PRIMARY KEY AUTOINCREMENT, tipo TEXT NOT NULL, nome TEXT NOT NULL, descricao TEXT NOT NULL, recompensa_xp INTEGER NOT NULL, progresso INTEGER NOT NULL DEFAULT 0, objetivo INTEGER NOT NULL, status TEXT NOT NULL DEFAULT "ativa", criado_em INTEGER NOT NULL DEFAULT 0, exercise_id INTEGER NULL)');
      }),
    );
    addTearDown(antigo.close);

    final tipos = (await antigo.select(antigo.sportActivities).get())
        .map((a) => a.tipo)
        .toList();
    expect(tipos, [
      SportType.corridaCaminhada,
      SportType.corridaCaminhada,
      SportType.muayThaiBoxe,
      SportType.muayThaiBoxe,
      SportType.skate,
    ]);
    final colunas = await antigo
        .customSelect('PRAGMA table_info(workout_template_exercises)')
        .get();
    expect(colunas.map((c) => c.read<String>('name')),
        ['id', 'template_id', 'exercise_id', 'ordem']);
  });

  test(
      'migration v5 -> v8: nível recalculado, rank mantido, rank_desde = hoje, ficha',
      () async {
    final antigo = AppDatabase.forTesting(
      NativeDatabase.memory(setup: (raw) {
        raw.execute('PRAGMA user_version = 5');
        raw.execute(
            'CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, nome TEXT NOT NULL, avatar TEXT NULL, classe TEXT NOT NULL, titulo TEXT NULL, tema TEXT NOT NULL DEFAULT "escuro", xp INTEGER NOT NULL DEFAULT 0, nivel INTEGER NOT NULL DEFAULT 1, rank TEXT NOT NULL DEFAULT "F")');
        // 5.000 XP: com a curva antiga era nível 3; com a nova é nível 10.
        raw.execute(
            "INSERT INTO users (nome, classe, xp, nivel, rank) VALUES ('Astra', 'guerreiro', 5000, 3, 'E')");
        raw.execute(
            'CREATE TABLE sport_activities (id INTEGER PRIMARY KEY AUTOINCREMENT, tipo TEXT NOT NULL, data INTEGER NOT NULL, duracao_minutos INTEGER NOT NULL, distancia_km REAL NULL, rounds INTEGER NULL, observacoes TEXT NULL, criado_em INTEGER NOT NULL DEFAULT 0)');
        raw.execute(
            'CREATE TABLE rank_exams (id INTEGER PRIMARY KEY AUTOINCREMENT, rank_alvo TEXT NOT NULL, inicio INTEGER NOT NULL, prazo_dias INTEGER NOT NULL, modalidades TEXT NOT NULL DEFAULT "", status TEXT NOT NULL DEFAULT "ativo", reinicios INTEGER NOT NULL DEFAULT 0)');
        raw.execute(
            "INSERT INTO rank_exams (rank_alvo, inicio, prazo_dias, status) VALUES ('E', 0, 35, 'aguardando')");
      }),
    );
    addTearDown(antigo.close);

    final u = await antigo.select(antigo.users).getSingle();
    expect(u.xp, 5000);
    expect(u.nivel, 10);
    expect(u.rank, 'E'); // o rank atual não cai
    // v8: título vira "Despertado", unidades padrão e data de criação.
    expect(u.titulo, 'Despertado');
    expect(u.unidadePeso, WeightUnit.kg);
    expect(u.unidadeComprimento, LengthUnit.cm);
    expect(u.alturaCm, isNull);
    expect(u.criadoEm, isNotNull);
    expect(await antigo.select(antigo.bodyRecords).get(), isEmpty);
    // Quem já existe conta o tempo no rank a partir de hoje.
    final agora = DateTime.now();
    expect(u.rankDesde, isNotNull);
    expect(agora.difference(u.rankDesde!).inMinutes.abs(), lessThan(5));
    // O antigo "aguardando" vira "disponível" (exame ainda não iniciado).
    final exameAntigo = await antigo.select(antigo.rankExams).getSingle();
    expect(exameAntigo.status, RankExamStatus.disponivel);
    final colunas =
        await antigo.customSelect('PRAGMA table_info(sport_activities)').get();
    expect(
        colunas.map((c) => c.read<String>('name')), contains('xp_concedido'));
    final exame =
        await antigo.customSelect('PRAGMA table_info(rank_exams)').get();
    expect(exame.map((c) => c.read<String>('name')), contains('visto'));
  });
}

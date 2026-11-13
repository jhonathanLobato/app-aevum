import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/database/app_database.dart';
import 'package:gym_system/features/activities/domain/sport_activity.dart';
import 'package:gym_system/features/daily/domain/daily_values.dart';
import 'package:gym_system/features/profile/data/profile_repository_impl.dart';
import 'package:gym_system/features/profile/domain/level_curve.dart';
import 'package:gym_system/features/rank_exam/data/rank_exam_repository_impl.dart';
import 'package:gym_system/features/rank_exam/domain/rank_exam.dart';
import 'package:gym_system/features/workouts/domain/workout_session.dart';

void main() {
  late AppDatabase db;
  late DriftProfileRepository perfil;
  late DriftRankExamRepository repo;

  // Segunda-feira 02/03/2026, 10h: o usuário entrou no rank F em 01/01 e, por
  // padrão, já acumulou a experiência mínima do F (12 treinos).
  final inicio = DateTime(2026, 3, 2, 10);
  final entrouNoRank = DateTime(2026, 1, 1, 9);
  var agora = inicio;

  const extras = [SportType.ciclismo, SportType.skate, SportType.futebol];

  setUp(() {
    agora = inicio;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    perfil = DriftProfileRepository(db, agora: () => agora);
    repo = DriftRankExamRepository(db, perfil, agora: () => agora);
  });

  tearDown(() => db.close());

  Future<void> treinoNoDia(DateTime dia) =>
      db.into(db.workoutSessions).insert(WorkoutSessionsCompanion.insert(
            nome: 'Treino',
            status: WorkoutSessionStatus.concluido,
            data: Value(DateTime(dia.year, dia.month, dia.day, 18)),
          ));

  /// Cria o usuário em 01/01 (entrada no rank F) já com XP para o [nivel] e
  /// [treinos] treinos concluídos em dias distintos depois da entrada no rank
  /// (1 ponto de experiência cada; o mínimo do F é 12).
  Future<void> usuarioNoNivel(int nivel, {int treinos = 12}) async {
    final relogio = agora;
    agora = entrouNoRank;
    await perfil.addXp(const LevelCurve().xpNoInicioDoNivel(nivel));
    agora = relogio;
    for (var i = 0; i < treinos; i++) {
      await treinoNoDia(DateTime(2026, 1, 2 + i));
    }
  }

  /// Dias de treino programados (1=segunda … 7=domingo).
  Future<void> programar(List<int> dias) async {
    await db.delete(db.scheduleDays).go();
    for (final d in dias) {
      await db
          .into(db.scheduleDays)
          .insert(ScheduleDaysCompanion.insert(weekday: Value(d)));
    }
  }

  Future<void> atividade(SportType tipo, DateTime quando, {int min = 30}) =>
      db.into(db.sportActivities).insert(SportActivitiesCompanion.insert(
            tipo: tipo,
            data: quando,
            duracaoMinutos: min,
          ));

  Future<void> missoesCumpridas(int n) async {
    for (var i = 0; i < n; i++) {
      final dia = somarDias(DateTime(2026, 3, 2), i);
      await db.into(db.dailyDays).insert(DailyDaysCompanion.insert(
          dia: chaveDoDia(dia), concluida: const Value(true)));
    }
  }

  Future<void> folga(DateTime dia) =>
      db.into(db.dailyDays).insert(DailyDaysCompanion.insert(
          dia: chaveDoDia(dia), folga: const Value(true)));

  Future<RankStatus> status() async => (await repo.watchStatus().first)!;

  /// Libera o exame F→E e o inicia na hora com [extras].
  Future<void> liberarEIniciar() async {
    await programar([1, 3, 5]);
    await usuarioNoNivel(10);
    await repo.sincronizar();
    expect(await repo.iniciarExame(extras), IniciarExameResultado.iniciado);
  }

  group('liberação: nível E experiência mínima no rank', () {
    test('nível ok mas sem a experiência mínima: continua bloqueado', () async {
      await programar([1, 3, 5]);
      await usuarioNoNivel(10, treinos: 11);

      expect(await repo.sincronizar(), isEmpty);
      var s = await status();
      expect(s.fase, RankExamPhase.bloqueado);
      expect(s.niveisFaltando, 0);
      expect(s.experiencia, 11);
      expect(s.experienciaMinima, 12);
      expect(s.experienciaFaltando, 1);
      expect(s.progressoExperiencia, closeTo(11 / 12, 1e-9));

      await treinoNoDia(DateTime(2026, 2, 1)); // 12º treino
      final eventos = await repo.sincronizar();
      expect(eventos.single.tipo, RankExamEventType.liberado);
      s = await status();
      expect(s.fase, RankExamPhase.disponivel);
      expect(s.experienciaFaltando, 0);
    });

    test('experiência ok mas sem o nível mínimo: continua bloqueado', () async {
      await programar([1, 3, 5]);
      await usuarioNoNivel(9);

      expect(await repo.sincronizar(), isEmpty);
      final s = await status();
      expect(s.fase, RankExamPhase.bloqueado);
      expect(s.niveisFaltando, 1);
      expect(s.experienciaFaltando, 0);
    });

    test('libera quando os DOIS são cumpridos, uma única vez', () async {
      await programar([1, 3, 5]);
      await usuarioNoNivel(10);

      final eventos = await repo.sincronizar();
      expect(eventos.single.tipo, RankExamEventType.liberado);
      expect(eventos.single.rankAlvo, 'E');
      expect(await repo.sincronizar(), isEmpty);

      final s = await status();
      expect(s.fase, RankExamPhase.disponivel);
      expect(s.liberadoEm, agora);
      expect(s.inicioAutomaticoEm, DateTime(2026, 3, 9));
    });

    test('o nível sobe pelo XP mas o rank só muda pelo exame', () async {
      await programar([1, 3, 5]);
      await usuarioNoNivel(30);
      expect((await perfil.watchCurrentUser().first)!.rank, 'F');
      await repo.sincronizar();
      expect((await status()).proximoRank, 'E');
    });

    test('usuário existente sem registro de entrada conta a partir de hoje',
        () async {
      await programar([1, 3, 5]);
      await usuarioNoNivel(10);
      await (db.update(db.users))
          .write(const UsersCompanion(rankDesde: Value<DateTime?>(null)));

      // Os treinos anteriores a hoje não contam: experiência zerada.
      expect(await repo.sincronizar(), isEmpty);
      final u = await db.select(db.users).getSingle();
      expect(u.rankDesde, agora);
      expect((await status()).experiencia, 0);
    });

    test('experiência mínima por rank: F12, E15, D25, C50, B95, A210', () {
      expect(RankExamValues.experienciaMinimaNoRank,
          {'F': 12, 'E': 15, 'D': 25, 'C': 50, 'B': 95, 'A': 210});
      final valores = RankExamValues.experienciaMinimaNoRank.values.toList();
      for (var i = 1; i < valores.length; i++) {
        expect(valores[i], greaterThan(valores[i - 1])); // crescente
      }
    });

    test('treino conta 1 ponto (no máximo um por dia); missão não conta',
        () async {
      await programar([1, 3, 5]);
      await usuarioNoNivel(1, treinos: 0);
      await treinoNoDia(DateTime(2026, 2, 1));
      await treinoNoDia(DateTime(2026, 2, 1)); // 2º no mesmo dia: ignorado
      await treinoNoDia(DateTime(2025, 12, 31)); // antes de entrar no rank
      await missoesCumpridas(10);
      expect((await status()).experiencia, 1);
    });

    test('atividade extra: 0,5 ponto, só 30+ min, no máximo 4 por semana',
        () async {
      await programar([1, 3, 5]);
      await usuarioNoNivel(1, treinos: 0);
      // Semana de 02/02 a 08/02: 5 atividades de 30+ min (4 contam) + 1 curta.
      for (var d = 2; d <= 6; d++) {
        await atividade(SportType.ciclismo, DateTime(2026, 2, d));
      }
      await atividade(SportType.skate, DateTime(2026, 2, 7), min: 29);
      // Semana seguinte: 1 atividade.
      await atividade(SportType.futebol, DateTime(2026, 2, 9));
      expect((await status()).experiencia, 2.5); // (4 + 1) × 0,5
    });

    test('editar ou excluir o registro ajusta a experiência', () async {
      await programar([1, 3, 5]);
      await usuarioNoNivel(1, treinos: 0);
      for (var d = 2; d <= 6; d++) {
        await atividade(SportType.ciclismo, DateTime(2026, 2, d));
      }
      expect((await status()).experiencia, 2); // 4 × 0,5
      await (db.delete(db.sportActivities)..where((a) => a.id.equals(1))).go();
      expect((await status()).experiencia, 2); // o 5º entra no limite
      await (db.delete(db.sportActivities)..where((a) => a.id.equals(2))).go();
      expect((await status()).experiencia, 1.5);
      await (db.update(db.sportActivities)..where((a) => a.id.equals(3)))
          .write(const SportActivitiesCompanion(duracaoMinutos: Value(10)));
      expect((await status()).experiencia, 1);
    });

    test('tabela de exames: prazo, % de treinos, % de missão e extras', () {
      const s = RankExamValues.specs;
      List<T> col<T>(T Function(RankExamSpec) f) =>
          [for (final r in 'EDCBAS'.split('')) f(s[r]!)];
      expect(col((e) => e.prazoDias), [35, 50, 70, 90, 110, 140]);
      expect(col((e) => e.fracaoTreinos), [.80, .80, .85, .85, .90, .95]);
      expect(col((e) => e.fracaoMissaoDiaria), [.75, .75, .80, .80, .85, .90]);
      expect(col((e) => e.modalidades), [3, 3, 3, 4, 4, 4]);
      expect(col((e) => e.registrosPorModalidade), [1, 2, 2, 2, 3, 3]);
    });
  });

  group('início do exame', () {
    setUp(() async {
      await programar([1, 3, 5]);
      await usuarioNoNivel(10);
      await repo.sincronizar(); // libera
    });

    test('o exame não começa sozinho ao ser liberado', () async {
      final s = await status();
      expect(s.fase, RankExamPhase.disponivel);
      expect(s.exame, isNull);
    });

    test('iniciar com as atividades escolhidas: o prazo conta do início',
        () async {
      agora = inicio.add(const Duration(days: 3));
      expect(await repo.iniciarExame(extras), IniciarExameResultado.iniciado);

      final s = await status();
      expect(s.fase, RankExamPhase.emAndamento);
      final e = s.exame!;
      expect(e.inicio, agora);
      expect(e.diasRestantes, 35);
      expect(e.modalidades.map((m) => m.tipo), extras);
    });

    test('exige a quantidade certa de atividades extras', () async {
      expect(await repo.iniciarExame([SportType.skate]),
          IniciarExameResultado.modalidadesInvalidas);
      expect(await repo.iniciarExame(SportType.values),
          IniciarExameResultado.modalidadesInvalidas);
      expect((await status()).fase, RankExamPhase.disponivel);
    });

    test('exige 2+ dias de treino programados', () async {
      await programar([3]);
      expect(await repo.iniciarExame(extras),
          IniciarExameResultado.precisaProgramar);
      expect((await status()).precisaProgramar, isTrue);
      await programar([3, 5]);
      expect(await repo.iniciarExame(extras), IniciarExameResultado.iniciado);
    });

    test('sem exame disponível não há o que iniciar', () async {
      await repo.iniciarExame(extras);
      expect(
          await repo.iniciarExame(extras), IniciarExameResultado.indisponivel);
    });

    test('dentro da janela de 7 dias nada acontece sozinho', () async {
      agora = inicio.add(const Duration(days: 6, hours: 10));
      expect(await repo.sincronizar(), isEmpty);
      expect((await status()).fase, RankExamPhase.disponivel);
    });

    test('no 8º dia começa sozinho com as modalidades mais registradas',
        () async {
      for (var i = 0; i < 3; i++) {
        await atividade(SportType.futebol, inicio.subtract(Duration(days: i)));
      }
      for (var i = 0; i < 2; i++) {
        await atividade(SportType.skate, inicio.subtract(Duration(days: i)));
      }
      await atividade(SportType.muayThaiBoxe, inicio);
      await atividade(SportType.ciclismo, inicio); // empata: vale o catálogo

      agora = DateTime(2026, 3, 9, 8);
      final eventos = await repo.sincronizar();

      expect(eventos.single.tipo, RankExamEventType.iniciadoAutomaticamente);
      expect(eventos.single.modalidades,
          [SportType.futebol, SportType.skate, SportType.ciclismo]);
      final s = await status();
      expect(s.fase, RankExamPhase.emAndamento);
      expect(s.exame!.inicio, agora);
    });

    test('sem nenhum registro, escolhe as primeiras do catálogo', () async {
      agora = DateTime(2026, 3, 9, 8);
      final eventos = await repo.sincronizar();
      expect(eventos.single.modalidades, [
        SportType.corridaCaminhada,
        SportType.ciclismo,
        SportType.muayThaiBoxe,
      ]);
    });

    test('o início automático espera ter 2+ dias de treino programados',
        () async {
      await programar([3]);
      agora = DateTime(2026, 3, 12, 8);
      expect(await repo.sincronizar(), isEmpty);
      expect((await status()).fase, RankExamPhase.disponivel);

      await programar([3, 5]);
      expect((await repo.sincronizar()).single.tipo,
          RankExamEventType.iniciadoAutomaticamente);
    });
  });

  group('metas', () {
    setUp(liberarEIniciar);

    test('meta de treinos = ⌈% × treinos programados no período⌉', () async {
      final e = (await status()).exame!;
      // 35 dias = 5 semanas × 3 = 15 programados; 80% → 12.
      expect(e.treinosProgramadosNoPeriodo, 15);
      expect(e.treinosNecessarios, 12);
      expect(e.missoesNecessarias, 27); // ⌈75% × 35⌉
    });

    test('muda com a programação (pode ganhar dias durante o exame)', () async {
      await programar([1, 2, 3, 5]); // 4/semana → 20 programados
      final e = (await status()).exame!;
      expect(e.treinosProgramadosNoPeriodo, 20);
      expect(e.treinosNecessarios, 16);
    });

    test('folga em dia de treino tira o treino da meta e o dia da missão',
        () async {
      await folga(DateTime(2026, 3, 2)); // segunda: dia de treino
      await folga(DateTime(2026, 3, 4)); // quarta: dia de treino
      await folga(DateTime(2026, 3, 3)); // terça: sem treino

      final e = (await status()).exame!;
      expect(e.treinosProgramadosNoPeriodo, 13);
      expect(e.treinosNecessarios, 11); // ⌈0,8 × 13⌉ = ⌈10,4⌉
      expect(e.diasValidos, 32);
      expect(e.missoesNecessarias, 24); // ⌈0,75 × 32⌉
    });

    test('só conta treinos concluídos do período, um por dia, e extras 30+ min',
        () async {
      await treinoNoDia(inicio.add(const Duration(days: 1)));
      await treinoNoDia(inicio.add(const Duration(days: 1))); // mesmo dia
      await treinoNoDia(inicio.subtract(const Duration(days: 3))); // antes
      await atividade(SportType.ciclismo, inicio.add(const Duration(days: 1)));
      await atividade(SportType.skate, inicio.add(const Duration(days: 1)),
          min: 29);
      await atividade(SportType.basquete, inicio.add(const Duration(days: 1)));

      final e = (await status()).exame!;
      expect(e.treinosFeitos, 1);
      expect(e.modalidadesCumpridas, 1);
      expect(e.modalidades.map((m) => m.registros), [1, 0, 0]);
    });
  });

  group('aprovação e rank up pendente', () {
    setUp(liberarEIniciar);

    Future<void> cumprirTudo() async {
      for (var i = 0; i < 12; i++) {
        await treinoNoDia(inicio.add(Duration(days: i)));
      }
      for (final t in extras) {
        await atividade(t, inicio.add(const Duration(days: 2)));
      }
      await missoesCumpridas(27);
    }

    test('com tudo cumprido, aprova e só então o rank sobe', () async {
      await cumprirTudo();
      agora = inicio.add(const Duration(days: 30));

      final eventos = await repo.sincronizar();

      expect(eventos.single.tipo, RankExamEventType.aprovado);
      expect(eventos.single.rankAnterior, 'F');
      expect(eventos.single.rankAlvo, 'E');
      expect((await perfil.watchCurrentUser().first)!.rank, 'E');
      expect((await status()).fase, RankExamPhase.bloqueado);
    });

    test('falta 1 requisito: não aprova', () async {
      await cumprirTudo();
      await (db.delete(db.sportActivities)
            ..where((a) => a.tipo.equalsValue(SportType.skate)))
          .go();
      expect(await repo.sincronizar(), isEmpty);
      expect((await perfil.watchCurrentUser().first)!.rank, 'F');
    });

    test('RANK UP não exibido volta na próxima abertura até ser confirmado',
        () async {
      await cumprirTudo();
      agora = inicio.add(const Duration(days: 30));
      await repo.sincronizar(); // aprova; o app "fecha" antes do overlay

      final proxima = await repo.sincronizar();
      expect(proxima.single.tipo, RankExamEventType.aprovado);
      expect(proxima.single.rankAnterior, 'F');
      expect(proxima.single.rankAlvo, 'E');

      await repo.confirmarRankUp('E');
      expect(await repo.sincronizar(), isEmpty);
    });

    test('o próximo exame (D) exige nível 25 E 15 de experiência no rank E',
        () async {
      await cumprirTudo();
      agora = inicio.add(const Duration(days: 30));
      await repo.sincronizar();
      await repo.confirmarRankUp('E');
      final entrouNoE = agora;

      // O excedente não passa: os treinos do exame (e do F) não contam no E.
      expect((await status()).experiencia, 0);
      expect(await repo.sincronizar(), isEmpty); // nível 10 < 25
      await usuarioNoNivel(25, treinos: 0);
      expect(await repo.sincronizar(), isEmpty); // falta a experiência no E

      for (var i = 0; i < 14; i++) {
        await treinoNoDia(entrouNoE.add(Duration(days: 1 + i)));
      }
      agora = entrouNoE.add(const Duration(days: 20));
      expect(await repo.sincronizar(), isEmpty); // 14 < 15

      await treinoNoDia(entrouNoE.add(const Duration(days: 15)));
      final eventos = await repo.sincronizar();
      expect(eventos.single.rankAlvo, 'D');
      expect(eventos.single.tipo, RankExamEventType.liberado);
    });
  });

  group('reinício: nova janela de 7 dias', () {
    setUp(liberarEIniciar);

    test('prazo vencido com requisito incompleto reinicia na hora', () async {
      for (var i = 0; i < 12; i++) {
        await treinoNoDia(inicio.add(Duration(days: i)));
      }
      await missoesCumpridas(27); // faltam as atividades extras
      agora = inicio.add(const Duration(days: 35));

      final eventos = await repo.sincronizar();

      expect(eventos.single.tipo, RankExamEventType.reiniciado);
      expect(eventos.single.motivo, RankExamResetReason.prazo);
      // Volta a ficar disponível: nova janela, sem atividades escolhidas.
      final s = await status();
      expect(s.fase, RankExamPhase.disponivel);
      expect(s.liberadoEm, agora);
      expect(s.exame, isNull);
      final exame = await db.select(db.rankExams).getSingle();
      expect(exame.reinicios, 1);
      expect(exame.modalidades, isEmpty);
    });

    test('meta de treinos impossível reinicia antes do prazo', () async {
      await missoesCumpridas(27);
      agora = inicio.add(const Duration(days: 30)); // restam 5 dias, meta 12

      final eventos = await repo.sincronizar();

      expect(eventos.single.motivo, RankExamResetReason.treinosImpossivel);
    });

    test('meta da missão diária impossível reinicia antes do prazo', () async {
      for (var i = 0; i < 12; i++) {
        await treinoNoDia(inicio.add(Duration(days: i)));
      }
      agora = inicio.add(const Duration(days: 9)); // restam 26 dias (< 27)

      final eventos = await repo.sincronizar();

      expect(eventos.single.motivo, RankExamResetReason.missaoDiariaImpossivel);
    });

    test('ainda possível: não reinicia', () async {
      agora = inicio.add(const Duration(days: 8));
      for (var i = 0; i < 12; i++) {
        await treinoNoDia(inicio.add(Duration(days: i)));
      }
      expect(await repo.sincronizar(), isEmpty);
    });

    test(
        'depois do reinício dá para iniciar de novo, ou começa sozinho em 7 dias',
        () async {
      agora = inicio.add(const Duration(days: 30));
      await repo.sincronizar(); // reinicia (treinos impossíveis)
      final reiniciadoEm = agora;

      // Iniciar manualmente: o progresso antigo não conta.
      await treinoNoDia(inicio.add(const Duration(days: 1)));
      expect(await repo.iniciarExame(extras), IniciarExameResultado.iniciado);
      final e = (await status()).exame!;
      expect(e.treinosFeitos, 0);
      expect(e.inicio, reiniciadoEm);
    });

    test('se não iniciar depois do reinício, começa sozinho 7 dias depois',
        () async {
      agora = inicio.add(const Duration(days: 30));
      await repo.sincronizar(); // reinicia
      agora = agora.add(const Duration(days: 7));

      final eventos = await repo.sincronizar();
      expect(eventos.single.tipo, RankExamEventType.iniciadoAutomaticamente);
    });
  });
}

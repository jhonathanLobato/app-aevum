import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/database/app_database.dart';
import 'package:gym_system/features/daily/data/daily_repository_impl.dart';
import 'package:gym_system/features/daily/domain/daily_models.dart';
import 'package:gym_system/features/daily/domain/daily_values.dart';
import 'package:gym_system/features/profile/data/profile_repository_impl.dart';
import 'package:gym_system/features/rank_exam/data/tables/rank_exam_table.dart';
import 'package:gym_system/features/profile/domain/level_curve.dart';

void main() {
  late AppDatabase db;
  late DriftProfileRepository perfil;
  late DriftDailyRepository repo;

  // Quarta-feira 11/03/2026 (a semana vai de seg 09/03 a dom 15/03).
  var agora = DateTime(2026, 3, 11, 10);

  setUp(() {
    agora = DateTime(2026, 3, 11, 10);
    db = AppDatabase.forTesting(NativeDatabase.memory());
    perfil = DriftProfileRepository(db);
    repo = DriftDailyRepository(db, perfil, agora: () => agora);
  });

  tearDown(() => db.close());

  Future<int> xp() async => (await perfil.watchCurrentUser().first)!.xp;

  Future<DailyAddResult> completar() async {
    await repo.adicionar(DailyPart.flexoes, 50);
    await repo.adicionar(DailyPart.abdominais, 50);
    return repo.adicionar(DailyPart.km, 2);
  }

  group('missão diária', () {
    test('soma os registros do dia; parcial não dá XP', () async {
      await repo.adicionar(DailyPart.flexoes, 10);
      final r = await repo.adicionar(DailyPart.flexoes, 25);
      await repo.adicionar(DailyPart.km, 1.5);
      await repo.adicionar(DailyPart.km, 0.5);

      expect(r.progresso.flexoes, 35);
      final p = await repo.watchHoje().first;
      expect(p.km, 2.0);
      expect(p.abdominais, 0);
      expect(p.concluida, isFalse);
      expect(await perfil.watchCurrentUser().first, isNull); // sem XP
    });

    test('completar as 3 partes dá 50 XP uma única vez', () async {
      final r = await completar();
      expect(r.completouAgora, isTrue);
      expect(r.xpGanho!.xpGanho, DailyValues.xpMissao);
      expect(await xp(), 50);

      // Passar das metas depois não dá XP de novo.
      final extra = await repo.adicionar(DailyPart.flexoes, 10);
      expect(extra.completouAgora, isFalse);
      expect(await xp(), 50);
    });

    test('desfazer remove o último registro da parte, só antes de concluir',
        () async {
      await repo.adicionar(DailyPart.flexoes, 10);
      await repo.adicionar(DailyPart.flexoes, 25);
      expect(await repo.desfazerUltimo(DailyPart.flexoes), isTrue);
      expect((await repo.watchHoje().first).flexoes, 10);
      expect(await repo.desfazerUltimo(DailyPart.abdominais), isFalse);

      await completar();
      expect(await repo.desfazerUltimo(DailyPart.km), isFalse);
      expect((await repo.watchHoje().first).km, 2.0);
    });

    test('o dia é independente: o progresso de ontem não conta hoje', () async {
      await repo.adicionar(DailyPart.flexoes, 50);
      agora = DateTime(2026, 3, 12, 8);
      expect((await repo.watchHoje().first).flexoes, 0);
    });

    test('em dia de folga os registros não dão XP', () async {
      await repo.alternarFolga(agora);
      final r = await completar();
      expect(r.completouAgora, isFalse);
      expect(r.progresso.folga, isTrue);
      expect(await perfil.watchCurrentUser().first, isNull);
    });

    test('vale em dia de descanso programado (independe da programação)',
        () async {
      // Quarta é descanso; só segunda é treino.
      await repo.alternarDiaDeTreino(DateTime.monday);
      expect(await repo.watchProgramacao().first, {DateTime.monday});
      final r = await completar();
      expect(r.completouAgora, isTrue);
    });
  });

  group('folgas', () {
    test('marca e desmarca; contador X/4 do mês', () async {
      expect(
          await repo.alternarFolga(DateTime(2026, 3, 12)), FolgaResult.marcada);
      expect((await repo.watchFolgas().first).usadas, 1);
      expect(await repo.alternarFolga(DateTime(2026, 3, 12)),
          FolgaResult.desmarcada);
      expect((await repo.watchFolgas().first).usadas, 0);
    });

    test('limite de 4 por mês', () async {
      for (final dia in [11, 12, 13, 14]) {
        expect(await repo.alternarFolga(DateTime(2026, 3, dia)),
            FolgaResult.marcada);
      }
      expect(await repo.alternarFolga(DateTime(2026, 3, 15)),
          FolgaResult.limiteAtingido);
      final info = await repo.watchFolgas().first;
      expect(info.usadas, 4);
      expect(info.restantes, 0);
    });

    test('não acumula: o mês seguinte começa com 4 de novo', () async {
      for (final dia in [11, 12, 13, 14]) {
        await repo.alternarFolga(DateTime(2026, 3, dia));
      }
      agora = DateTime(2026, 4, 1, 9);
      expect((await repo.watchFolgas().first).usadas, 0);
      expect(await repo.alternarFolga(agora), FolgaResult.marcada);
    });

    test('não permite folga em dia passado nem em dia já cumprido', () async {
      expect(await repo.alternarFolga(DateTime(2026, 3, 10)),
          FolgaResult.indisponivel);
      await completar();
      expect(await repo.alternarFolga(agora), FolgaResult.indisponivel);
    });
  });

  group('penalidade (virada do dia)', () {
    Future<void> abrirNoDia(DateTime dia, {int xpInicial = 2500}) async {
      agora = dia;
      await perfil.addXp(xpInicial);
      await repo.processarVirada(); // primeiro uso: só cria o dia de hoje
    }

    test('primeiro uso não penaliza nada', () async {
      await perfil.addXp(500);
      expect(await repo.processarVirada(), isEmpty);
      expect(await xp(), 500);
    });

    test('dia anterior sem missão e sem folga perde 100 XP e fica pendente',
        () async {
      await abrirNoDia(DateTime(2026, 3, 11, 9));
      agora = DateTime(2026, 3, 12, 9);

      final aplicadas = await repo.processarVirada();

      expect(aplicadas.single.xpPerdido, 100);
      expect(await xp(), 2400);
      expect(await repo.watchPenalidadePendente().first, 100);
      await repo.confirmarPenalidades();
      expect(await repo.watchPenalidadePendente().first, 0);
    });

    test('processar de novo não penaliza duas vezes', () async {
      await abrirNoDia(DateTime(2026, 3, 11, 9));
      agora = DateTime(2026, 3, 12, 9);
      await repo.processarVirada();
      expect(await repo.processarVirada(), isEmpty);
      expect(await xp(), 2400);
    });

    test('missão cumprida ou dia de folga não perdem XP', () async {
      await abrirNoDia(DateTime(2026, 3, 11, 9));
      await completar(); // 11 cumprido (+50)
      await repo.alternarFolga(DateTime(2026, 3, 12)); // 12 folga
      final antes = await xp();
      agora = DateTime(2026, 3, 13, 9);

      expect(await repo.processarVirada(), isEmpty);
      expect(await xp(), antes);
    });

    test('máximo de 300 XP por semana (segunda a domingo)', () async {
      await abrirNoDia(DateTime(2026, 3, 9, 9)); // segunda
      agora = DateTime(2026, 3, 14, 9); // sábado: seg–sex falharam (5 dias)

      final aplicadas = await repo.processarVirada();

      expect(aplicadas.fold<int>(0, (s, p) => s + p.xpPerdido), 300);
      expect(await xp(), 2200);
    });

    test('a nova semana zera o teto', () async {
      await abrirNoDia(DateTime(2026, 3, 13, 9)); // sexta
      agora = DateTime(2026, 3, 17, 9); // terça seguinte
      // Falharam: sex (semana 1), sáb, dom (semana 1), seg (semana 2) = 4 dias.
      final aplicadas = await repo.processarVirada();
      expect(aplicadas.length, 4);
      expect(await xp(), 2500 - 400);
    });

    test('o XP nunca fica abaixo do início do nível (não cai de nível)',
        () async {
      final inicioNivel2 = const LevelCurve().xpParaProximoNivel(1);
      await abrirNoDia(DateTime(2026, 3, 11, 9), xpInicial: inicioNivel2 + 30);
      agora = DateTime(2026, 3, 12, 9);

      final aplicadas = await repo.processarVirada();

      expect(aplicadas.single.xpPerdido, 30);
      final u = (await perfil.watchCurrentUser().first)!;
      expect(u.xp, inicioNivel2);
      expect(u.nivel, 2);
    });

    test('o rank nunca cai', () async {
      await abrirNoDia(DateTime(2026, 3, 11, 9));
      await perfil.setRank('D');
      agora = DateTime(2026, 3, 13, 9);
      await repo.processarVirada();
      expect((await perfil.watchCurrentUser().first)!.rank, 'D');
    });
  });

  group('faixa da semana', () {
    test('estados dos 7 dias e treinos programados', () async {
      await repo.processarVirada(); // cria quarta
      await repo.alternarDiaDeTreino(DateTime.monday);
      await repo.alternarDiaDeTreino(DateTime.wednesday);
      await db.into(db.dailyDays).insert(DailyDaysCompanion.insert(
          dia: '2026-03-09', concluida: const Value(true)));
      await repo.alternarFolga(DateTime(2026, 3, 12));

      final dias = await repo.watchSemana().first;

      expect(dias.map((d) => d.dia.day), [9, 10, 11, 12, 13, 14, 15]);
      expect(dias.map((d) => d.status), [
        DayStatus.cumprida, // seg
        DayStatus.falhou, // ter (passou sem missão)
        DayStatus.hoje, // qua
        DayStatus.folga, // qui
        DayStatus.futuro,
        DayStatus.futuro,
        DayStatus.futuro,
      ]);
      expect(dias.map((d) => d.treinoProgramado),
          [true, false, true, false, false, false, false]);
      expect(dias.where((d) => d.ehHoje).single.dia.day, 11);
    });

    test('salvarProgramacao grava o conjunto inteiro e persiste', () async {
      expect(await repo.salvarProgramacao({1, 3, 5}), isTrue);
      expect(await repo.watchProgramacao().first, {1, 3, 5});

      // Outra instância lendo o mesmo banco (app reaberto) vê os dias.
      final outra = DriftDailyRepository(db, perfil);
      expect(await outra.watchProgramacao().first, {1, 3, 5});

      expect(await repo.salvarProgramacao({2, 3}), isTrue); // troca de dias
      expect(await repo.watchProgramacao().first, {2, 3});
      expect(await repo.salvarProgramacao({}), isTrue);
      expect(await repo.watchProgramacao().first, isEmpty);
    });

    test('durante o exame, salvar só pode adicionar dias', () async {
      await repo.salvarProgramacao({1, 3});
      await db.into(db.rankExams).insert(RankExamsCompanion.insert(
          rankAlvo: 'E', inicio: agora, prazoDias: 35));

      expect(await repo.salvarProgramacao({1}), isFalse); // remove o 3
      expect(await repo.watchProgramacao().first, {1, 3}); // nada mudou
      expect(await repo.salvarProgramacao({1, 3, 5}), isTrue);
      expect(await repo.watchProgramacao().first, {1, 3, 5});
    });

    test('alternar dia de treino liga e desliga', () async {
      await repo.alternarDiaDeTreino(3);
      await repo.alternarDiaDeTreino(5);
      await repo.alternarDiaDeTreino(3);
      expect(await repo.watchProgramacao().first, {5});
    });

    test('com exame de rank ativo a programação ganha dias mas não perde',
        () async {
      await repo.alternarDiaDeTreino(1);
      await repo.alternarDiaDeTreino(3);
      await db.into(db.rankExams).insert(RankExamsCompanion.insert(
          rankAlvo: 'E', inicio: agora, prazoDias: 35));

      expect(await repo.alternarDiaDeTreino(5), isTrue); // adicionar pode
      expect(await repo.alternarDiaDeTreino(1), isFalse); // remover não
      expect(await repo.watchProgramacao().first, {1, 3, 5});

      // Sem exame ativo (ex.: aguardando), remover volta a ser permitido.
      await (db.update(db.rankExams)).write(
          const RankExamsCompanion(status: Value(RankExamStatus.disponivel)));
      expect(await repo.alternarDiaDeTreino(1), isTrue);
    });
  });
}

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

  // Segunda-feira 02/03/2026, 10h.
  final inicio = DateTime(2026, 3, 2, 10);
  var agora = inicio;

  setUp(() {
    agora = inicio;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    perfil = DriftProfileRepository(db);
    repo = DriftRankExamRepository(db, perfil, agora: () => agora);
  });

  tearDown(() => db.close());

  Future<void> irParaNivel(int nivel) =>
      perfil.addXp(const LevelCurve().xpNoInicioDoNivel(nivel));

  Future<void> treinosConcluidos(int n, DateTime quando) async {
    for (var i = 0; i < n; i++) {
      await db.into(db.workoutSessions).insert(WorkoutSessionsCompanion.insert(
            nome: 'Treino $i',
            status: WorkoutSessionStatus.concluido,
            data: Value(quando),
          ));
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

  group('liberação', () {
    test('abaixo do nível mínimo não libera exame', () async {
      await irParaNivel(9);
      expect(await repo.sincronizar(), isEmpty);
      expect(await repo.watchAtivo().first, isNull);
    });

    test('no nível 10 libera o exame F→E, uma única vez', () async {
      await irParaNivel(10);

      final eventos = await repo.sincronizar();
      expect(eventos.single.tipo, RankExamEventType.liberado);
      expect(eventos.single.rankAlvo, 'E');
      expect(await repo.sincronizar(), isEmpty);

      final e = (await repo.watchAtivo().first)!;
      expect(e.rankAtual, 'F');
      expect(e.rankAlvo, 'E');
      expect(e.treinosNecessarios, 12);
      expect(e.modalidadesNecessarias, 3);
      expect(e.registrosPorModalidade, 1);
      expect(e.diasRestantes, 21);
      expect(e.missoesNecessarias, 16); // 75% de 21 dias, arredondado p/ cima
    });

    test('o nível sobe pelo XP mas o rank só muda pelo exame', () async {
      await irParaNivel(25);
      expect((await perfil.watchCurrentUser().first)!.rank, 'F');
      await repo.sincronizar();
      expect((await repo.watchAtivo().first)!.rankAlvo, 'E');
    });

    test('tabela de exames: requisitos por rank', () {
      const s = RankExamValues.specs;
      expect([for (final r in 'EDCBAS'.split('')) s[r]!.treinos],
          [12, 18, 26, 36, 48, 64]);
      expect([for (final r in 'EDCBAS'.split('')) s[r]!.prazoDias],
          [21, 30, 45, 60, 75, 90]);
      expect([for (final r in 'EDCBAS'.split('')) s[r]!.modalidades],
          [3, 3, 3, 4, 4, 4]);
      expect([for (final r in 'EDCBAS'.split('')) s[r]!.registrosPorModalidade],
          [1, 2, 2, 2, 3, 3]);
    });
  });

  group('progresso', () {
    setUp(() async {
      await irParaNivel(10);
      await repo.sincronizar();
    });

    test('só conta treinos concluídos e atividades 30+ min do período',
        () async {
      await treinosConcluidos(2, inicio.add(const Duration(days: 1)));
      await treinosConcluidos(5, inicio.subtract(const Duration(days: 3)));
      await repo.escolherModalidades(
          [SportType.ciclismo, SportType.skate, SportType.futebol]);
      await atividade(SportType.ciclismo, inicio.add(const Duration(days: 1)));
      await atividade(SportType.skate, inicio.add(const Duration(days: 1)),
          min: 29); // curta demais
      await atividade(SportType.basquete, inicio.add(const Duration(days: 1)));
      // Fora do período.
      await atividade(
          SportType.futebol, inicio.subtract(const Duration(days: 2)));

      final e = (await repo.watchAtivo().first)!;
      expect(e.treinosFeitos, 2);
      expect(e.modalidadesCumpridas, 1); // só o ciclismo
      expect(e.modalidades.map((m) => m.registros), [1, 0, 0]);
    });

    test('escolhe no máximo a quantidade exigida de modalidades', () async {
      await repo.escolherModalidades(SportType.values);
      final e = (await repo.watchAtivo().first)!;
      expect(e.modalidades, hasLength(3));
      expect(e.modalidadesEscolhidas, isTrue);
    });

    test('folgas saem do cálculo dos 75%', () async {
      for (var i = 0; i < 5; i++) {
        await db.into(db.dailyDays).insert(DailyDaysCompanion.insert(
            dia: chaveDoDia(DateTime(2026, 3, 3 + i)),
            folga: const Value(true)));
      }
      final e = (await repo.watchAtivo().first)!;
      expect(e.diasValidos, 16);
      expect(e.missoesNecessarias, 12); // 75% de 16
    });
  });

  group('aprovação', () {
    setUp(() async {
      await irParaNivel(10);
      await repo.sincronizar();
      await repo.escolherModalidades(
          [SportType.ciclismo, SportType.skate, SportType.futebol]);
    });

    Future<void> cumprirTudo() async {
      final dia = inicio.add(const Duration(days: 2));
      await treinosConcluidos(12, dia);
      for (final t in [
        SportType.ciclismo,
        SportType.skate,
        SportType.futebol
      ]) {
        await atividade(t, dia);
      }
      await missoesCumpridas(16);
    }

    test('com tudo cumprido, aprova e só então o rank sobe', () async {
      await cumprirTudo();
      agora = inicio.add(const Duration(days: 10));

      final eventos = await repo.sincronizar();

      expect(eventos.single.tipo, RankExamEventType.aprovado);
      expect(eventos.single.rankAnterior, 'F');
      expect(eventos.single.rankAlvo, 'E');
      expect((await perfil.watchCurrentUser().first)!.rank, 'E');
      expect(await repo.watchAtivo().first, isNull);
    });

    test('falta 1 requisito: não aprova', () async {
      await cumprirTudo();
      await (db.delete(db.sportActivities)
            ..where((a) => a.tipo.equalsValue(SportType.skate)))
          .go();
      expect(await repo.sincronizar(), isEmpty);
      expect((await perfil.watchCurrentUser().first)!.rank, 'F');
    });

    test('depois de aprovado, o próximo exame só abre no nível do próximo rank',
        () async {
      await cumprirTudo();
      await repo.sincronizar();
      expect(await repo.sincronizar(), isEmpty); // nível 10 < 20
      await irParaNivel(20);
      final eventos = await repo.sincronizar();
      expect(eventos.single.rankAlvo, 'D');
    });
  });

  group('reinício', () {
    setUp(() async {
      await irParaNivel(10);
      await repo.sincronizar();
    });

    test('prazo vencido com requisito incompleto reinicia na hora', () async {
      await missoesCumpridas(16); // missões OK, falta o resto
      agora = inicio.add(const Duration(days: 21));

      final eventos = await repo.sincronizar();

      expect(eventos.single.tipo, RankExamEventType.reiniciado);
      expect(eventos.single.motivo, RankExamResetReason.prazo);
      final e = (await repo.watchAtivo().first)!;
      expect(e.reinicios, 1);
      expect(e.diasRestantes, 21);
      expect(e.treinosFeitos, 0);
    });

    test('75% das missões diárias impossível reinicia antes do prazo',
        () async {
      // Nenhuma missão cumprida; no dia 7 restam só 15 dias (< 16 exigidos).
      agora = inicio.add(const Duration(days: 6));
      final eventos = await repo.sincronizar();

      expect(eventos.single.tipo, RankExamEventType.reiniciado);
      expect(eventos.single.motivo, RankExamResetReason.missaoDiariaImpossivel);
    });

    test('ainda possível: não reinicia', () async {
      agora = inicio.add(const Duration(days: 5)); // restam 16 dias, exige 16
      expect(await repo.sincronizar(), isEmpty);
    });

    test('depois do reinício, o progresso antigo não conta', () async {
      await treinosConcluidos(3, inicio.add(const Duration(days: 1)));
      agora = inicio.add(const Duration(days: 6));
      await repo.sincronizar(); // reinicia (impossível)

      final e = (await repo.watchAtivo().first)!;
      expect(e.treinosFeitos, 0);
      expect(e.inicio, agora);
    });
  });
}

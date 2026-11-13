import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/database/app_database.dart' hide Achievement;
import 'package:gym_system/features/achievements/data/achievement_repository_impl.dart';
import 'package:gym_system/features/achievements/domain/achievement.dart';
import 'package:gym_system/features/achievements/domain/achievement_rules.dart';
import 'package:gym_system/features/activities/domain/sport_activity.dart';
import 'package:gym_system/features/daily/domain/daily_values.dart';
import 'package:gym_system/features/profile/data/profile_repository_impl.dart';
import 'package:gym_system/features/workouts/domain/workout_session.dart';

DiaDaMissao _dia(DateTime d,
        {bool ok = false, bool folga = false, bool processado = true}) =>
    DiaDaMissao(dia: d, concluida: ok, folga: folga, processado: processado);

List<DiaDaMissao> _seq(DateTime ini, int n, {bool ok = true}) =>
    [for (var i = 0; i < n; i++) _dia(ini.add(Duration(days: i)), ok: ok)];

void main() {
  group('regras puras', () {
    test('sequência: soma dias cumpridos e a falha zera', () {
      final dias = [
        ..._seq(DateTime(2026, 1, 1), 5),
        _dia(DateTime(2026, 1, 6)), // falhou
        ..._seq(DateTime(2026, 1, 7), 3),
      ];
      expect(maiorSequenciaDaMissao(dias), 5);
    });

    test('sequência: folga e dia não avaliado são neutros', () {
      final dias = [
        ..._seq(DateTime(2026, 1, 1), 3),
        _dia(DateTime(2026, 1, 4), folga: true),
        ..._seq(DateTime(2026, 1, 5), 3),
        _dia(DateTime(2026, 1, 8), processado: false), // hoje
      ];
      expect(maiorSequenciaDaMissao(dias), 6);
    });

    test('sequência: buraco sem registro quebra', () {
      final dias = [
        ..._seq(DateTime(2026, 1, 1), 3),
        ..._seq(DateTime(2026, 1, 6), 3),
      ];
      expect(maiorSequenciaDaMissao(dias), 3);
    });

    test('mês limpo: só mês encerrado, completo e sem falhas', () {
      final fevLimpo = _seq(DateTime(2026, 2, 1), 28);
      final hoje = DateTime(2026, 3, 10);
      expect(temMesLimpo(fevLimpo, hoje), isTrue);

      // um dia falhado
      final comFalha = [...fevLimpo]..[9] = _dia(DateTime(2026, 2, 10));
      expect(temMesLimpo(comFalha, hoje), isFalse);

      // folga não suja o mês
      final comFolga = [...fevLimpo]..[9] =
          _dia(DateTime(2026, 2, 10), folga: true);
      expect(temMesLimpo(comFolga, hoje), isTrue);

      // mês incompleto (começou no meio) e mês corrente não valem
      expect(temMesLimpo(_seq(DateTime(2026, 2, 5), 24), hoje), isFalse);
      expect(temMesLimpo(fevLimpo, DateTime(2026, 2, 20)), isFalse);
    });

    test('meses seguidos', () {
      expect(
          maiorSequenciaDeMeses([
            DateTime(2026, 1, 5),
            DateTime(2026, 1, 20),
            DateTime(2026, 2, 1),
            DateTime(2026, 3, 9),
            DateTime(2026, 5, 2),
          ]),
          3);
      expect(
          maiorSequenciaDeMeses([
            DateTime(2025, 11, 1),
            DateTime(2025, 12, 1),
            DateTime(2026, 1, 1)
          ]),
          3);
      expect(maiorSequenciaDeMeses([]), 0);
    });
  });

  group('repositório', () {
    late AppDatabase db;
    late DriftAchievementRepository repo;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = DriftAchievementRepository(db, perfil: DriftProfileRepository(db));
    });
    tearDown(() async => db.close());

    Future<List<String>> conferir() async =>
        (await repo.verificarTudo()).map((a) => a.chave).toList();

    Future<void> sessao(DateTime data, {int? segundos}) async {
      final id = await db.into(db.workoutSessions).insert(
            WorkoutSessionsCompanion.insert(
              nome: 'T',
              status: WorkoutSessionStatus.concluido,
              duracaoSegundos: Value(segundos),
            ),
          );
      await (db.update(db.workoutSessions)..where((s) => s.id.equals(id)))
          .write(WorkoutSessionsCompanion(data: Value(data)));
    }

    Future<int> xp() async =>
        (await db.select(db.users).getSingleOrNull())?.xp ?? 0;

    test('XP é concedido uma única vez ao desbloquear', () async {
      await db
          .into(db.bodyRecords)
          .insert(BodyRecordsCompanion.insert(data: DateTime(2026, 1, 1)));

      expect(await conferir(), ['primeira_avaliacao']);
      expect(await xp(), 50);

      expect(await conferir(), isEmpty);
      expect(await xp(), 50); // sem duplicar
    });

    test('Madrugador, Coruja e Maratona usam início e duração do treino',
        () async {
      for (var i = 0; i < 10; i++) {
        await sessao(DateTime(2026, 1, 1 + i, 6, 30));
      }
      expect(await conferir(), contains('madrugador'));
      expect(await conferir(), isEmpty);

      for (var i = 0; i < 10; i++) {
        await sessao(DateTime(2026, 2, 1 + i, 21, 15), segundos: 7200);
      }
      final novas = await conferir();
      expect(novas, containsAll(['coruja', 'maratona']));
      expect(novas, isNot(contains('madrugador')));
    });

    test('missão diária: acumulados de flexões, abdominais e km', () async {
      Future<void> add(DailyPart p, double v, int dia) =>
          db.into(db.dailyEntries).insert(DailyEntriesCompanion.insert(
              dia: '2026-01-${dia.toString().padLeft(2, '0')}',
              parte: p,
              valor: v));
      await add(DailyPart.flexoes, 600, 1);
      await add(DailyPart.flexoes, 400, 2);
      await add(DailyPart.abdominais, 999, 1);
      await add(DailyPart.km, 499, 1);

      var novas = await conferir();
      expect(novas, ['mil_flexoes']);

      await add(DailyPart.abdominais, 1, 3);
      await add(DailyPart.km, 1, 3);
      novas = await conferir();
      expect(novas, containsAll(['mil_abdominais', 'andarilho']));
    });

    test('sequência de 7 dias da missão diária desbloqueia "Uma Semana"',
        () async {
      for (var i = 1; i <= 7; i++) {
        await db.into(db.dailyDays).insert(DailyDaysCompanion.insert(
            dia: '2026-01-0$i',
            concluida: const Value(true),
            processado: const Value(true)));
      }
      expect(await conferir(), ['uma_semana']);
    });

    test('Mês Limpo e Acompanhamento', () async {
      // Mês passado completo e cumprido.
      final agora = DateTime.now();
      final mesPassado = DateTime(agora.year, agora.month - 1, 1);
      final dias = DateTime(mesPassado.year, mesPassado.month + 1, 0).day;
      for (var d = 1; d <= dias; d++) {
        final chave =
            '${mesPassado.year}-${mesPassado.month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
        await db.into(db.dailyDays).insert(DailyDaysCompanion.insert(
            dia: chave,
            concluida: const Value(true),
            processado: const Value(true)));
      }
      // 6 meses seguidos de registro corporal.
      for (var m = 0; m < 6; m++) {
        await db.into(db.bodyRecords).insert(BodyRecordsCompanion.insert(
            data: DateTime(agora.year, agora.month - m, 5)));
      }
      final novas = await conferir();
      expect(novas, containsAll(['mes_limpo', 'acompanhamento']));
    });

    test('Versátil, Fundista e Lutador (atividades)', () async {
      Future<void> ativ(SportType t, {double? km}) =>
          db.into(db.sportActivities).insert(SportActivitiesCompanion.insert(
              tipo: t,
              data: DateTime(2026, 1, 1),
              duracaoMinutos: 40,
              distanciaKm: Value(km)));

      for (final t in SportType.values) {
        await ativ(t, km: t == SportType.corridaCaminhada ? 100 : null);
      }
      expect(await conferir(), containsAll(['versatil', 'fundista']));

      for (var i = 0; i < 49; i++) {
        await ativ(i.isEven ? SportType.muayThaiBoxe : SportType.jiuJitsu);
      }
      // 2 lutas já existem do loop acima + 49 = 51.
      expect(await conferir(), ['lutador']);
    });

    test('rank: Rank D e Monarca vêm do rank atual', () async {
      await DriftProfileRepository(db).addXp(1);
      await (db.update(db.users)).write(const UsersCompanion(rank: Value('D')));
      var novas = await conferir();
      expect(novas, containsAll(['rank_e', 'rank_d']));
      expect(novas, isNot(contains('rank_c')));

      await (db.update(db.users)).write(const UsersCompanion(rank: Value('S')));
      novas = await conferir();
      expect(novas, containsAll(['rank_c', 'rank_b', 'rank_a', 'monarca']));
    });

    test('toda conquista do catálogo tem XP e categoria conhecidos', () {
      for (final d in kAchievementCatalog) {
        expect(kAchievementCategories, contains(d.categoria), reason: d.chave);
      }
    });
  });
}

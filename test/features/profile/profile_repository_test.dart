import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/database/app_database.dart';
import 'package:gym_system/features/profile/data/profile_repository_impl.dart';
import 'package:gym_system/features/profile/domain/level_curve.dart';

void main() {
  late AppDatabase db;
  late DriftProfileRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftProfileRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('cria o perfil na primeira concessão de XP', () async {
    expect(await repo.watchCurrentUser().first, isNull);

    await repo.addXp(30);

    final user = await repo.watchCurrentUser().first;
    expect(user, isNotNull);
    expect(user!.xp, 30);
    expect(user.nivel, 1);
    expect(user.rank, 'F');
  });

  test('acumula XP entre chamadas e recalcula o nível, sem mexer no rank',
      () async {
    const curve = LevelCurve();
    final xpParaNivel10 =
        List.generate(9, (i) => curve.xpParaProximoNivel(i + 1))
            .reduce((a, b) => a + b);

    await repo.addXp(xpParaNivel10);

    final user = await repo.watchCurrentUser().first;
    expect(user!.nivel, 10);
    // O rank só sobe pelo exame de rank, não pelo nível.
    expect(user.rank, 'F');
  });

  test('reporta subida de nível apenas quando ela realmente acontece',
      () async {
    const curve = LevelCurve();
    final xpParaNivel2 = curve.xpParaProximoNivel(1);

    final semSubida = await repo.addXp(xpParaNivel2 - 10);
    expect(semSubida.subiuDeNivel, isFalse);

    final comSubida = await repo.addXp(10);
    expect(comSubida.subiuDeNivel, isTrue);
    expect(comSubida.nivelAnterior, 1);
    expect(comSubida.novoNivel, 2);
  });

  test('XP nunca muda o rank (só o exame muda)', () async {
    const curve = LevelCurve();
    final xpParaNivel10 =
        List.generate(9, (i) => curve.xpParaProximoNivel(i + 1))
            .reduce((a, b) => a + b);

    final r = await repo.addXp(xpParaNivel10);
    expect(r.novoNivel, 10);
    expect(r.subiuDeRank, isFalse);
    expect(r.novoRank, 'F');

    await repo.setRank('E');
    expect((await repo.watchCurrentUser().first)!.rank, 'E');
  });

  group('removeXp (penalidade)', () {
    test('tira o XP pedido dentro do nível atual', () async {
      await repo.addXp(500);
      final perdido = await repo.removeXp(100);
      expect(perdido, 100);
      expect((await repo.watchCurrentUser().first)!.xp, 400);
    });

    test('nunca cai abaixo do início do nível atual (não perde nível)',
        () async {
      const curve = LevelCurve();
      final inicioNivel2 = curve.xpParaProximoNivel(1);
      await repo.addXp(inicioNivel2 + 30); // nível 2, 30 XP dentro do nível

      final perdido = await repo.removeXp(100);

      expect(perdido, 30);
      final user = (await repo.watchCurrentUser().first)!;
      expect(user.xp, inicioNivel2);
      expect(user.nivel, 2);
    });

    test('no início do nível não perde nada; o rank nunca cai', () async {
      await repo.addXp(10);
      await repo.setRank('D');
      expect(await repo.removeXp(100), 10);
      expect(await repo.removeXp(100), 0);
      expect((await repo.watchCurrentUser().first)!.rank, 'D');
    });
  });
}

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

  test('acumula XP entre chamadas e recalcula nível e rank', () async {
    const curve = LevelCurve();
    final xpParaNivel10 =
        List.generate(9, (i) => curve.xpParaProximoNivel(i + 1))
            .reduce((a, b) => a + b);

    await repo.addXp(xpParaNivel10);

    final user = await repo.watchCurrentUser().first;
    expect(user!.nivel, 10);
    expect(user.rank, 'E');
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
}

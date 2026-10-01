import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/database/app_database.dart';
import 'package:gym_system/features/profile/data/profile_repository_impl.dart';
import 'package:gym_system/features/profile/domain/app_theme.dart';
import 'package:gym_system/features/profile/domain/player_class.dart';

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

  test('updateProfile cria o perfil se ele ainda não existir', () async {
    await repo.updateProfile(nome: 'Ana', classe: PlayerClass.guardiao);

    final user = await repo.watchCurrentUser().first;
    expect(user!.nome, 'Ana');
    expect(user.classe, PlayerClass.guardiao);
  });

  test('campos não informados mantêm o valor atual', () async {
    await repo.updateProfile(
      nome: 'Ana',
      classe: PlayerClass.guardiao,
      titulo: 'Campeã',
      tema: AppTheme.claro,
    );

    await repo.updateProfile(avatar: 'star');

    final user = await repo.watchCurrentUser().first;
    expect(user!.nome, 'Ana');
    expect(user.classe, PlayerClass.guardiao);
    expect(user.titulo, 'Campeã');
    expect(user.tema, AppTheme.claro);
    expect(user.avatar, 'star');
  });

  test('XP e nível não são afetados por updateProfile', () async {
    await repo.addXp(100);
    await repo.updateProfile(nome: 'Ana');

    final user = await repo.watchCurrentUser().first;
    expect(user!.xp, 100);
  });
}

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/database/app_database.dart';
import 'package:gym_system/features/achievements/data/achievement_repository_impl.dart';
import 'package:gym_system/features/achievements/domain/achievement.dart';
import 'package:gym_system/features/workouts/domain/workout_session.dart';

void main() {
  late AppDatabase db;
  late DriftAchievementRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftAchievementRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> concluirSessao(DateTime data) async {
    final sessionId = await db.into(db.workoutSessions).insert(
          WorkoutSessionsCompanion.insert(
            nome: 'Treino',
            status: WorkoutSessionStatus.concluido,
          ),
        );
    await (db.update(db.workoutSessions)..where((s) => s.id.equals(sessionId)))
        .write(WorkoutSessionsCompanion(data: Value(data)));
  }

  test('popula o catálogo fixo, todas bloqueadas', () async {
    await repo.ensureCatalog();

    final todas = await repo.watchAll().first;
    expect(todas, hasLength(kAchievementCatalog.length));
    expect(todas.every((a) => a.status == AchievementStatus.bloqueada), isTrue);
  });

  test('chamar ensureCatalog de novo não duplica', () async {
    await repo.ensureCatalog();
    await repo.ensureCatalog();

    final todas = await repo.watchAll().first;
    expect(todas, hasLength(kAchievementCatalog.length));
  });

  test('completar o primeiro treino desbloqueia "Primeiros Passos"', () async {
    await concluirSessao(DateTime.now());

    final desbloqueadas = await repo.verificarPorTreinoConcluido();

    expect(desbloqueadas.map((a) => a.chave), ['primeiros_passos']);
  });

  test('completar 10 treinos desbloqueia também "Disciplina"', () async {
    for (var i = 0; i < 9; i++) {
      await concluirSessao(DateTime.now());
      await repo.verificarPorTreinoConcluido();
    }
    await concluirSessao(DateTime.now());

    final desbloqueadas = await repo.verificarPorTreinoConcluido();

    expect(desbloqueadas.map((a) => a.chave), ['disciplina']);
  });

  test('bater o primeiro PR desbloqueia "Evolução"', () async {
    final desbloqueadas = await repo.verificarPorNovoRecorde();

    expect(desbloqueadas.map((a) => a.chave), ['evolucao']);

    final semNovaDesbloqueio = await repo.verificarPorNovoRecorde();
    expect(semNovaDesbloqueio, isEmpty);
  });

  test(
      '"Superação" só desbloqueia se o PR vier 7+ dias depois do último treino concluído',
      () async {
    await concluirSessao(DateTime.now().subtract(const Duration(days: 2)));

    final cedoDemais = await repo.verificarPorNovoRecorde();
    expect(cedoDemais.map((a) => a.chave), ['evolucao']);

    // Empurra a data do único treino concluído para 8 dias atrás.
    await (db.update(db.workoutSessions)
          ..where((s) => s.status.equalsValue(WorkoutSessionStatus.concluido)))
        .write(WorkoutSessionsCompanion(
            data: Value(DateTime.now().subtract(const Duration(days: 8)))));

    final tardeOSuficiente = await repo.verificarPorNovoRecorde();
    expect(tardeOSuficiente.map((a) => a.chave), ['superacao']);
  });
}

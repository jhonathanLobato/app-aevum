import 'package:drift/drift.dart';

import '../../../database/app_database.dart' hide Achievement;
import '../../../database/app_database.dart' as db;
import '../../activities/domain/sport_activity.dart';
import '../../daily/domain/daily_values.dart';
import '../../profile/domain/level_curve.dart';
import '../../profile/domain/profile_repository.dart';
import '../../workouts/domain/workout_session.dart';
import '../domain/achievement.dart';
import '../domain/achievement_repository.dart';
import '../domain/achievement_rules.dart';

class DriftAchievementRepository implements AchievementRepository {
  /// [perfil] concede o XP das conquistas ao desbloquear; sem ele (testes
  /// isolados) a conquista só é marcada como desbloqueada.
  DriftAchievementRepository(this._db, {ProfileRepository? perfil})
      : _perfil = perfil;

  final AppDatabase _db;
  final ProfileRepository? _perfil;

  static const _ranksPorChave = {
    'rank_e': 'E',
    'rank_d': 'D',
    'rank_c': 'C',
    'rank_b': 'B',
    'rank_a': 'A',
    'monarca': 'S',
  };

  @override
  Stream<List<Achievement>> watchAll() {
    final query = _db.select(_db.achievements)
      ..orderBy([(a) => OrderingTerm(expression: a.id)]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<void> ensureCatalog() async {
    for (final definicao in kAchievementCatalog) {
      final existente = await (_db.select(_db.achievements)
            ..where((a) => a.chave.equals(definicao.chave)))
          .getSingleOrNull();
      if (existente != null) {
        await (_db.update(_db.achievements)
              ..where((a) => a.chave.equals(definicao.chave)))
            .write(AchievementsCompanion(
          nome: Value(definicao.nome),
          descricao: Value(definicao.descricao),
          requisito: Value(definicao.requisito),
        ));
      } else {
        await _db.into(_db.achievements).insert(
              AchievementsCompanion.insert(
                chave: definicao.chave,
                nome: definicao.nome,
                descricao: definicao.descricao,
                icone: Value(definicao.icone),
                requisito: definicao.requisito,
              ),
              // A abertura do app e a tela de Conquistas podem montar o
              // catálogo ao mesmo tempo: o segundo insert não pode falhar.
              mode: InsertMode.insertOrIgnore,
            );
      }
    }
  }

  @override
  Future<List<Achievement>> verificarRank() => verificarTudo();

  @override
  Future<List<Achievement>> verificarPorTreinoConcluido() => verificarTudo();

  @override
  Future<List<Achievement>> verificarPorNovoRecorde() {
    // O evento é um PR novo: "Evolução" vale já, e "Superação" (dias parados
    // até agora) só pode ser avaliada neste momento.
    return verificarTudo(aoBaterRecorde: true);
  }

  @override
  Future<List<Achievement>> verificarTudo({bool aoBaterRecorde = false}) {
    return _db.transaction(() async {
      await ensureCatalog();
      final criterios = await _criterios();
      if (aoBaterRecorde) {
        criterios['evolucao'] = true;
        if (await _passaramSeteDiasSemTreinar()) criterios['superacao'] = true;
      }

      final desbloqueadas = <Achievement>[];
      for (final definicao in kAchievementCatalog) {
        if (criterios[definicao.chave] != true) continue;
        final d = await _desbloquearSeNecessario(definicao);
        if (d != null) desbloqueadas.add(d);
      }
      return desbloqueadas;
    });
  }

  /// Critério de cada conquista, calculado dos dados reais (por isso editar
  /// ou apagar registros não deixa nada inconsistente).
  Future<Map<String, bool>> _criterios() async {
    final criterios = <String, bool>{};

    // Treinos concluídos: quantidade, horário de início e duração.
    final sessoes = await (_db.select(_db.workoutSessions)
          ..where((s) => s.status.equalsValue(WorkoutSessionStatus.concluido)))
        .get();
    final treinos = sessoes.length;
    const metasTreinos = {
      'primeiros_passos': 1,
      'disciplina': 10,
      'constancia': 25,
      'dedicado': 50,
      'veterano': 100,
      'lenda_da_academia': 250,
      'imortal': 500,
    };
    metasTreinos.forEach((k, meta) => criterios[k] = treinos >= meta);
    criterios['madrugador'] =
        sessoes.where((s) => s.data.hour < 7).length >= 10;
    criterios['coruja'] = sessoes.where((s) => s.data.hour >= 21).length >= 10;
    criterios['maratona'] =
        sessoes.any((s) => (s.duracaoSegundos ?? 0) >= 2 * 3600);

    // Volume acumulado (treinos concluídos).
    final volume = await _somarVolumeTotal();
    const metasVolume = {
      'primeiro_milhar': 1000.0,
      'dez_toneladas': 10000.0,
      'tita': 100000.0,
      'atlas': 1000000.0,
    };
    metasVolume.forEach((k, meta) => criterios[k] = volume >= meta);

    // Recordes pessoais.
    final prs = await _contarPRs();
    criterios['evolucao'] = prs >= 1;
    criterios['quebra_de_recorde'] = prs >= 5;
    criterios['recordista'] = prs >= 25;
    criterios['lenda_dos_recordes'] = prs >= 100;

    // Missão diária: acumulados e sequências.
    final flexoes = await _somarDaily(DailyPart.flexoes);
    final abdominais = await _somarDaily(DailyPart.abdominais);
    final km = await _somarDaily(DailyPart.km);
    criterios['mil_flexoes'] = flexoes >= 1000;
    criterios['dez_mil_flexoes'] = flexoes >= 10000;
    criterios['mil_abdominais'] = abdominais >= 1000;
    criterios['dez_mil_abdominais'] = abdominais >= 10000;
    criterios['andarilho'] = km >= 500;

    final dias = await _diasDaMissao();
    final sequencia = maiorSequenciaDaMissao(dias);
    criterios['uma_semana'] = sequencia >= 7;
    criterios['um_mes'] = sequencia >= 30;
    criterios['cem_dias'] = sequencia >= 100;
    criterios['sistema_absoluto'] = sequencia >= 365;
    criterios['mes_limpo'] = temMesLimpo(dias, DateTime.now());

    // Atividades.
    final atividades = await _db.select(_db.sportActivities).get();
    criterios['versatil'] =
        atividades.map((a) => a.tipo).toSet().length >= SportType.values.length;
    criterios['fundista'] = atividades
            .where((a) => a.tipo == SportType.corridaCaminhada)
            .fold<double>(0, (s, a) => s + (a.distanciaKm ?? 0)) >=
        100;
    criterios['lutador'] = atividades
            .where((a) =>
                a.tipo == SportType.muayThaiBoxe ||
                a.tipo == SportType.jiuJitsu)
            .length >=
        50;

    // Corpo.
    final registros = await _db.select(_db.bodyRecords).get();
    criterios['primeira_avaliacao'] = registros.isNotEmpty;
    criterios['acompanhamento'] =
        maiorSequenciaDeMeses(registros.map((r) => r.data)) >= 6;

    // Rank.
    final usuario = await (_db.select(_db.users)..limit(1)).getSingleOrNull();
    if (usuario != null) {
      _ranksPorChave.forEach((k, rank) {
        criterios[k] = rankAtende(usuario.rank, rank);
      });
    }

    return criterios;
  }

  Future<double> _somarVolumeTotal() async {
    final soma = _db.setEntries.volume.sum();
    final resultado = await (_db.selectOnly(_db.setEntries).join([
      innerJoin(
        _db.workoutSessions,
        _db.workoutSessions.id.equalsExp(_db.setEntries.sessionId),
      ),
    ])
          ..addColumns([soma])
          ..where(_db.workoutSessions.status
              .equalsValue(WorkoutSessionStatus.concluido)))
        .getSingle();
    return resultado.read(soma) ?? 0;
  }

  Future<int> _contarPRs() async {
    final contagem = _db.personalRecords.id.count();
    return (_db.selectOnly(_db.personalRecords)..addColumns([contagem]))
        .map((row) => row.read(contagem)!)
        .getSingle();
  }

  Future<double> _somarDaily(DailyPart parte) async {
    final soma = _db.dailyEntries.valor.sum();
    final resultado = await (_db.selectOnly(_db.dailyEntries)
          ..addColumns([soma])
          ..where(_db.dailyEntries.parte.equalsValue(parte)))
        .getSingle();
    return resultado.read(soma) ?? 0;
  }

  Future<List<DiaDaMissao>> _diasDaMissao() async {
    final linhas = await _db.select(_db.dailyDays).get();
    return [
      for (final l in linhas)
        () {
          final p = l.dia.split('-').map(int.parse).toList();
          return DiaDaMissao(
            dia: DateTime(p[0], p[1], p[2]),
            concluida: l.concluida,
            folga: l.folga,
            processado: l.processado,
          );
        }(),
    ];
  }

  Future<bool> _passaramSeteDiasSemTreinar() async {
    final ultimoTreino = await (_db.select(_db.workoutSessions)
          ..where((s) => s.status.equalsValue(WorkoutSessionStatus.concluido))
          ..orderBy([
            (s) => OrderingTerm(expression: s.data, mode: OrderingMode.desc)
          ])
          ..limit(1))
        .getSingleOrNull();

    if (ultimoTreino == null) return false;
    return DateTime.now().difference(ultimoTreino.data).inDays >= 7;
  }

  Future<Achievement?> _desbloquearSeNecessario(
      AchievementDefinition definicao) async {
    final chave = definicao.chave;
    final atual = await (_db.select(_db.achievements)
          ..where((a) => a.chave.equals(chave)))
        .getSingleOrNull();
    if (atual == null || atual.status == AchievementStatus.desbloqueada) {
      return null;
    }

    await (_db.update(_db.achievements)..where((a) => a.chave.equals(chave)))
        .write(
      AchievementsCompanion(
        status: const Value(AchievementStatus.desbloqueada),
        dataDesbloqueio: Value(DateTime.now()),
      ),
    );

    // O XP é concedido uma única vez: só chegamos aqui na transição
    // bloqueada → desbloqueada.
    if (definicao.xp > 0) await _perfil?.addXp(definicao.xp);

    final atualizada = await (_db.select(_db.achievements)
          ..where((a) => a.chave.equals(chave)))
        .getSingle();
    return _toDomain(atualizada);
  }

  Achievement _toDomain(db.Achievement row) {
    final definicao = kAchievementCatalog
        .where((d) => d.chave == row.chave)
        .cast<AchievementDefinition?>()
        .firstOrNull;
    return Achievement(
      id: row.id,
      chave: row.chave,
      nome: row.nome,
      descricao: row.descricao,
      icone: row.icone ?? 'emoji_events',
      requisito: row.requisito,
      status: row.status,
      dataDesbloqueio: row.dataDesbloqueio,
      xp: definicao?.xp ?? 0,
      categoria: definicao?.categoria ?? '',
    );
  }
}

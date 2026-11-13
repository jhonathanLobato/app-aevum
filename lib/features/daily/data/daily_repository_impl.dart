import 'package:drift/drift.dart';

import '../../../database/app_database.dart';
import '../../profile/domain/profile_repository.dart';
import '../domain/daily_models.dart';
import '../domain/daily_repository.dart';
import '../domain/daily_values.dart';

class DriftDailyRepository implements DailyRepository {
  DriftDailyRepository(this._db, this._profile, {DateTime Function()? agora})
      : _agora = agora ?? DateTime.now;

  final AppDatabase _db;
  final ProfileRepository _profile;
  final DateTime Function() _agora;

  Stream<T> _observar<T>(
      List<TableInfo> tabelas, Future<T> Function() carregar) async* {
    yield await carregar();
    yield* _db
        .tableUpdates(TableUpdateQuery.onAllTables(tabelas))
        .asyncMap((_) => carregar());
  }

  // ---------------------------------------------------------------- hoje

  Future<void> _garantirDia(String chave) async {
    final existe = await (_db.select(_db.dailyDays)
          ..where((d) => d.dia.equals(chave)))
        .getSingleOrNull();
    if (existe == null) {
      await _db
          .into(_db.dailyDays)
          .insert(DailyDaysCompanion.insert(dia: chave));
    }
  }

  Future<DailyProgress> _carregarProgresso(DateTime dia) async {
    final chave = chaveDoDia(dia);
    final entradas = await (_db.select(_db.dailyEntries)
          ..where((e) => e.dia.equals(chave)))
        .get();
    double soma(DailyPart p) => entradas
        .where((e) => e.parte == p)
        .fold<double>(0, (s, e) => s + e.valor);
    final linha = await (_db.select(_db.dailyDays)
          ..where((d) => d.dia.equals(chave)))
        .getSingleOrNull();
    return DailyProgress(
      dia: apenasData(dia),
      flexoes: soma(DailyPart.flexoes).round(),
      abdominais: soma(DailyPart.abdominais).round(),
      km: soma(DailyPart.km),
      folga: linha?.folga ?? false,
      concluida: linha?.concluida ?? false,
    );
  }

  @override
  Stream<DailyProgress> watchHoje() => _observar(
        [_db.dailyEntries, _db.dailyDays],
        () => _carregarProgresso(_agora()),
      );

  @override
  Future<DailyAddResult> adicionar(DailyPart parte, double valor) {
    return _db.transaction(() async {
      final hoje = apenasData(_agora());
      final chave = chaveDoDia(hoje);
      if (valor > 0) {
        await _db.into(_db.dailyEntries).insert(DailyEntriesCompanion.insert(
              dia: chave,
              parte: parte,
              valor: valor,
            ));
      }
      await _garantirDia(chave);
      var progresso = await _carregarProgresso(hoje);

      if (progresso.metasAtingidas &&
          !progresso.concluida &&
          !progresso.folga) {
        await (_db.update(_db.dailyDays)..where((d) => d.dia.equals(chave)))
            .write(const DailyDaysCompanion(concluida: Value(true)));
        final xp = await _profile.addXp(DailyValues.xpMissao);
        progresso = await _carregarProgresso(hoje);
        return DailyAddResult(progresso: progresso, xpGanho: xp);
      }
      return DailyAddResult(progresso: progresso);
    });
  }

  @override
  Future<bool> desfazerUltimo(DailyPart parte) {
    return _db.transaction(() async {
      final chave = chaveDoDia(_agora());
      final progresso = await _carregarProgresso(_agora());
      if (progresso.concluida) return false;
      final ultimo = await (_db.select(_db.dailyEntries)
            ..where((e) => e.dia.equals(chave) & e.parte.equalsValue(parte))
            ..orderBy([
              (e) => OrderingTerm(expression: e.id, mode: OrderingMode.desc)
            ])
            ..limit(1))
          .getSingleOrNull();
      if (ultimo == null) return false;
      await (_db.delete(_db.dailyEntries)..where((e) => e.id.equals(ultimo.id)))
          .go();
      return true;
    });
  }

  // -------------------------------------------------------------- semana

  @override
  Stream<List<WeekDayInfo>> watchSemana() => _observar(
        [_db.dailyDays, _db.scheduleDays],
        () async {
          final hoje = apenasData(_agora());
          final inicio = inicioDaSemana(hoje);
          final linhas = {
            for (final d in await _db.select(_db.dailyDays).get()) d.dia: d,
          };
          final programados = {
            for (final s in await _db.select(_db.scheduleDays).get()) s.weekday,
          };
          return [
            for (var i = 0; i < 7; i++)
              () {
                final dia = somarDias(inicio, i);
                final linha = linhas[chaveDoDia(dia)];
                final DayStatus status;
                if (linha?.folga ?? false) {
                  status = DayStatus.folga;
                } else if (linha?.concluida ?? false) {
                  status = DayStatus.cumprida;
                } else if (dia.isBefore(hoje)) {
                  status = DayStatus.falhou;
                } else if (dia == hoje) {
                  status = DayStatus.hoje;
                } else {
                  status = DayStatus.futuro;
                }
                return WeekDayInfo(
                  dia: dia,
                  status: status,
                  treinoProgramado: programados.contains(dia.weekday),
                  ehHoje: dia == hoje,
                );
              }(),
          ];
        },
      );

  // -------------------------------------------------------------- folgas

  Future<int> _folgasNoMes(DateTime ref) async {
    final prefixo = '${ref.year.toString().padLeft(4, '0')}-'
        '${ref.month.toString().padLeft(2, '0')}-';
    final linhas = await (_db.select(_db.dailyDays)
          ..where((d) => d.folga.equals(true) & d.dia.like('$prefixo%')))
        .get();
    return linhas.length;
  }

  @override
  Stream<FolgasInfo> watchFolgas() => _observar(
        [_db.dailyDays],
        () async => FolgasInfo(
          usadas: await _folgasNoMes(_agora()),
          total: DailyValues.folgasPorMes,
        ),
      );

  @override
  Future<FolgaResult> alternarFolga(DateTime dia) {
    return _db.transaction(() async {
      final alvo = apenasData(dia);
      final hoje = apenasData(_agora());
      if (alvo.isBefore(hoje)) return FolgaResult.indisponivel;

      final chave = chaveDoDia(alvo);
      await _garantirDia(chave);
      final linha = await (_db.select(_db.dailyDays)
            ..where((d) => d.dia.equals(chave)))
          .getSingle();

      if (linha.folga) {
        await (_db.update(_db.dailyDays)..where((d) => d.dia.equals(chave)))
            .write(const DailyDaysCompanion(folga: Value(false)));
        return FolgaResult.desmarcada;
      }
      if (linha.concluida) return FolgaResult.indisponivel;
      if (await _folgasNoMes(alvo) >= DailyValues.folgasPorMes) {
        return FolgaResult.limiteAtingido;
      }
      await (_db.update(_db.dailyDays)..where((d) => d.dia.equals(chave)))
          .write(const DailyDaysCompanion(folga: Value(true)));
      return FolgaResult.marcada;
    });
  }

  // ----------------------------------------------------------- penalidade

  @override
  Future<List<PenaltyApplied>> processarVirada() {
    return _db.transaction(() async {
      final hoje = apenasData(_agora());
      final hojeChave = chaveDoDia(hoje);

      final primeira = await (_db.select(_db.dailyDays)
            ..orderBy([(d) => OrderingTerm(expression: d.dia)])
            ..limit(1))
          .getSingleOrNull();
      if (primeira == null) {
        await _garantirDia(hojeChave);
        return const [];
      }

      // Materializa todos os dias entre o primeiro registrado e hoje.
      final partes = primeira.dia.split('-').map(int.parse).toList();
      var dia = DateTime(partes[0], partes[1], partes[2]);
      while (!dia.isAfter(hoje)) {
        await _garantirDia(chaveDoDia(dia));
        dia = somarDias(dia, 1);
      }

      final pendentes = await (_db.select(_db.dailyDays)
            ..where((d) =>
                d.processado.equals(false) &
                d.dia.isSmallerThanValue(hojeChave))
            ..orderBy([(d) => OrderingTerm(expression: d.dia)]))
          .get();

      final aplicadas = <PenaltyApplied>[];
      for (final linha in pendentes) {
        var perdido = 0;
        if (!linha.concluida && !linha.folga) {
          final p = linha.dia.split('-').map(int.parse).toList();
          final data = DateTime(p[0], p[1], p[2]);
          final semanaIni = chaveDoDia(inicioDaSemana(data));
          final semanaFim = chaveDoDia(somarDias(inicioDaSemana(data), 6));
          final daSemana = await (_db.select(_db.dailyDays)
                ..where((d) =>
                    d.dia.isBiggerOrEqualValue(semanaIni) &
                    d.dia.isSmallerOrEqualValue(semanaFim)))
              .get();
          final jaPerdido = daSemana.fold<int>(0, (s, d) => s + d.penalidadeXp);
          final permitido = DailyValues.penalidadeSemanalMax - jaPerdido;
          final aPerder = permitido <= 0
              ? 0
              : (permitido < DailyValues.penalidadeXp
                  ? permitido
                  : DailyValues.penalidadeXp);
          if (aPerder > 0) perdido = await _profile.removeXp(aPerder);
          if (perdido > 0) {
            aplicadas.add(PenaltyApplied(dia: data, xpPerdido: perdido));
          }
        }
        await (_db.update(_db.dailyDays)..where((d) => d.dia.equals(linha.dia)))
            .write(DailyDaysCompanion(
          processado: const Value(true),
          penalidadeXp: Value(perdido),
          avisado: Value(perdido == 0),
        ));
      }
      return aplicadas;
    });
  }

  @override
  Stream<int> watchPenalidadePendente() => _observar(
        [_db.dailyDays],
        () async {
          final linhas = await (_db.select(_db.dailyDays)
                ..where((d) => d.avisado.equals(false)))
              .get();
          return linhas.fold<int>(0, (s, d) => s + d.penalidadeXp);
        },
      );

  @override
  Future<void> confirmarPenalidades() {
    return (_db.update(_db.dailyDays)..where((d) => d.avisado.equals(false)))
        .write(const DailyDaysCompanion(avisado: Value(true)));
  }

  // ---------------------------------------------------------- programação

  @override
  Stream<Set<int>> watchProgramacao() => _observar(
        [_db.scheduleDays],
        () async => {
          for (final s in await _db.select(_db.scheduleDays).get()) s.weekday,
        },
      );

  @override
  Future<void> alternarDiaDeTreino(int weekday) async {
    final existe = await (_db.select(_db.scheduleDays)
          ..where((s) => s.weekday.equals(weekday)))
        .getSingleOrNull();
    if (existe == null) {
      await _db
          .into(_db.scheduleDays)
          .insert(ScheduleDaysCompanion.insert(weekday: Value(weekday)));
    } else {
      await (_db.delete(_db.scheduleDays)
            ..where((s) => s.weekday.equals(weekday)))
          .go();
    }
  }
}

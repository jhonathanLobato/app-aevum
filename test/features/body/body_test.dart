import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/app/app.dart';
import 'package:gym_system/database/app_database.dart';
import 'package:gym_system/database/database_provider.dart';
import 'package:gym_system/features/body/data/body_repository_impl.dart';
import 'package:gym_system/features/body/domain/body.dart';
import 'package:gym_system/features/body/presentation/body_record_form_screen.dart';
import 'package:gym_system/features/body/presentation/body_screen.dart';
import 'package:gym_system/features/profile/data/profile_repository_impl.dart';
import 'package:gym_system/features/profile/domain/app_theme.dart';
import 'package:gym_system/features/profile/domain/player_class.dart';
import 'package:gym_system/features/profile/domain/titles.dart';
import 'package:gym_system/features/profile/domain/units.dart';
import 'package:gym_system/features/profile/presentation/profile_screen.dart';

AppDatabase _db() => AppDatabase.forTesting(NativeDatabase.memory());

Finder _campo(String key) =>
    find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField));

/// Abre [tela] empilhada sobre uma página inicial (para o `pop` do Salvar).
Future<void> _abrir(WidgetTester tester, AppDatabase db, Widget tela) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
    child: MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => tela)),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

Future<void> _fechar(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  group('unidades', () {
    test('kg <-> lb e cm <-> pol (o banco guarda kg e cm)', () {
      const lb = Units(peso: WeightUnit.lb, comprimento: LengthUnit.pol);
      expect(lb.pesoParaBanco(220.46226218), closeTo(100, 1e-6));
      expect(lb.pesoParaExibir(100), closeTo(220.462, 1e-3));
      expect(lb.comprimentoParaBanco(10), closeTo(25.4, 1e-9));
      expect(lb.comprimentoParaExibir(177.8), closeTo(70, 1e-9));
      expect(lb.formatarPeso(45.359237), '100.0 LB');
      expect(lb.formatarComprimento(25.4), '10.0 POL');
      const si = Units();
      expect(si.pesoParaBanco(80), 80);
      expect(si.formatarPeso(32.5), '32.5 KG');
      expect(si.formatarComprimento(80), '80.0 CM');
    });

    test('medidas convertem só peso e comprimento; gordura fica em %', () {
      const lb = Units(peso: WeightUnit.lb, comprimento: LengthUnit.pol);
      expect(BodyMeasure.gordura.paraExibir(18, lb), 18);
      expect(BodyMeasure.cintura.paraExibir(76.2, lb), closeTo(30, 1e-9));
      expect(BodyMeasure.peso.sufixo(lb), 'LB');
      expect(BodyMeasure.braco.sufixo(lb), 'POL');
      expect(BodyMeasure.gordura.sufixo(lb), '%');
    });
  });

  group('IMC e idade', () {
    test('IMC com a faixa', () {
      expect(calcularImc(80, 180), closeTo(24.69, 0.01));
      expect(calcularImc(null, 180), isNull);
      expect(calcularImc(80, null), isNull);
      expect(faixaImc(17.9), 'Abaixo do peso');
      expect(faixaImc(18.5), 'Normal');
      expect(faixaImc(24.9), 'Normal');
      expect(faixaImc(25), 'Sobrepeso');
      expect(faixaImc(29.9), 'Sobrepeso');
      expect(faixaImc(30), 'Obesidade');
    });

    test('idade considera o aniversário', () {
      final hoje = DateTime(2026, 6, 15);
      expect(idadeEm(DateTime(2000, 6, 15), hoje), 26);
      expect(idadeEm(DateTime(2000, 6, 16), hoje), 25);
      expect(idadeEm(DateTime(2000, 1, 1), hoje), 26);
    });
  });

  group('registros (repositório)', () {
    late AppDatabase db;
    late DriftBodyRepository repo;

    setUp(() {
      db = _db();
      repo = DriftBodyRepository(db);
    });
    tearDown(() => db.close());

    test('registrar exige ao menos um valor', () async {
      expect(await repo.salvar(BodyRecordInput(data: DateTime(2026, 3, 1))),
          isFalse);
      expect(await repo.watchAll().first, isEmpty);

      expect(
          await repo.salvar(
              BodyRecordInput(data: DateTime(2026, 3, 1), cinturaCm: 80)),
          isTrue);
      final r = (await repo.watchAll().first).single;
      expect(r.cinturaCm, 80);
      expect(r.pesoKg, isNull);
    });

    test('editar e excluir', () async {
      await repo.salvar(
          BodyRecordInput(data: DateTime(2026, 3, 1), pesoKg: 80, bracoCm: 35));
      final id = (await repo.watchAll().first).single.id;

      await repo.salvar(
          BodyRecordInput(data: DateTime(2026, 3, 2), pesoKg: 79.5),
          id: id);
      var r = (await repo.get(id))!;
      expect(r.pesoKg, 79.5);
      expect(r.bracoCm, isNull); // sobrescrito
      expect(r.data, DateTime(2026, 3, 2));

      await repo.excluir(id);
      expect(await repo.watchAll().first, isEmpty);
    });

    test('evolução: primeiro, anterior, último e variações', () async {
      for (final (d, p) in [(1, 80.0), (8, 79.0), (15, 77.5)]) {
        await repo
            .salvar(BodyRecordInput(data: DateTime(2026, 3, d), pesoKg: p));
      }
      // Registro sem peso não entra na série de peso.
      await repo
          .salvar(BodyRecordInput(data: DateTime(2026, 3, 20), cinturaCm: 82));
      final todos = await repo.watchAll().first;
      final peso = evolucaoDe(todos, BodyMeasure.peso);
      expect(peso.pontos.length, 3);
      expect(peso.primeiro, 80);
      expect(peso.anterior, 79);
      expect(peso.ultimo, 77.5);
      expect(peso.variacaoDesdePrimeiro, -2.5);
      expect(peso.variacaoDesdeAnterior, -1.5);
      expect(evolucaoDe(todos, BodyMeasure.cintura).variacaoDesdePrimeiro,
          isNull); // um só ponto
    });
  });

  group('tela Novo registro', () {
    testWidgets('em lb: digita em lb, grava em kg; sem valor não salva',
        (tester) async {
      final db = _db();
      addTearDown(db.close);
      await DriftProfileRepository(db).salvarFicha(
        nome: 'Ana',
        avatar: null,
        classe: PlayerClass.guerreiro,
        titulo: tituloPadrao,
        tema: AppTheme.escuro,
        unidades: const Units(peso: WeightUnit.lb, comprimento: LengthUnit.pol),
      );
      await _abrir(tester, db, const BodyRecordFormScreen());

      await tester.ensureVisible(find.byKey(const Key('body_salvar')));
      await tester.tap(find.byKey(const Key('body_salvar')));
      await tester.pumpAndSettle();
      expect(find.text('Informe ao menos um valor.'), findsOneWidget);
      expect(await db.select(db.bodyRecords).get(), isEmpty);

      await tester.enterText(_campo('body_field_peso'), '220.46226218');
      await tester.enterText(_campo('body_field_cintura'), '30');
      await tester.ensureVisible(find.byKey(const Key('body_salvar')));
      await tester.tap(find.byKey(const Key('body_salvar')));
      await tester.pumpAndSettle();

      final r = await db.select(db.bodyRecords).getSingle();
      expect(r.pesoKg, closeTo(100, 1e-6));
      expect(r.cinturaCm, closeTo(76.2, 1e-9));
      await _fechar(tester);
    });

    testWidgets('sair sem salvar descarta', (tester) async {
      final db = _db();
      addTearDown(db.close);
      await _abrir(tester, db, const BodyRecordFormScreen());
      await tester.enterText(_campo('body_field_peso'), '80');
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();
      expect(await db.select(db.bodyRecords).get(), isEmpty);
      await _fechar(tester);
    });

    testWidgets('valor inválido mostra erro e não grava', (tester) async {
      final db = _db();
      addTearDown(db.close);
      await _abrir(tester, db, const BodyRecordFormScreen());
      await tester.enterText(_campo('body_field_gordura'), '120');
      await tester.ensureVisible(find.byKey(const Key('body_salvar')));
      await tester.tap(find.byKey(const Key('body_salvar')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('body_erro')), findsOneWidget);
      expect(await db.select(db.bodyRecords).get(), isEmpty);
      await _fechar(tester);
    });
  });

  testWidgets('tela Corpo: resumo, IMC, evolução e exclusão', (tester) async {
    final db = _db();
    addTearDown(db.close);
    final perfil = DriftProfileRepository(db);
    await perfil.salvarFicha(
      nome: 'Ana',
      avatar: null,
      classe: PlayerClass.guerreiro,
      titulo: tituloPadrao,
      tema: AppTheme.escuro,
      unidades: const Units(),
      alturaCm: 180,
    );
    final repo = DriftBodyRepository(db);
    await repo.salvar(BodyRecordInput(data: DateTime(2026, 3, 1), pesoKg: 82));
    await repo.salvar(BodyRecordInput(data: DateTime(2026, 4, 1), pesoKg: 80));

    await _abrir(tester, db, const BodyScreen());

    expect(find.text('80.0 KG'), findsWidgets);
    expect(find.text('-2.0 KG'), findsOneWidget); // desde o primeiro
    expect(find.text('24.7'), findsOneWidget); // 80 / 1,8²
    expect(find.text('IMC Normal'), findsOneWidget);
    expect(find.byKey(const Key('body_grafico')), findsOneWidget);

    // Excluir pede confirmação.
    final id = (await db.select(db.bodyRecords).get()).last.id;
    await tester.ensureVisible(find.byKey(Key('body_excluir_$id')));
    await tester.tap(find.byKey(Key('body_excluir_$id')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('EXCLUIR'));
    await tester.pumpAndSettle();
    expect((await db.select(db.bodyRecords).get()).length, 1);
    await _fechar(tester);
  });

  group('títulos', () {
    test('desbloqueio por conquista e por rank', () {
      TitleDef t(String nome) =>
          kTitleCatalog.firstWhere((x) => x.nome == nome);
      expect(t('Despertado').desbloqueado(conquistas: {}, rank: 'F'), isTrue);
      expect(t('Iniciante').desbloqueado(conquistas: {}, rank: 'F'), isFalse);
      expect(
          t('Iniciante')
              .desbloqueado(conquistas: {'primeiros_passos'}, rank: 'F'),
          isTrue);
      expect(
          t('Caçador Rank E').desbloqueado(conquistas: {}, rank: 'F'), isFalse);
      expect(
          t('Caçador Rank E').desbloqueado(conquistas: {}, rank: 'D'), isTrue);
      expect(
          t('Caçador Rank S').desbloqueado(conquistas: {}, rank: 'A'), isFalse);
      expect(kTitleCatalog.length, 15);
    });
  });

  group('Ficha do Caçador', () {
    testWidgets('salva identidade, corpo e preferências; título bloqueado',
        (tester) async {
      final db = _db();
      addTearDown(db.close);
      await tester.pumpWidget(ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: ProfileScreen()),
      ));
      await tester.pumpAndSettle();
      expect(find.text('FICHA DO CAÇADOR'), findsOneWidget);

      await tester.enterText(_campo('profile_nome_field'), 'Ana');
      await tester.enterText(_campo('profile_altura_field'), '180');

      // Título: "Iniciante" está bloqueado (cadeado + condição).
      await tester
          .ensureVisible(find.byKey(const Key('profile_titulo_button')));
      await tester.tap(find.byKey(const Key('profile_titulo_button')));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.lock_outline), findsWidgets);
      expect(find.text('Conquista Primeiros Passos'), findsOneWidget);
      await tester.tap(find.byKey(const Key('titulo_Iniciante')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('titulo_Iniciante')), findsOneWidget,
          reason: 'bloqueado não fecha o diálogo');
      await tester.tap(find.byKey(const Key('titulo_Despertado')));
      await tester.pumpAndSettle();

      // Preferências: tema claro, lb e pol (a altura é convertida).
      expect(find.byKey(const Key('profile_tema_claro')), findsNothing,
          reason: 'Preferências começa recolhida');
      await tester
          .ensureVisible(find.byKey(const Key('profile_toggle_preferencias')));
      await tester.tap(find.byKey(const Key('profile_toggle_preferencias')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('profile_tema_claro')));
      await tester.tap(find.byKey(const Key('profile_tema_claro')));
      await tester.tap(find.byKey(const Key('profile_peso_lb')));
      await tester
          .ensureVisible(find.byKey(const Key('profile_comprimento_pol')));
      await tester.tap(find.byKey(const Key('profile_comprimento_pol')));
      await tester.pumpAndSettle();
      final altura = tester
          .widget<TextField>(_campo('profile_altura_field'))
          .controller!
          .text;
      expect(altura, '70.9'); // 180 cm

      // Nada foi gravado antes de salvar.
      expect(await db.select(db.users).get(), isEmpty);

      await tester.ensureVisible(find.byKey(const Key('profile_salvar')));
      await tester.tap(find.byKey(const Key('profile_salvar')));
      await tester.pumpAndSettle();

      final u = await db.select(db.users).getSingle();
      expect(u.nome, 'Ana');
      expect(u.titulo, 'Despertado');
      expect(u.tema, AppTheme.claro);
      expect(u.unidadePeso, WeightUnit.lb);
      expect(u.unidadeComprimento, LengthUnit.pol);
      expect(u.alturaCm, closeTo(180.1, 0.1)); // 70.9 pol
      await _fechar(tester);
    });

    testWidgets('data do despertar usa o registro mais antigo', (tester) async {
      final db = _db();
      addTearDown(db.close);
      final perfil =
          DriftProfileRepository(db, agora: () => DateTime(2026, 5, 10));
      await perfil.updateProfile(nome: 'Ana', classe: PlayerClass.guerreiro);
      await DriftBodyRepository(db)
          .salvar(BodyRecordInput(data: DateTime(2026, 5, 1), pesoKg: 80));

      expect(await perfil.watchDespertar().first, DateTime(2026, 5, 1));
      await _fechar(tester);
    });
  });

  testWidgets('tema claro aplica o filtro e inverte a luminosidade',
      (tester) async {
    final db = _db();
    addTearDown(db.close);
    await DriftProfileRepository(db).salvarFicha(
      nome: 'Ana',
      avatar: null,
      classe: PlayerClass.guerreiro,
      titulo: tituloPadrao,
      tema: AppTheme.claro,
      unidades: const Units(),
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const App(),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('tema_claro')), findsOneWidget);

    // Matriz: branco -> preto, preto -> branco, matiz preservado.
    double aplicar(List<double> m, int linha, List<double> rgb) =>
        m[linha * 5] * rgb[0] +
        m[linha * 5 + 1] * rgb[1] +
        m[linha * 5 + 2] * rgb[2] +
        m[linha * 5 + 4];
    const m = filtroTemaClaroMatriz;
    for (var i = 0; i < 3; i++) {
      expect(aplicar(m, i, [255, 255, 255]), closeTo(0, 1e-6));
      expect(aplicar(m, i, [0, 0, 0]), closeTo(255, 1e-6));
    }
    await _fechar(tester);
  });
}

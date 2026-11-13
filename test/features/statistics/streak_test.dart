import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/features/statistics/domain/streak.dart';

/// Horário de Brasília (UTC-3, sem horário de verão desde 2019).
Duration _brasilia(DateTime utc) => const Duration(hours: -3);

void main() {
  test('sem treinos a sequência é 0', () {
    expect(maiorSequenciaDeDias([], deslocamento: _brasilia), 0);
  });

  test('conta dias consecutivos e ignora furos', () {
    final datas = [
      DateTime.utc(2026, 3, 1, 15),
      DateTime.utc(2026, 3, 2, 15),
      DateTime.utc(2026, 3, 3, 15),
      DateTime.utc(2026, 3, 5, 15), // furo no dia 4
    ];
    expect(maiorSequenciaDeDias(datas, deslocamento: _brasilia), 3);
  });

  test('vários treinos no mesmo dia contam como um dia', () {
    final datas = [
      DateTime.utc(2026, 3, 1, 12),
      DateTime.utc(2026, 3, 1, 18),
      DateTime.utc(2026, 3, 2, 12),
    ];
    expect(maiorSequenciaDeDias(datas, deslocamento: _brasilia), 2);
  });

  test('treino às 22h em Brasília conta no dia local, não no dia UTC', () {
    // 22h de 10/03 em Brasília = 01h de 11/03 em UTC.
    final dia10as22h = DateTime.utc(2026, 3, 11, 1);
    // 10h de 11/03 em Brasília = 13h de 11/03 em UTC (mesmo dia UTC!).
    final dia11as10h = DateTime.utc(2026, 3, 11, 13);
    // 23h30 de 12/03 em Brasília = 02h30 de 13/03 em UTC.
    final dia12as2330 = DateTime.utc(2026, 3, 13, 2, 30);

    // No dia local são três dias seguidos (10, 11 e 12). Agrupando em UTC
    // seria 1 (os dois primeiros no dia 11) e depois o dia 13.
    expect(
      maiorSequenciaDeDias([dia10as22h, dia11as10h, dia12as2330],
          deslocamento: _brasilia),
      3,
    );
    expect(
      maiorSequenciaDeDias([dia10as22h, dia11as10h, dia12as2330],
          deslocamento: (_) => Duration.zero),
      1,
    );
  });

  test('o fuso do aparelho é usado por padrão', () {
    final local = [DateTime(2026, 1, 1, 23, 30), DateTime(2026, 1, 2, 0, 15)];
    expect(maiorSequenciaDeDias(local), 2);
  });
}

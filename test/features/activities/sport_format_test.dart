import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/features/activities/presentation/sport_activity_format.dart';

void main() {
  test('duração: minutos abaixo de 1h, horas a partir de 60 min', () {
    expect(formatarDuracao(45), '45 MIN');
    expect(formatarDuracao(60), '1H');
    expect(formatarDuracao(90), '1H 30MIN');
    expect(formatarDuracao(135), '2H 15MIN');
  });
}

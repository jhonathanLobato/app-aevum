import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system/app/app.dart';

void main() {
  testWidgets('abre a tela Sistema', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    expect(find.text('SISTEMA ONLINE'), findsOneWidget);
  });
}

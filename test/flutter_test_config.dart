import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// Configuração global de todos os testes (Fase 9).
///
/// Desde a Fase 9 o app tem uma animação verdadeiramente contínua (o pulso
/// do indicador "ONLINE", `SystemOnlineIndicator`) que nunca "se estabiliza"
/// sozinha — um `AnimationController.repeat()` sempre agenda mais um frame.
/// Isso é incompatível com `tester.pumpAndSettle()`, usado por praticamente
/// todo o resto da suíte (centenas de chamadas já existentes antes desta
/// fase), que trava esperando animações pararem.
///
/// Em vez de reescrever todos os testes existentes para parar de usar
/// `pumpAndSettle()`, ligamos "Reduced Motion" (`disableAnimations`) por
/// padrão pra suíte inteira — mesma flag de acessibilidade que o app já
/// respeita em todo widget animado da Fase 9 (ver [MediaQueryData.disableAnimations]).
/// Isso também deixa os testes mais rápidos e determinísticos (seção 24:
/// "teste comportamento e estado final", não cada frame visual).
///
/// Um teste que precise verificar o comportamento SEM Reduced Motion (ex.:
/// "o pulso do ONLINE realmente anima quando animações estão habilitadas")
/// pode ligar de volta localmente com
/// `tester.view.platformDispatcher.accessibilityFeaturesTestValue =
/// const FakeAccessibilityFeatures(disableAnimations: false)` e limpar depois
/// com `clearAccessibilityFeaturesTestValue()`.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized()
          .platformDispatcher
          .accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  await testMain();
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/profile/domain/app_theme.dart';
import '../features/profile/presentation/profile_providers.dart';
import 'router.dart';
import 'theme.dart';

/// Inverte a luminosidade preservando o matiz (equivale ao CSS
/// `invert(1) hue-rotate(180deg)`): o app inteiro é desenhado com a paleta
/// escura do Sistema (constantes), então o tema claro é essa mesma interface
/// com a luminosidade invertida — fundos claros, textos escuros, ciano e
/// dourado mantidos como destaque.
const filtroTemaClaroMatriz = <double>[
  0.574, -1.430, -0.144, 0, 255, //
  -0.426, -0.430, -0.144, 0, 255, //
  -0.426, -1.430, 0.856, 0, 255, //
  0, 0, 0, 1, 0, //
];

const filtroTemaClaro = ColorFilter.matrix(filtroTemaClaroMatriz);

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = ref.watch(currentUserProvider).valueOrNull?.tema;
    final claro = tema == AppTheme.claro;

    return MaterialApp.router(
      title: 'Aevum',
      debugShowCheckedModeBanner: false,
      // Sempre o tema escuro de base; o claro aplica o filtro por cima.
      theme: buildSystemTheme(escuro: true),
      routerConfig: appRouter,
      builder: (context, child) => claro
          ? ColorFiltered(
              key: const Key('tema_claro'),
              colorFilter: filtroTemaClaro,
              child: child,
            )
          : child ?? const SizedBox.shrink(),
    );
  }
}

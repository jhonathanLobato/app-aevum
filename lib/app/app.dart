import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/profile/domain/app_theme.dart';
import '../features/profile/presentation/profile_providers.dart';
import 'router.dart';
import 'theme.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = ref.watch(currentUserProvider).valueOrNull?.tema;

    return MaterialApp.router(
      title: 'Sistema',
      debugShowCheckedModeBanner: false,
      theme: buildSystemTheme(escuro: tema != AppTheme.claro),
      routerConfig: appRouter,
    );
  }
}

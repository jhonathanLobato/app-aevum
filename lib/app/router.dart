import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/achievements/presentation/achievements_screen.dart';
import '../features/activities/domain/sport_activity.dart';
import '../features/activities/presentation/activities_screen.dart';
import '../features/activities/presentation/sport_activity_detail_screen.dart';
import '../features/activities/presentation/sport_activity_form_screen.dart';
import '../features/activities/presentation/sport_history_screen.dart';
import '../features/activities/presentation/sport_type_screen.dart';
import '../features/exercises/presentation/exercise_history_screen.dart';
import '../features/exercises/presentation/exercises_screen.dart';
import '../features/missions/presentation/missions_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/statistics/presentation/statistics_screen.dart';
import '../features/system_home/presentation/system_screen.dart';
import '../features/workouts/presentation/active_workout_screen.dart';
import '../features/workouts/presentation/workout_form_screen.dart';
import '../features/workouts/presentation/workout_history_screen.dart';
import '../features/workouts/presentation/workout_template_detail_screen.dart';
import '../features/workouts/presentation/workouts_screen.dart';
import 'scaffold_with_nav_bar.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Rotas de Atividades com modalidade inválida na URL voltam pra aba.
String? _redirecionarSeModalidadeInvalida(
    BuildContext context, GoRouterState state) {
  return SportType.fromName(state.pathParameters['type']) == null
      ? '/activities'
      : null;
}

SportType _tipoDaRota(GoRouterState state) =>
    SportType.fromName(state.pathParameters['type'])!;

/// As 6 áreas principais (Sistema/Treinos/Atividades/Missões/Status/
/// Conquistas) vivem dentro do [StatefulShellRoute], cada uma em seu próprio
/// branch — isso preserva a pilha de navegação e o estado de cada aba ao
/// alternar entre elas (ex.: scroll, formulários abertos), sem precisar de
/// nenhum estado próprio: o índice da aba atual é inteiramente
/// responsabilidade do go_router (`navigationShell.currentIndex`).
///
/// Toda tela que não é uma das 6 abas (detalhe de exercício, histórico,
/// perfil, detalhe de treino, sessão ativa) continua como rota de nível
/// raiz — com `parentNavigatorKey: rootNavigatorKey` para empilhar por cima
/// do shell inteiro (escondendo a navigation bar) em vez de tentar se
/// encaixar dentro do navigator de um branch específico. É o padrão
/// recomendado pelo próprio go_router para `StatefulShellRoute`, e resolve
/// de graça o pedido de que o treino ativo não tenha a barra atrapalhando.
final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
                path: '/', builder: (context, state) => const SystemScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
                path: '/workouts',
                builder: (context, state) => const WorkoutsScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
                path: '/activities',
                builder: (context, state) => const ActivitiesScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
                path: '/missions',
                builder: (context, state) => const MissionsScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
                path: '/statistics',
                builder: (context, state) => const StatisticsScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
                path: '/achievements',
                builder: (context, state) => const AchievementsScreen()),
          ],
        ),
      ],
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/activities/:type',
      redirect: _redirecionarSeModalidadeInvalida,
      builder: (context, state) => SportTypeScreen(tipo: _tipoDaRota(state)),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/activities/:type/new',
      redirect: _redirecionarSeModalidadeInvalida,
      builder: (context, state) =>
          SportActivityFormScreen(tipo: _tipoDaRota(state)),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/activities/:type/history',
      redirect: _redirecionarSeModalidadeInvalida,
      builder: (context, state) => SportHistoryScreen(tipo: _tipoDaRota(state)),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/activities/:type/:id',
      redirect: _redirecionarSeModalidadeInvalida,
      builder: (context, state) => SportActivityDetailScreen(
        tipo: _tipoDaRota(state),
        activityId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/activities/:type/:id/edit',
      redirect: _redirecionarSeModalidadeInvalida,
      builder: (context, state) => SportActivityFormScreen(
        tipo: _tipoDaRota(state),
        activityId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/exercises',
      builder: (context, state) => const ExercisesScreen(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/exercises/:id/history',
      builder: (context, state) => ExerciseHistoryScreen(
        exerciseId: int.parse(state.pathParameters['id']!),
        exerciseNome: state.extra as String? ?? 'Exercício',
      ),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/workouts/new',
      builder: (context, state) => const WorkoutFormScreen(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/workouts/:id',
      builder: (context, state) => WorkoutTemplateDetailScreen(
        templateId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/workouts/:id/edit',
      builder: (context, state) => WorkoutFormScreen(
        templateId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/sessions/:id',
      builder: (context, state) => ActiveWorkoutScreen(
        sessionId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/history',
      builder: (context, state) => const WorkoutHistoryScreen(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);

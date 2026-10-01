import 'package:go_router/go_router.dart';

import '../features/achievements/presentation/achievements_screen.dart';
import '../features/exercises/presentation/exercise_history_screen.dart';
import '../features/exercises/presentation/exercises_screen.dart';
import '../features/missions/presentation/missions_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/statistics/presentation/statistics_screen.dart';
import '../features/system_home/presentation/system_screen.dart';
import '../features/workouts/presentation/active_workout_screen.dart';
import '../features/workouts/presentation/workout_history_screen.dart';
import '../features/workouts/presentation/workout_template_detail_screen.dart';
import '../features/workouts/presentation/workouts_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SystemScreen(),
    ),
    GoRoute(
      path: '/exercises',
      builder: (context, state) => const ExercisesScreen(),
    ),
    GoRoute(
      path: '/exercises/:id/history',
      builder: (context, state) => ExerciseHistoryScreen(
        exerciseId: int.parse(state.pathParameters['id']!),
        exerciseNome: state.extra as String? ?? 'Exercício',
      ),
    ),
    GoRoute(
      path: '/workouts',
      builder: (context, state) => const WorkoutsScreen(),
    ),
    GoRoute(
      path: '/workouts/:id',
      builder: (context, state) => WorkoutTemplateDetailScreen(
        templateId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/sessions/:id',
      builder: (context, state) => ActiveWorkoutScreen(
        sessionId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const WorkoutHistoryScreen(),
    ),
    GoRoute(
      path: '/missions',
      builder: (context, state) => const MissionsScreen(),
    ),
    GoRoute(
      path: '/achievements',
      builder: (context, state) => const AchievementsScreen(),
    ),
    GoRoute(
      path: '/statistics',
      builder: (context, state) => const StatisticsScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);

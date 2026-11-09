import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_routes.dart';
import '../core/widgets/app_shell.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/chatbot/presentation/screens/chatbot_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/favorites/presentation/screens/favorites_screen.dart';
import '../features/matches/presentation/screens/match_details_screen.dart';
import '../features/matches/presentation/screens/matches_screen.dart';
import '../features/players/presentation/screens/player_analysis_screen.dart';
import '../features/players/presentation/screens/player_comparison_screen.dart';
import '../features/players/presentation/screens/players_screen.dart';
import '../features/predictions/presentation/screens/predictions_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/stats/presentation/screens/stats_screen.dart';
import '../features/tactics/presentation/screens/tactics_screen.dart';
import '../features/teams/presentation/screens/team_details_screen.dart';
import '../features/teams/presentation/screens/teams_screen.dart';

CustomTransitionPage<void> _fadePage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const OnboardingScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const RegisterScreen()),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: AppRoutes.matchDetails,
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: MatchDetailsScreen(
            matchId: state.pathParameters['matchId'] ?? 'm-live-1',
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.teams,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const TeamsScreen()),
      ),
      GoRoute(
        path: AppRoutes.teamDetails,
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: TeamDetailsScreen(
            teamId: state.pathParameters['teamId'] ?? '',
            leagueId: state.uri.queryParameters['league'],
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.players,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const PlayersScreen()),
      ),
      GoRoute(
        path: AppRoutes.playerDetails,
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: PlayerAnalysisScreen(
            playerId: state.pathParameters['playerId'] ?? 'saka',
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.playerCompare,
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: PlayerComparisonScreen(
            leftId: state.uri.queryParameters['left'],
            rightId: state.uri.queryParameters['right'],
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.predictions,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const PredictionsScreen()),
      ),
      GoRoute(
        path: AppRoutes.tactics,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const TacticsScreen()),
      ),
      GoRoute(
        path: AppRoutes.favorites,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const FavoritesScreen()),
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const SettingsScreen()),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const NotificationsScreen()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.matches,
                builder: (context, state) => const MatchesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.chatbot,
                builder: (context, state) => const ChatbotScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.stats,
                builder: (context, state) => const StatsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

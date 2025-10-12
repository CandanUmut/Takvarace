import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/dashboard/dashboard_screen.dart';
import '../../features/diary/diary_screen.dart';
import '../../features/leaderboard/leaderboard_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shields/shields_screen.dart';
import '../providers.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  final profileAsync = ref.watch(profileControllerProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/diary',
        builder: (context, state) => const DiaryScreen(),
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: '/shields',
        builder: (context, state) => const ShieldsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    redirect: (context, state) {
      final profile = profileAsync.valueOrNull;
      final loading = profileAsync.isLoading;
      final loggingIn = state.uri.path == '/onboarding';
      if (loading) return null;
      if (profile == null && !loggingIn) {
        return '/onboarding';
      }
      if (profile != null && loggingIn) {
        return '/dashboard';
      }
      return null;
    },
  );
});

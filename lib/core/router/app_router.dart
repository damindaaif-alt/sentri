import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/call_log/presentation/pages/call_log_page.dart';
import '../../features/caller_id/presentation/pages/caller_detail_page.dart';
import '../../features/blocklist/presentation/pages/blocklist_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../constants/app_constants.dart';
import 'home_shell.dart';

abstract class AppRouter {
  static final router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        redirect: (context, state) => AppRoutes.home,
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const CallLogPage(),
          ),
          GoRoute(
            path: AppRoutes.callLog,
            builder: (context, state) => const CallLogPage(),
          ),
          GoRoute(
            path: AppRoutes.blocklist,
            builder: (context, state) => const BlocklistPage(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.callerDetail,
        builder: (context, state) => CallerDetailPage(
          phoneNumber: state.pathParameters['number'] ?? '',
        ),
      ),
    ],
  );
}

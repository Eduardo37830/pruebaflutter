import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/application/auth_notifier.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/chapters/presentation/chapter_list_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/editor/presentation/editor_screen.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/onboarding',
    redirect: (context, state) {
      if (authState.isLoading) {
        return null;
      }

      final isLoggedIn = authState.valueOrNull ?? false;
      final location = state.matchedLocation;
      final isAuthRoute = location == '/auth' || location == '/onboarding' || location == '/register';

      if (!isLoggedIn && !isAuthRoute) {
        return '/onboarding';
      }

      if (isLoggedIn && isAuthRoute) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/chapters/:projectLocalId/:projectTitle',
        builder: (context, state) {
          final projectLocalId = state.pathParameters['projectLocalId']!;
          final encodedTitle = state.pathParameters['projectTitle'] ?? '';
          final projectTitle = Uri.decodeComponent(encodedTitle);

          return ChapterListScreen(
            projectLocalId: projectLocalId,
            projectTitle: projectTitle,
          );
        },
      ),
      GoRoute(
        path: '/editor/:projectLocalId/:chapterLocalId',
        builder: (context, state) {
          final projectLocalId = state.pathParameters['projectLocalId']!;
          final chapterLocalId = state.pathParameters['chapterLocalId']!;

          return EditorScreen(
            projectLocalId: projectLocalId,
            chapterLocalId: chapterLocalId,
          );
        },
      ),
    ],
  );
}

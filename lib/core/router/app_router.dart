import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_notifier.dart';
import '../../screens/login_screen.dart';
import '../../screens/main_shell.dart';
import '../../screens/onboarding_screen.dart';
import '../../screens/otp_screen.dart';
import '../../screens/register_screen.dart';
import '../../screens/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthRouterNotifier(ref);
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final path = state.matchedLocation;

      // Always let splash render itself
      if (path == '/splash') return null;

      final authState = ref.read(authProvider);

      // Pendant le chargement initial, rester sur splash.
      // Ne pas rediriger si l'utilisateur est déjà sur une route auth (ex: login en cours).
      if (authState.isLoading && !path.startsWith('/auth') && path != '/onboarding') {
        return '/splash';
      }

      final loggedIn = authState.valueOrNull != null;
      final onAuthRoute = path.startsWith('/auth');
      final onOnboarding = path == '/onboarding';

      if (!loggedIn && !onAuthRoute && !onOnboarding) return '/auth/login';
      if (loggedIn && onAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth',
        redirect: (_, __) => '/auth/login',
        routes: [
          GoRoute(
            path: 'login',
            builder: (_, __) => const LoginScreen(),
          ),
          GoRoute(
            path: 'register',
            builder: (_, __) => const RegisterScreen(),
          ),
          GoRoute(
            path: 'otp',
            builder: (_, state) {
              final phone = state.uri.queryParameters['phone'] ?? '';
              final verificationId =
                  state.uri.queryParameters['verificationId'] ?? '';
              return OtpScreen(
                phone: phone,
                verificationId: verificationId,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const MainShell(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page introuvable: ${state.error}'),
      ),
    ),
  );
});

class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}

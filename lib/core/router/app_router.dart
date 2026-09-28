import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_state.dart';
import '../../features/admin/presentation/admin_shell_screen.dart';
import '../../features/auth/auth_callback_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/onboarding_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/setup_wizard/presentation/setup_wizard_screen.dart';
import '../../features/splash/splash_screen.dart';

/// Notifies [GoRouter.refreshListenable] on every auth state change, so the
/// router just re-runs [redirect] on the current location instead of being
/// torn down and rebuilt (rebuilding mid-navigation — e.g. while a fresh
/// deep link like `#/dashboard` is still being redirected on first load —
/// left the Navigator with nothing resolved to render: a blank white page).
class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = _AuthRefreshListenable(ref);
  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final path = state.matchedLocation;

      if (authState.status == AuthStatus.unknown) {
        return path == '/splash' ? null : '/splash';
      }

      if (!authState.isAuthenticated) {
        const publicPaths = {'/login', '/register', '/auth/callback'};
        return publicPaths.contains(path) ? null : '/login';
      }

      // A Super Admin is company-less by design (a platform account, not a
      // shop owner) — checked before needsOnboarding, which would
      // otherwise misread that as "signed up, not onboarded yet" and send
      // them to the shop-onboarding form instead of the admin panel.
      if (authState.user!.isSuperAdmin) {
        return path.startsWith('/admin') ? null : '/admin';
      }

      // Signed up via Google but hasn't entered their shop's details yet —
      // nothing else in the app is usable without a company.
      if (authState.user!.needsOnboarding) {
        return path == '/onboarding' ? null : '/onboarding';
      }

      // Unlike needsOnboarding, this is dismissible — the wizard screen
      // itself can mark it complete without finishing every step, so
      // nobody is ever hard-blocked here.
      if (authState.user!.needsSetupWizard) {
        return path == '/setup-wizard' ? null : '/setup-wizard';
      }

      const preAuthPaths = {
        '/login', '/register', '/splash', '/onboarding', '/auth/callback', '/setup-wizard',
      };
      if (preAuthPaths.contains(path) || path.startsWith('/admin')) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(
        path: '/auth/callback',
        builder: (context, state) => AuthCallbackScreen(token: state.uri.queryParameters['token']),
      ),
      GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
      GoRoute(path: '/setup-wizard', builder: (context, state) => const SetupWizardScreen()),
      GoRoute(path: '/admin', builder: (context, state) => const AdminShellScreen()),
    ],
  );
});

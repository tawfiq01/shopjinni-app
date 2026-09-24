import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_state.dart';

/// Lands here after the browser is redirected back from Google. Consumes
/// the token in the URL and hands off to AuthController — the router
/// takes it from there (onboarding vs. dashboard) once the resulting auth
/// state updates.
class AuthCallbackScreen extends ConsumerStatefulWidget {
  const AuthCallbackScreen({super.key, required this.token});

  final String? token;

  @override
  ConsumerState<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends ConsumerState<AuthCallbackScreen> {
  @override
  void initState() {
    super.initState();
    final token = widget.token;
    if (token == null || token.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/login'));
      return;
    }
    Future.microtask(() => ref.read(authControllerProvider.notifier).loginWithToken(token));
  }

  @override
  Widget build(BuildContext context) {
    final error = ref.watch(authControllerProvider).error;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (error != null) ...[
              Text(error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => context.go('/login'), child: const Text('Back to login')),
            ] else
              const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

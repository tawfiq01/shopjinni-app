import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_user.dart';
import 'auth_repository.dart';
import 'token_storage.dart';

enum AuthStatus { unknown, authenticating, authenticated, unauthenticated }

class AuthState {
  const AuthState._({required this.status, this.user, this.token, this.error});

  const AuthState.unknown() : this._(status: AuthStatus.unknown);

  const AuthState.authenticating() : this._(status: AuthStatus.authenticating);

  const AuthState.authenticated({required String token, required AppUser user})
      : this._(status: AuthStatus.authenticated, token: token, user: user);

  const AuthState.unauthenticated({String? error})
      : this._(status: AuthStatus.unauthenticated, error: error);

  final AuthStatus status;
  final AppUser? user;
  final String? token;
  final String? error;

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

class AuthController extends Notifier<AuthState> {
  final AuthRepository _repository = AuthRepository();
  final TokenStorage _tokenStorage = TokenStorage();

  @override
  AuthState build() {
    Future.microtask(_restoreSession);
    return const AuthState.unknown();
  }

  Future<void> _restoreSession() async {
    final token = await _tokenStorage.read();
    if (token == null) {
      state = const AuthState.unauthenticated();
      return;
    }
    try {
      final user = await _repository.me(token);
      state = AuthState.authenticated(token: token, user: user);
    } catch (_) {
      await _tokenStorage.clear();
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    state = const AuthState.authenticating();
    try {
      final result = await _repository.login(email: email, password: password);
      await _tokenStorage.save(result.token);
      state = AuthState.authenticated(token: result.token, user: result.user);
    } on AuthException catch (e) {
      state = AuthState.unauthenticated(error: e.message);
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String companyName,
    String? companyAddress,
    String? companyPhone,
  }) async {
    state = const AuthState.authenticating();
    try {
      final result = await _repository.register(
        name: name,
        email: email,
        password: password,
        companyName: companyName,
        companyAddress: companyAddress,
        companyPhone: companyPhone,
      );
      await _tokenStorage.save(result.token);
      state = AuthState.authenticated(token: result.token, user: result.user);
    } on AuthException catch (e) {
      state = AuthState.unauthenticated(error: e.message);
    }
  }

  /// Consumes the token handed back in the URL after the Google sign-in
  /// redirect completes — the user may or may not have a company yet
  /// (needsOnboarding on the returned user distinguishes the two), so this
  /// just authenticates; the router decides where to send them next.
  Future<void> loginWithToken(String token) async {
    state = const AuthState.authenticating();
    try {
      final user = await _repository.me(token);
      await _tokenStorage.save(token);
      state = AuthState.authenticated(token: token, user: user);
    } on AuthException catch (e) {
      state = AuthState.unauthenticated(error: e.message);
    }
  }

  Future<void> completeOnboarding({
    required String companyName,
    String? companyAddress,
    String? companyPhone,
  }) async {
    final token = state.token;
    if (token == null) {
      throw AuthException('You must be logged in to finish setting up your shop.');
    }
    final user = await _repository.completeOnboarding(
      token: token,
      companyName: companyName,
      companyAddress: companyAddress,
      companyPhone: companyPhone,
    );
    state = AuthState.authenticated(token: token, user: user);
  }

  /// Re-fetches the current user so cached AppUser fields (e.g.
  /// setupWizardCompleted, changed via a company-level action the auth
  /// state doesn't otherwise know about) catch up with the backend —
  /// same pattern completeOnboarding() already uses, just without a
  /// company-provisioning call attached.
  Future<void> refreshUser() async {
    final token = state.token;
    if (token == null) return;
    final user = await _repository.me(token);
    state = AuthState.authenticated(token: token, user: user);
  }

  Future<void> updateProfile({required String name, required String email, String? phone}) async {
    final token = state.token;
    if (token == null) {
      throw AuthException('You must be logged in to update your profile.');
    }
    final user = await _repository.updateProfile(token: token, name: name, email: email, phone: phone);
    state = AuthState.authenticated(token: token, user: user);
  }

  Future<void> uploadAvatar({required List<int> bytes, required String filename}) async {
    final token = state.token;
    if (token == null) {
      throw AuthException('You must be logged in to update your profile photo.');
    }
    final user = await _repository.uploadAvatar(token: token, bytes: bytes, filename: filename);
    state = AuthState.authenticated(token: token, user: user);
  }

  Future<void> deleteAvatar() async {
    final token = state.token;
    if (token == null) {
      throw AuthException('You must be logged in to update your profile photo.');
    }
    final user = await _repository.deleteAvatar(token: token);
    state = AuthState.authenticated(token: token, user: user);
  }

  Future<String> googleAuthUrl() => _repository.googleAuthUrl();

  Future<void> logout() async {
    final token = state.token;
    if (token != null) {
      await _repository.logout(token);
    }
    await _tokenStorage.clear();
    state = const AuthState.unauthenticated();
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) {
    final token = state.token;
    if (token == null) {
      throw AuthException('You must be logged in to change your password.');
    }
    return _repository.changePassword(
      token: token,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);

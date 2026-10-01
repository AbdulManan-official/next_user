import 'session_service.dart';

/// Global authentication service for session and login state.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final SessionService _session = SessionService.instance;

  bool get isLoggedIn => _session.isAuthenticated;

  Future<bool> login({
    required String emailOrPhone,
    required String password,
  }) async {
    // Simulated API call or authentication logic
    await Future.delayed(const Duration(milliseconds: 600));
    _session.saveSession(
      token: 'sample_token_jwt',
      userId: 'usr_001',
      role: 'user',
      data: {'email': emailOrPhone, 'name': 'Valued Client'},
    );
    return true;
  }

  Future<bool> verifyOtp({
    required String code,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return code.length == 4 || code.length == 6;
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _session.clearSession();
  }
}

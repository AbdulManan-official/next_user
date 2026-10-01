/// Simple memory/session cache service.
class SessionService {
  SessionService._();
  static final SessionService instance = SessionService._();

  String? _token;
  String? _userId;
  String? _userRole;
  Map<String, dynamic>? _userData;

  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  String? get token => _token;
  String? get userId => _userId;
  String? get userRole => _userRole;
  Map<String, dynamic>? get userData => _userData;

  void saveSession({
    required String token,
    required String userId,
    String? role,
    Map<String, dynamic>? data,
  }) {
    _token = token;
    _userId = userId;
    _userRole = role;
    _userData = data;
  }

  void clearSession() {
    _token = null;
    _userId = null;
    _userRole = null;
    _userData = null;
  }
}

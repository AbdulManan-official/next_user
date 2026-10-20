import 'package:firebase_auth/firebase_auth.dart';

/// App session management service linked with Firebase Authentication and Laravel Backend.
class SessionService {
  SessionService._();
  static final SessionService instance = SessionService._();

  String? _token; // Firebase token or Laravel Sanctum Bearer token
  String? _backendToken;
  String? _userId; // Firebase UID
  int? _backendUserId; // Laravel users table ID
  String? _userRole;
  bool _isProfileComplete = false;
  Map<String, dynamic>? _userData;

  bool get isAuthenticated =>
      FirebaseAuth.instance.currentUser != null ||
      (_backendToken != null && _backendToken!.isNotEmpty) ||
      (_token != null && _token!.isNotEmpty);

  User? get currentFirebaseUser => FirebaseAuth.instance.currentUser;

  /// Returns active auth token for API requests (prefers Laravel Sanctum Bearer token)
  String? get token => _backendToken ?? _token;
  String? get backendToken => _backendToken;
  String? get userId => _userId ?? FirebaseAuth.instance.currentUser?.uid;
  int? get backendUserId => _backendUserId;
  String get userRole => _userRole ?? 'client';
  bool get isProfileComplete => _isProfileComplete;
  Map<String, dynamic>? get userData => _userData;

  String get clientName =>
      _userData?['name']?.toString() ??
      FirebaseAuth.instance.currentUser?.displayName ??
      '';

  String get clientEmail =>
      _userData?['email']?.toString() ??
      FirebaseAuth.instance.currentUser?.email ??
      '';

  String get clientPhone =>
      _userData?['phone']?.toString() ??
      FirebaseAuth.instance.currentUser?.phoneNumber ??
      '';

  void saveSession({
    required String token,
    required String userId,
    String? backendToken,
    int? backendUserId,
    String? role,
    bool? isProfileComplete,
    Map<String, dynamic>? data,
  }) {
    _token = token;
    _userId = userId;
    if (backendToken != null) _backendToken = backendToken;
    if (backendUserId != null) _backendUserId = backendUserId;
    _userRole = role ?? 'client';

    if (data != null) {
      _userData = Map<String, dynamic>.from(data);
    }

    final name = _userData?['name']?.toString() ?? '';
    final email = _userData?['email']?.toString() ?? '';
    _isProfileComplete = isProfileComplete ??
        (name.trim().isNotEmpty && email.trim().isNotEmpty && !name.contains('Valued Client'));
  }

  /// Syncs session directly after successful backend /api/auth/sync call
  void syncWithBackendUser({
    required int id,
    required String token,
    required Map<String, dynamic> userMap,
  }) {
    _backendUserId = id;
    _backendToken = token;
    _userRole = userMap['role']?.toString() ?? 'client';

    final name = userMap['name']?.toString() ?? '';
    final email = userMap['email']?.toString() ?? '';
    final phone = userMap['phone']?.toString() ?? '';

    _userData = {
      ...?_userData,
      'name': name,
      'email': email,
      'phone': phone,
      'role': _userRole,
      'id': id,
    };

    final profileFlag = userMap['is_profile_complete'];
    if (profileFlag is bool) {
      _isProfileComplete = profileFlag;
    } else {
      _isProfileComplete = name.trim().isNotEmpty && email.trim().isNotEmpty;
    }
  }

  /// Updates profile details in memory after /api/user/profile update
  void updateProfileData({required String name, required String email}) {
    _userData = {
      ...?_userData,
      'name': name.trim(),
      'email': email.trim(),
    };
    _isProfileComplete = name.trim().isNotEmpty && email.trim().isNotEmpty;
  }

  Future<void> syncWithFirebaseUser(User user, {String? role}) async {
    final idToken = await user.getIdToken();
    _token = idToken ?? 'firebase_jwt_token';
    _userId = user.uid;
    _userRole = role ?? 'client';

    _userData = {
      ...?_userData,
      'name': user.displayName ?? '',
      'email': user.email ?? '',
      'phone': user.phoneNumber ?? '',
      'photoUrl': user.photoURL ?? '',
    };

    final name = _userData?['name']?.toString() ?? '';
    final email = _userData?['email']?.toString() ?? '';
    _isProfileComplete = name.trim().isNotEmpty && email.trim().isNotEmpty;
  }

  void clearSession() {
    _token = null;
    _backendToken = null;
    _userId = null;
    _backendUserId = null;
    _userRole = null;
    _isProfileComplete = false;
    _userData = null;
  }
}

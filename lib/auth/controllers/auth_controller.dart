import 'package:flutter/foundation.dart';
import '../../services/auth_service.dart';
import '../models/user_model.dart';

/// Auth state and business logic controller.
class AuthController extends ChangeNotifier {
  AuthController({AuthService? authService})
      : _authService = authService ?? AuthService.instance;

  final AuthService _authService;
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null || _authService.isLoggedIn;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        _currentUser = UserModel(
          id: user.uid,
          name: user.displayName ?? 'Valued Client',
          email: user.email ?? email,
          phone: user.phoneNumber,
          avatarUrl: user.photoURL,
          role: 'user',
        );
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = _authService.getReadableErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }
}

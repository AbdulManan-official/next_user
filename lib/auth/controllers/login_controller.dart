import 'package:flutter/material.dart';
import '../../services/session_service.dart';

/// Controller handling login form state, inputs, and authentication.
class LoginController extends ChangeNotifier {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController emailController =
      TextEditingController(text: 'test@gmail.com');
  final TextEditingController passwordController =
      TextEditingController(text: 'password');

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isPasswordVisible => _isPasswordVisible;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void clearErrorMessage() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Authenticate user credentials
  Future<bool> login(BuildContext context) async {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final email = emailController.text.trim();
      final password = passwordController.text;

      // Check dummy credentials (test@gmail.com / password) or any valid format
      await Future.delayed(const Duration(milliseconds: 600));

      if (email.toLowerCase() == 'test@gmail.com' && password == 'password') {
        _isLoading = false;
        SessionService.instance.saveSession(
          token: 'user_jwt_token_sample',
          userId: 'usr_001',
          role: 'user',
          data: {
            'email': email,
            'name': 'Valued Client',
          },
        );
        notifyListeners();
        return true;
      } else {
        // Fallback valid demo authentication
        _isLoading = false;
        SessionService.instance.saveSession(
          token: 'user_jwt_token_sample',
          userId: 'usr_001',
          role: 'user',
          data: {
            'email': email,
            'name': 'Valued Client',
          },
        );
        notifyListeners();
        return true;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An error occurred during login: $e';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

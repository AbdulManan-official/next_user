import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'session_service.dart';

/// Production-ready Firebase Authentication Service handling Email/Password,
/// Phone SMS OTP, Google Sign-In, Apple Sign-In, and Password Reset.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  // google_sign_in v7 uses GoogleSignIn.instance (singleton)
  final SessionService _session = SessionService.instance;

  /// Stream of user authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Currently logged in Firebase User
  User? get currentUser => _auth.currentUser;

  /// Whether a user is currently signed in
  bool get isLoggedIn => _auth.currentUser != null;

  // ---------------------------------------------------------------------------
  // 1. Email & Password Authentication
  // ---------------------------------------------------------------------------

  /// Sign in with Email and Password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        await _session.syncWithFirebaseUser(credential.user!);
      }

      return credential;
    } catch (e) {
      debugPrint('⚠️ [AuthService] signInWithEmailAndPassword error: $e');
      rethrow;
    }
  }

  /// Backward compatible alias for signInWithEmailAndPassword
  Future<bool> login({
    required String emailOrPhone,
    required String password,
  }) async {
    final cred = await signInWithEmailAndPassword(
      email: emailOrPhone,
      password: password,
    );
    return cred.user != null;
  }

  /// Backward compatible alias for signOut
  Future<void> logout() => signOut();

  /// Create a new account with Name, Email, and Password
  Future<UserCredential> signUpWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update Firebase User Profile display name
      final user = credential.user;
      if (user != null) {
        await user.updateDisplayName(name.trim());
        await user.reload();
        final refreshedUser = _auth.currentUser ?? user;
        await _session.syncWithFirebaseUser(refreshedUser);
      }

      return credential;
    } catch (e) {
      debugPrint('⚠️ [AuthService] signUpWithEmailAndPassword error: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 2. Phone Authentication & SMS OTP
  // ---------------------------------------------------------------------------

  /// Sends 6-digit SMS OTP to given phone number via Firebase Phone Auth
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
    required Function(String verificationId) onCodeAutoRetrievalTimeout,
    int? resendToken,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber.trim(),
        forceResendingToken: resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-retrieval / Instant verification on Android
          try {
            final userCred = await _auth.signInWithCredential(credential);
            if (userCred.user != null) {
              await _session.syncWithFirebaseUser(userCred.user!);
            }
          } catch (_) {}
          onVerificationCompleted(credential);
        },
        verificationFailed: onVerificationFailed,
        codeSent: onCodeSent,
        codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      debugPrint('⚠️ [AuthService] verifyPhoneNumber error: $e');
      rethrow;
    }
  }

  /// Verifies SMS code and signs in with PhoneAuthCredential
  Future<UserCredential> verifyOtpAndSignIn({
    required String verificationId,
    required String smsCode,
    String? displayName,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );

      final userCred = await _auth.signInWithCredential(credential);

      if (userCred.user != null) {
        if (displayName != null && displayName.trim().isNotEmpty) {
          await userCred.user!.updateDisplayName(displayName.trim());
          await userCred.user!.reload();
        }
        final refreshedUser = _auth.currentUser ?? userCred.user!;
        await _session.syncWithFirebaseUser(refreshedUser);
      }

      return userCred;
    } catch (e) {
      debugPrint('⚠️ [AuthService] verifyOtpAndSignIn error: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 3. Social Authentication (Google & Apple)
  // ---------------------------------------------------------------------------

  /// Sign in using Google OAuth (google_sign_in v7 API)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // v7: authenticate() returns GoogleSignInAccount directly
      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();

      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        // v7: accessToken not available — idToken is sufficient for Firebase
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);

      if (userCred.user != null) {
        await _session.syncWithFirebaseUser(userCred.user!);
      }

      return userCred;
    } catch (e) {
      debugPrint('⚠️ [AuthService] signInWithGoogle error: $e');
      final str = e.toString().toLowerCase();
      // If user deliberately cancelled/dismissed dialog, return null gracefully
      if (str.contains('canceled') ||
          str.contains('cancelled') ||
          str.contains('abort') ||
          str.contains('interrupted')) {
        return null;
      }
      rethrow;
    }
  }

  /// Sign in using Apple OAuth
  Future<UserCredential?> signInWithApple() async {
    try {
      final appleProvider = AppleAuthProvider();
      final userCred = await _auth.signInWithProvider(appleProvider);

      if (userCred.user != null) {
        await _session.syncWithFirebaseUser(userCred.user!);
      }

      return userCred;
    } catch (e) {
      debugPrint('⚠️ [AuthService] signInWithApple error: $e');
      final str = e.toString().toLowerCase();
      if (str.contains('canceled') ||
          str.contains('cancelled') ||
          str.contains('popup_closed') ||
          str.contains('closed')) {
        return null;
      }
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 4. Password Reset
  // ---------------------------------------------------------------------------

  /// Sends a official Firebase Password Reset link to the user's email
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      debugPrint('⚠️ [AuthService] sendPasswordResetEmail error: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 5. Sign Out
  // ---------------------------------------------------------------------------

  /// Sign out from all providers and clear local session
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
      _session.clearSession();
    } catch (e) {
      debugPrint('⚠️ [AuthService] signOut error: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 6. Enterprise Human-Readable Error Message Parser
  // ---------------------------------------------------------------------------

  /// Converts technical FirebaseAuthException codes into friendly messages
  String getReadableErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No registered account found with this email.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'invalid-credential':
          return 'Invalid credentials. Please verify your email and password.';
        case 'email-already-in-use':
          return 'This email address is already registered. Please sign in instead.';
        case 'invalid-email':
          return 'The email address provided is improperly formatted.';
        case 'weak-password':
          return 'The password is too weak. Please use at least 6 characters.';
        case 'user-disabled':
          return 'This user account has been disabled by security administration.';
        case 'too-many-requests':
          return 'Too many attempts. For security, please wait a moment and try again.';
        case 'operation-not-allowed':
          return 'This sign-in method is currently disabled in your Firebase console.';
        case 'invalid-verification-code':
          return 'Invalid 6-digit verification code. Please check SMS and try again.';
        case 'invalid-verification-id':
          return 'Session expired. Please request a new verification code.';
        case 'session-expired':
          return 'The verification session has timed out. Please request a new code.';
        case 'invalid-phone-number':
          return 'The phone number provided is not valid. Please enter a valid mobile number.';
        case 'quota-exceeded':
          return 'Daily SMS quota exceeded. Please contact support or use email sign-in.';
        case 'network-request-failed':
          return 'Network connectivity error. Please check your internet connection.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with this email using a different sign-in provider.';
        default:
          return error.message ?? 'An error occurred during authentication (${error.code}).';
      }
    }

    final str = error?.toString() ?? '';
    final lower = str.toLowerCase();

    if (lower.contains('10') || lower.contains('developer_error')) {
      return 'Google Sign-In configuration error: Please make sure SHA-1 key is added in Firebase Console.';
    }
    if (lower.contains('12500') || lower.contains('sign_in_failed')) {
      return 'Google Sign-In failed. Please check your Google Play Services or network.';
    }
    if (lower.contains('network') || lower.contains('socket') || lower.contains('7:')) {
      return 'Network connection error. Please check your internet connection and try again.';
    }
    if (lower.contains('operation-not-allowed') || lower.contains('not enabled')) {
      return 'This sign-in provider is not enabled in Firebase Console.';
    }
    if (lower.contains('popup_closed') || lower.contains('canceled') || lower.contains('cancelled')) {
      return 'Sign-in was cancelled.';
    }

    if (str.startsWith('Exception: ')) {
      return str.substring(11);
    }

    return 'Authentication failed. Please verify your details and try again.';
  }
}

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'auth_errors.dart';
import 'api_client.dart';
import 'notification_service.dart';
import 'session_service.dart';
import '../utils/app_urls.dart';

/// Single source of truth Authentication Service for Next User.
/// Implements complete multi-provider authentication (Email/Password, Phone SMS OTP, Google OAuth),
/// seamless credential linking, token re-issuance (getIdToken(true)), and re-authentication.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Saved when Google says: account-exists-with-different-credential
  AuthCredential? pendingCredential;
  String? pendingEmail;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  List<String> get providerIds =>
      currentUser?.providerData.map((p) => p.providerId).toList() ?? [];

  // ---------------------------------------------------------------------------
  // 1. Email & Password Authentication
  // ---------------------------------------------------------------------------

  /// Sign in with Email and Password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    final c = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await linkPendingIfAny();
    return c;
  }

  /// Create a new account with Email and Password
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    final c = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await c.user?.sendEmailVerification();
    return c;
  }

  /// Send official Firebase password reset email
  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  /// Send verification email to currently signed in user
  Future<void> sendEmailVerification() async {
    await currentUser?.sendEmailVerification();
  }

  // Backward compatibility alias for older calls
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) => signInWithEmail(email, password);

  Future<UserCredential> signUpWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await signUpWithEmail(email, password);
    if (name.trim().isNotEmpty && cred.user != null) {
      await cred.user!.updateDisplayName(name.trim());
      await cred.user!.reload();
    }
    return cred;
  }

  Future<void> sendPasswordResetEmail({required String email}) =>
      sendPasswordReset(email);

  // ---------------------------------------------------------------------------
  // 2. Phone Authentication & SMS OTP
  // ---------------------------------------------------------------------------

  /// Verify phone number via SMS OTP (Simplified callback signature)
  Future<void> verifyPhone({
    required String phoneNumber, // E.164, for example +923001234567 or +447911123456
    required bool linking,
    int? resendToken,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function() onAutoDone,
    required void Function(Object error) onError,
  }) {
    return _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber.trim(),
      timeout: const Duration(seconds: 60),
      forceResendingToken: resendToken,
      verificationCompleted: (PhoneAuthCredential cred) async {
        try {
          if (linking) {
            await currentUser!.linkWithCredential(cred);
            await currentUser!.getIdToken(true);
          } else {
            await _auth.signInWithCredential(cred);
            await linkPendingIfAny();
          }
          onAutoDone();
        } catch (e) {
          onError(e);
        }
      },
      verificationFailed: (FirebaseAuthException e) => onError(e),
      codeSent: (id, token) => onCodeSent(id, token),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  /// Full verifyPhoneNumber method matching Flutter/Firebase standard callbacks
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(FirebaseAuthException e) onVerificationFailed,
    required void Function(PhoneAuthCredential credential) onVerificationCompleted,
    required void Function(String verificationId) onCodeAutoRetrievalTimeout,
    int? resendToken,
  }) {
    return _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber.trim(),
      timeout: const Duration(seconds: 60),
      forceResendingToken: resendToken,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await _auth.signInWithCredential(credential);
          await linkPendingIfAny();
        } catch (_) {}
        onVerificationCompleted(credential);
      },
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
    );
  }

  /// Sign in with SMS OTP verification ID and code (named parameters)
  Future<UserCredential> verifyOtpAndSignIn({
    required String verificationId,
    required String smsCode,
    String? displayName,
  }) async {
    final cred = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode.trim(),
    );
    final r = await _auth.signInWithCredential(cred);
    if (displayName != null && displayName.trim().isNotEmpty && r.user != null) {
      await r.user!.updateDisplayName(displayName.trim());
      await r.user!.reload();
    }
    await linkPendingIfAny();
    return r;
  }

  /// Positional variant matching guide: verifyOtp(id, code)
  Future<UserCredential> verifyOtp(String verificationId, String code) =>
      verifyOtpAndSignIn(verificationId: verificationId, smsCode: code);

  /// Link phone credential to currently logged-in account (for users who signed up via Email or Google)
  Future<void> linkPhone(String verificationId, String code) async {
    final cred = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: code.trim(),
    );
    await currentUser!.linkWithCredential(cred);
    await currentUser!.getIdToken(true);
  }

  // ---------------------------------------------------------------------------
  // 3. Link Email + Password (Phone Users)
  // ---------------------------------------------------------------------------

  /// Links email and password to an account that signed up via Phone OTP
  Future<void> linkEmailPassword(String email, String password) async {
    final user = currentUser!;
    final cred = EmailAuthProvider.credential(
      email: email.trim(),
      password: password,
    );
    await user.linkWithCredential(cred);
    await user.sendEmailVerification(); // linking does NOT auto-verify email
    await user.reload();
    await _auth.currentUser!.getIdToken(true);
  }

  // ---------------------------------------------------------------------------
  // 4. Social Authentication (Google OAuth)
  // ---------------------------------------------------------------------------

  /// Sign in using Google OAuth with account linking fallback
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();

      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final r = await _auth.signInWithCredential(credential);
      await linkPendingIfAny();
      return r;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        pendingCredential = e.credential;
        pendingEmail = e.email;
      }
      rethrow;
    } catch (e) {
      final str = e.toString().toLowerCase();
      // User cancelled picker
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
      await linkPendingIfAny();
      return userCred;
    } catch (e) {
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

  /// Automatically links pending credentials after a successful second-provider login
  Future<void> linkPendingIfAny() async {
    final p = pendingCredential;
    final u = currentUser;
    if (p == null || u == null) return;
    try {
      await u.linkWithCredential(p);
      await u.getIdToken(true);
    } on FirebaseAuthException catch (e) {
      if (e.code != 'provider-already-linked') rethrow;
    } finally {
      pendingCredential = null;
      pendingEmail = null;
    }
  }

  // ---------------------------------------------------------------------------
  // 5. Re-authentication (Required before sensitive operations like account deletion)
  // ---------------------------------------------------------------------------

  Future<void> reauthWithPassword(String password) async {
    final u = currentUser!;
    await u.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: u.email!, password: password),
    );
    await u.getIdToken(true);
  }

  Future<void> reauthWithGoogle() async {
    final GoogleSignInAccount googleUser =
        await GoogleSignIn.instance.authenticate();
    final GoogleSignInAuthentication googleAuth =
        googleUser.authentication;
    await currentUser!.reauthenticateWithCredential(
      GoogleAuthProvider.credential(idToken: googleAuth.idToken),
    );
    await currentUser!.getIdToken(true);
  }

  Future<void> reauthWithPhone(String verificationId, String code) async {
    await currentUser!.reauthenticateWithCredential(
      PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: code.trim(),
      ),
    );
    await currentUser!.getIdToken(true);
  }

  // ---------------------------------------------------------------------------
  // 6. Sign Out
  // ---------------------------------------------------------------------------

  /// Sign out from all providers, clear FCM push token on backend & device, and clear local session
  Future<void> signOut() async {
    pendingCredential = null;
    pendingEmail = null;

    // 1. Clear FCM token on the backend so logged-out device does not receive push alerts
    try {
      await ApiClient.instance.delete(AppUrls.fcmToken);
    } catch (_) {}

    // 2. Unregister device push token from Firebase Cloud Messaging
    try {
      await NotificationService.instance.deleteToken();
    } catch (_) {}

    // 3. Sign out of Google and Firebase
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _auth.signOut();
    SessionService.instance.clearSession();
  }

  // ---------------------------------------------------------------------------
  // 7. Error Translation Helper
  // ---------------------------------------------------------------------------

  String getReadableErrorMessage(dynamic error) => readableError(error);
}

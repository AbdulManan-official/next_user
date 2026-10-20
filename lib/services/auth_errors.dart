import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Returns a human-readable error message for both Firebase and Backend API errors.
/// Returns an empty string when the error should be ignored (e.g., provider-already-linked).
String readableError(Object e) {
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'Account exists. Sign in with your original method.';
      case 'credential-already-in-use':
        return 'This phone/email belongs to another account. Please contact support.';
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in.';
      case 'provider-already-linked':
        return '';
      case 'requires-recent-login':
        return 'Please sign in again to continue.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Wrong email or password, or this account uses Google/Phone.';
      case 'invalid-verification-code':
        return 'Wrong code. Try again.';
      case 'session-expired':
        return 'Code expired. Please resend.';
      case 'too-many-requests':
        return 'Too many tries. Wait a bit and try again.';
      case 'network-request-failed':
        return 'No internet connection.';
      case 'weak-password':
        return 'Password must be at least 8 characters.';
      case 'invalid-phone-number':
        return 'Phone number is not valid.';
      case 'operation-not-allowed':
        return 'SMS is not enabled for this region.';
    }
    if ((e.message ?? '').contains('17006')) return 'SMS is not enabled for this region.';
  }
  if (e is DioException) {
    final data = e.response?.data;
    final code = data is Map ? data['code'] : null;
    switch (code) {
      case 'PHONE_EXISTS':
        return 'This phone is already registered. Sign in with your original method.';
      case 'EMAIL_EXISTS':
        return 'This email is already registered. Sign in with email, then add your phone in Profile.';
      case 'NAME_REQUIRED':
        return 'Please enter your name.';
      case 'REAUTH_REQUIRED':
        return 'Please sign in again to continue.';
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'No internet connection.';
    }
  }
  return 'Something went wrong. Please try again.';
}

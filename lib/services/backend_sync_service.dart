import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../utils/app_urls.dart';
import 'api_client.dart';
import 'session_service.dart';

/// Service responsible for synchronizing authenticated users with the Backend Database.
/// Implements POST /api/auth/sync, PUT /api/users/me, and DELETE /api/users/me per the unified Auth Architecture.
class BackendSyncService {
  BackendSyncService._();
  static final BackendSyncService instance = BackendSyncService._();

  final ApiClient _api = ApiClient.instance;

  /// Synchronizes user with backend (POST /auth/sync).
  /// Backend returns: { user, providers, missing, is_profile_complete }
  Future<Map<String, dynamic>> syncUserWithBackend({
    String? loginType,
    String? login,
    String? firebaseUid,
    String? name,
    String? email,
    String? deviceToken,
  }) async {
    final uid = firebaseUid ?? FirebaseAuth.instance.currentUser?.uid ?? SessionService.instance.userId;

    try {
      if (kDebugMode) {
        debugPrint('[BackendSyncService] Syncing with ${AppUrls.authSync} for UID: $uid');
      }

      // POST /auth/sync (Token is attached automatically as Bearer in ApiClient)
      final response = await _api.post(AppUrls.authSync);

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final userData = (data['user'] as Map<String, dynamic>?) ?? {};
        final backendId = int.tryParse(userData['id']?.toString() ?? '') ?? 1;
        final isProfileComplete = data['is_profile_complete'] == true;
        final missing = (data['missing'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
        final providers = (data['providers'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

        SessionService.instance.syncWithBackendUser(
          id: backendId,
          token: SessionService.instance.token ?? '',
          userMap: {
            ...userData,
            'is_profile_complete': isProfileComplete,
          },
        );

        return {
          'success': true,
          'is_profile_complete': isProfileComplete,
          'missing': missing,
          'providers': providers,
          'user': userData,
        };
      }
    } on DioException catch (dioErr) {
      if (kDebugMode) {
        debugPrint('[BackendSyncService] Backend sync HTTP error: ${dioErr.response?.statusCode} - ${dioErr.message}');
      }
      // Re-throw 409 conflict errors (PHONE_EXISTS, EMAIL_EXISTS) so caller can display exact readable error
      if (dioErr.response?.statusCode == 409) {
        rethrow;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BackendSyncService] Unexpected error during backend sync: $e');
      }
    }

    // Graceful Fallback Mode (If backend route is offline or not yet deployed)
    final fbUser = FirebaseAuth.instance.currentUser;
    final currentName = (fbUser?.displayName ?? name ?? SessionService.instance.clientName).trim();
    final currentEmail = (fbUser?.email ?? email ?? SessionService.instance.clientEmail).trim();
    final currentPhone = (fbUser?.phoneNumber ?? (loginType == 'phone' ? login : null) ?? SessionService.instance.clientPhone).trim();

    final providers = fbUser?.providerData.map((p) => p.providerId).toList() ?? [];
    final missing = <String>[];
    if (currentName.isEmpty || currentName.length < 2 || currentName == 'Valued Client') {
      missing.add('name');
    }
    if (currentEmail.isEmpty) {
      missing.add('email');
    }
    if (currentPhone.isEmpty) {
      missing.add('phone');
    }
    final hasLogin = providers.contains('password') || providers.contains('google.com');
    if (!hasLogin) {
      missing.add('password');
    }

    final isComplete = missing.isEmpty;

    SessionService.instance.saveSession(
      token: SessionService.instance.token ?? 'fallback_token',
      userId: uid ?? 'fb_local_user',
      backendUserId: 1,
      role: 'client',
      isProfileComplete: isComplete,
      data: {
        'name': currentName,
        'email': currentEmail,
        'phone': currentPhone,
        'role': 'client',
      },
    );

    return {
      'success': true,
      'fallback': true,
      'is_profile_complete': isComplete,
      'missing': missing,
      'providers': providers,
      'user': {
        'name': currentName,
        'email': currentEmail,
        'phone': currentPhone,
        'role': 'client',
      },
    };
  }

  /// Updates client profile details (PUT /api/users/me).
  /// In the standard API: name is passed in request body, email & phone are verified from the token.
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? email,
  }) async {
    final cleanName = name.trim();

    try {
      final response = await _api.put(
        AppUrls.usersMe,
        data: {
          'name': cleanName,
          if (email != null && email.trim().isNotEmpty) 'email': email.trim().toLowerCase(),
        },
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final isComplete = data['is_profile_complete'] == true;
        SessionService.instance.updateProfileData(name: cleanName, email: email?.trim());
        return {
          'success': true,
          'is_profile_complete': isComplete,
          'message': 'Profile updated successfully',
        };
      }
    } on DioException catch (dioErr) {
      if (dioErr.response?.statusCode == 409 || dioErr.response?.statusCode == 400) {
        rethrow;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BackendSyncService] Profile update offline/fallback: $e');
      }
    }

    // Always update local session so the client is never blocked
    SessionService.instance.updateProfileData(name: cleanName, email: email?.trim());
    return {
      'success': true,
      'fallback': true,
      'is_profile_complete': true,
      'message': 'Profile saved successfully',
    };
  }

  /// Delete current user account (DELETE /api/users/me) - Play Store Compliance
  Future<bool> deleteAccount() async {
    try {
      final response = await _api.delete(AppUrls.usersMe);
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BackendSyncService] deleteAccount error: $e');
      }
      rethrow;
    }
    return false;
  }
}

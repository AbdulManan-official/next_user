import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_errors.dart';
import 'backend_sync_service.dart';
import 'notification_service.dart';
import '../widgets/animation_helper.dart';
import '../widgets/app_snack_bar.dart';
import '../views/bottom_tab_view.dart';
import '../auth/views/complete_profile_view.dart';
import '../auth/views/login_view.dart';

/// Centralized post-authentication routing implementing the strict profile gate rule:
/// 1. Synchronizes user with backend (POST /auth/sync).
/// 2. If is_profile_complete == false, gates navigation strictly to CompleteProfileView.
/// 3. If is_profile_complete == true, routes directly to BottomTabView (Home).
/// 4. Surfaces errors using readableError(e).
Future<void> routeAfterAuth(
  BuildContext context, {
  Map<String, dynamic>? precomputedSync,
}) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          AnimationHelper.smoothRoute(page: const LoginView()),
          (route) => false,
        );
      }
      return;
    }

    final syncResult = precomputedSync ??
        await BackendSyncService.instance.syncUserWithBackend();

    if (!context.mounted) return;

    final isComplete = syncResult['is_profile_complete'] == true;
    final List<String> missing = List<String>.from(syncResult['missing'] ?? []);

    // Sync FCM Push notification token in background
    NotificationService.instance.initialize();

    if (!isComplete || missing.isNotEmpty) {
      Navigator.of(context).pushAndRemoveUntil(
        AnimationHelper.smoothRoute(
          page: CompleteProfileView(missing: missing),
        ),
        (route) => false,
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        AnimationHelper.smoothRoute(page: const BottomTabView()),
        (route) => false,
      );
    }
  } catch (e) {
    if (!context.mounted) return;
    final errorMsg = readableError(e);
    if (errorMsg.isNotEmpty) {
      AppSnackBar.showError(context, errorMsg);
    }
  }
}

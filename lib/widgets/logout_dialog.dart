import 'package:flutter/material.dart';
import 'app_snack_bar.dart';
import 'glass_kit.dart';

import '../auth/views/login_view.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'animation_helper.dart';
import '../utils/app_theme_styles.dart';
import '../utils/responsive_helper.dart';

/// Reusable Confirmation Dialog for destructive or sensitive actions.
class ConfirmDialog {
  ConfirmDialog._();

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDanger = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) {
        final responsive = ctx.responsive;
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding:
              EdgeInsets.symmetric(horizontal: responsive.r(24), vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: GlassCard(
              radius: 24,
              blur: 24,
              fillAlpha: 0.06,
              edgeTint: isDanger ? AppColors.error : AppColors.gold,
              underlay: AppColors.surface.withValues(alpha: 0.88),
              padding: EdgeInsets.symmetric(
                horizontal: responsive.r(20),
                vertical: responsive.r(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isDanger ? AppColors.error : AppColors.gold)
                              .withValues(alpha: 0.14),
                          border: Border.all(
                            color: (isDanger ? AppColors.error : AppColors.gold)
                                .withValues(alpha: 0.42),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isDanger
                                      ? AppColors.error
                                      : AppColors.gold)
                                  .withValues(alpha: 0.28),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                        child: Icon(
                          isDanger
                              ? Icons.logout_rounded
                              : Icons.info_outline_rounded,
                          color: isDanger ? AppColors.error : AppColors.gold,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: responsive.sp(20),
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: responsive.r(16)),
                  Text(
                    message,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: responsive.sp(13),
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: responsive.r(22)),
                  Row(
                    children: [
                      Expanded(
                        child: GlassButton(
                          label: cancelText,
                          height: 48,
                          onTap: () => Navigator.of(ctx).pop(false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: isDanger
                            ? _DangerButton(
                                label: confirmText,
                                onTap: () => Navigator.of(ctx).pop(true),
                              )
                            : GoldButton(
                                label: confirmText,
                                height: 48,
                                onTap: () => Navigator.of(ctx).pop(true),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Glass logout confirmation dialog.
/// Returns true if the user confirms logout, false otherwise.
Future<bool> showLogoutConfirmationDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => const _LogoutDialog(),
  );
  return confirmed ?? false;
}

// Blocks double tap while a logout is already running.
bool _loggingOut = false;

/// Logout with confirmation, session clearing, navigation reset, error handling.
Future<void> performUserLogout(BuildContext context) async {
  if (_loggingOut) return;
  _loggingOut = true;

  var loadingShown = false;
  final rootNav = Navigator.of(context, rootNavigator: true);

  try {
    final confirmed = await showLogoutConfirmationDialog(context);
    if (!confirmed || !context.mounted) return;

    // Non-dismissible loading dialog while clearing tokens & session.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      useRootNavigator: true,
      builder: (_) => const _SigningOutDialog(),
    );
    loadingShown = true;

    await AuthService.instance.signOut();

    try {
      await NotificationService.instance.deleteToken();
    } catch (_) {}

    // removeUntil wipes every route, loading dialog included.
    rootNav.pushAndRemoveUntil(
      AnimationHelper.smoothRoute(page: const LoginView()),
      (route) => false,
    );
  } catch (e) {
    debugPrint('Logout failed: $e');
    // pop(), NOT maybePop(): the loading dialog is wrapped in
    // PopScope(canPop: false), so maybePop would never close it.
    if (loadingShown && rootNav.mounted) rootNav.pop();
    if (context.mounted) {
      AppSnackBar.showError(context, 'Failed to log out. Please try again.');
    }
  } finally {
    _loggingOut = false;
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  CONFIRM DIALOG
// ════════════════════════════════════════════════════════════════════════════
class _LogoutDialog extends StatelessWidget {
  const _LogoutDialog();

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return MediaQuery.withClampedTextScaling(
      minScaleFactor: 0.9,
      maxScaleFactor: 1.15,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding:
            EdgeInsets.symmetric(horizontal: responsive.r(24), vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: GlassCard(
            radius: 24,
            blur: 24,
            fillAlpha: 0.06,
            edgeTint: AppColors.error,
            underlay: AppColors.surface.withValues(alpha: 0.88),
            padding: EdgeInsets.symmetric(
              horizontal: responsive.r(20),
              vertical: responsive.r(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.error.withValues(alpha: 0.14),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.42),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withValues(alpha: 0.28),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.error,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Sign Out',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: responsive.sp(20),
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: responsive.r(16)),
                Text(
                  'Are you sure you want to log out? You will need to sign in '
                  'again to access your portal.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: responsive.sp(13),
                    height: 1.5,
                  ),
                ),
                SizedBox(height: responsive.r(22)),
                Row(
                  children: [
                    Expanded(
                      child: GlassButton(
                        label: 'Cancel',
                        height: 48,
                        onTap: () => Navigator.of(context).pop(false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DangerButton(
                        label: 'Logout',
                        onTap: () => Navigator.of(context).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Destructive action: red gradient, same shape as GoldButton.
class _DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DangerButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(18);

    return Semantics(
      button: true,
      label: label,
      child: Pressable(
        onTap: onTap,
        scale: 0.97,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: r,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF26B6B), AppColors.error, Color(0xFFD13434)],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withValues(alpha: 0.38),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  SIGNING-OUT DIALOG
// ════════════════════════════════════════════════════════════════════════════
class _SigningOutDialog extends StatelessWidget {
  const _SigningOutDialog();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: MediaQuery.withClampedTextScaling(
        minScaleFactor: 0.9,
        maxScaleFactor: 1.15,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: GlassCard(
            radius: 24,
            blur: 20,
            fillAlpha: 0.08,
            underlay: AppColors.surface.withValues(alpha: 0.72),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Semantics(
              liveRegion: true,
              label: 'Signing out',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      strokeCap: StrokeCap.round,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppColors.gold),
                      backgroundColor: AppColors.gold.withValues(alpha: 0.22),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Signing out...',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
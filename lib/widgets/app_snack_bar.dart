import 'package:flutter/material.dart';
import '../utils/app_theme_styles.dart';
import 'glass_kit.dart';

/// Single source of truth for app-wide SnackBar notifications.
/// Glass toast: blurred surface, status-tinted edge + glow, icon tile.
/// Success = green, Error = red, Warning = amber, Info = gold.
class AppSnackBar {
  AppSnackBar._();

  static const Duration _duration = Duration(seconds: 4);

  static void showSuccess(BuildContext context, String message) => _show(
        context,
        message,
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
      );

  static void showError(BuildContext context, String message) => _show(
        context,
        message,
        icon: Icons.error_outline_rounded,
        color: AppColors.error,
      );

  static void showWarning(BuildContext context, String message) => _show(
        context,
        message,
        icon: Icons.warning_amber_rounded,
        color: AppColors.warning,
      );

  static void showInfo(BuildContext context, String message) => _show(
        context,
        message,
        icon: Icons.info_outline_rounded,
        color: AppColors.gold,
      );

  static void _show(
    BuildContext context,
    String message, {
    required IconData icon,
    required Color color,
  }) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        // Glass card draws everything. SnackBar itself = invisible frame.
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        behavior: SnackBarBehavior.floating,
        clipBehavior: Clip.none, // else card shadow gets clipped
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: _duration,
        content: _GlassToast(message: message, icon: icon, color: color),
      ),
    );
  }
}

class _GlassToast extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;

  const _GlassToast({
    required this.message,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true, // screen reader announces it
      child: GlassCard(
        radius: 20,
        blur: 16,
        fillAlpha: 0.08,
        edgeTint: color,
        // Dark base + status tint → text readable on any backdrop.
        underlay: Color.alphaBlend(
          color.withValues(alpha: 0.16),
          AppColors.surface.withValues(alpha: 0.78),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.16),
                border: Border.all(color: color.withValues(alpha: 0.45)),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.30),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
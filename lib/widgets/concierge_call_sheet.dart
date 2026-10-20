import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/app_theme_styles.dart';

/// Luxury Call Sheet Modal for Concierge & Crew instant calls.
class ConciergeCallSheet extends StatefulWidget {
  const ConciergeCallSheet({
    super.key,
    required this.name,
    required this.role,
    this.avatarInitials = 'NC',
  });

  final String name;
  final String role;
  final String avatarInitials;

  static void show(
    BuildContext context, {
    required String name,
    required String role,
    String avatarInitials = 'NC',
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ConciergeCallSheet(
        name: name,
        role: role,
        avatarInitials: avatarInitials,
      ),
    );
  }

  @override
  State<ConciergeCallSheet> createState() => _ConciergeCallSheetState();
}

class _ConciergeCallSheetState extends State<ConciergeCallSheet> {
  bool _isMuted = false;
  bool _isSpeaker = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 32,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 28),

                // Avatar with glowing aura ring
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: AppColors.goldGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.avatarInitials,
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.textOnGold,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                Text(widget.name, style: AppTextStyles.headlineLarge),
                const SizedBox(height: 4),
                Text(
                  widget.role,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.goldLight),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Connected · 00:24',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 36),

                // Call Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mute
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: _isMuted ? AppColors.gold : AppColors.surfaceElevated,
                        padding: const EdgeInsets.all(18),
                      ),
                      icon: Icon(
                        _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                        color: _isMuted ? AppColors.textOnGold : AppColors.textPrimary,
                        size: 26,
                      ),
                      onPressed: () => setState(() => _isMuted = !_isMuted),
                    ),

                    // End Call
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.error,
                        padding: const EdgeInsets.all(22),
                      ),
                      icon: const Icon(Icons.call_end_rounded, color: Colors.white, size: 30),
                      onPressed: () => Navigator.of(context).pop(),
                    ),

                    // Speaker
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: _isSpeaker ? AppColors.gold : AppColors.surfaceElevated,
                        padding: const EdgeInsets.all(18),
                      ),
                      icon: Icon(
                        _isSpeaker ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                        color: _isSpeaker ? AppColors.textOnGold : AppColors.textPrimary,
                        size: 26,
                      ),
                      onPressed: () => setState(() => _isSpeaker = !_isSpeaker),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

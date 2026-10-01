import 'package:flutter/material.dart';
import '../utils/app_theme_styles.dart';

/// Screen displayed for outgoing audio/video calls.
class OutgoingCallScreen extends StatelessWidget {
  const OutgoingCallScreen({
    super.key,
    required this.calleeName,
    this.calleeAvatar,
    this.isVideo = false,
  });

  final String calleeName;
  final String? calleeAvatar;
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.surfaceElevated,
              child: const Icon(Icons.person, size: 60, color: AppColors.gold),
            ),
            const SizedBox(height: 24),
            Text(calleeName, style: AppTextStyles.headlineLarge),
            const SizedBox(height: 8),
            Text(
              'Calling...',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.goldLight),
            ),
            const Spacer(),
            Center(
              child: IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.error,
                  padding: const EdgeInsets.all(20),
                ),
                icon: const Icon(Icons.call_end_rounded, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(height: 54),
          ],
        ),
      ),
    );
  }
}

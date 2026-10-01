import 'package:flutter/material.dart';
import '../utils/app_theme_styles.dart';

/// Screen displayed for incoming audio/video calls.
class IncomingCallScreen extends StatelessWidget {
  const IncomingCallScreen({
    super.key,
    required this.callerName,
    this.callerAvatar,
    this.isVideo = false,
  });

  final String callerName;
  final String? callerAvatar;
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
            Text(callerName, style: AppTextStyles.headlineLarge),
            const SizedBox(height: 8),
            Text(
              'Incoming ${isVideo ? 'Video' : 'Audio'} Call...',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.goldLight),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Decline Button
                  Column(
                    children: [
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.error,
                          padding: const EdgeInsets.all(18),
                        ),
                        icon: const Icon(Icons.call_end_rounded, color: Colors.white, size: 28),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(height: 8),
                      Text('Decline', style: AppTextStyles.labelSmall),
                    ],
                  ),
                  // Accept Button
                  Column(
                    children: [
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.all(18),
                        ),
                        icon: const Icon(Icons.call_rounded, color: Colors.white, size: 28),
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                      const SizedBox(height: 8),
                      Text('Accept', style: AppTextStyles.labelSmall),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 54),
          ],
        ),
      ),
    );
  }
}

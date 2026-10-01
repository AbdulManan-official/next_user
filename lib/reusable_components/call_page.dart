import 'package:flutter/material.dart';
import '../utils/app_theme_styles.dart';

/// Audio & Video Call active session screen.
class CallPage extends StatelessWidget {
  const CallPage({
    super.key,
    required this.calleeName,
    this.isVideo = false,
  });

  final String calleeName;
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
              radius: 54,
              backgroundColor: AppColors.surfaceElevated,
              child: const Icon(Icons.person, size: 54, color: AppColors.gold),
            ),
            const SizedBox(height: 20),
            Text(calleeName, style: AppTextStyles.headlineLarge),
            const SizedBox(height: 8),
            Text(
              isVideo ? 'Video Call' : 'Audio Call',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.goldLight),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceElevated,
                    padding: const EdgeInsets.all(16),
                  ),
                  icon: const Icon(Icons.mic_off_rounded, color: AppColors.textPrimary),
                  onPressed: () {},
                ),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.error,
                    padding: const EdgeInsets.all(20),
                  ),
                  icon: const Icon(Icons.call_end_rounded, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceElevated,
                    padding: const EdgeInsets.all(16),
                  ),
                  icon: const Icon(Icons.volume_up_rounded, color: AppColors.textPrimary),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

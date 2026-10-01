import 'package:flutter/material.dart';
import '../utils/app_theme_styles.dart';

/// Video player screen placeholder with luxury controls.
class VideoViewerScreen extends StatelessWidget {
  const VideoViewerScreen({
    super.key,
    required this.videoUrl,
    this.title = 'Video Player',
  });

  final String videoUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        title: Text(title, style: AppTextStyles.titleMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.gold),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.goldGradient,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: AppColors.textOnGold,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Video Stream',
              style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

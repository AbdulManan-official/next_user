import 'package:flutter/material.dart';
import '../utils/app_theme_styles.dart';

/// Full-screen zoomable image viewer with luxury dark backdrop.
class ImagePreviewScreen extends StatelessWidget {
  const ImagePreviewScreen({
    super.key,
    required this.imageUrl,
    this.title = 'Image Preview',
    this.isAsset = false,
  });

  final String imageUrl;
  final String title;
  final bool isAsset;

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
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: isAsset
              ? Image.asset(imageUrl, fit: BoxFit.contain)
              : Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.broken_image_rounded, color: AppColors.textMuted, size: 64),
                  ),
                ),
        ),
      ),
    );
  }
}

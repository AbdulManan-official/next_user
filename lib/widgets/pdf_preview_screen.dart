import 'package:flutter/material.dart';
import '../utils/app_theme_styles.dart';

/// PDF Document preview screen wrapper.
class PdfPreviewScreen extends StatelessWidget {
  const PdfPreviewScreen({
    super.key,
    required this.pdfUrl,
    this.title = 'Document Viewer',
  });

  final String pdfUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
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
            const Icon(Icons.picture_as_pdf_rounded, color: AppColors.gold, size: 64),
            const SizedBox(height: 16),
            Text('PDF Document', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 8),
            Text(
              pdfUrl,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

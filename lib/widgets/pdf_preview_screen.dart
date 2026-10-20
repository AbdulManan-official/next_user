import 'dart:async';
import 'dart:io';
import 'dart:ui' show ImageFilter;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../utils/app_theme_styles.dart';
import '../utils/responsive_helper.dart';
import 'app_snack_bar.dart';
import 'glass_kit.dart';

/// Reusable Luxury PDF Preview & Download Viewer Screen.
/// Provides built-in pinch-to-zoom, page navigation, direct download to app sandbox,
/// native sharing, printing, and retry fallback handling.
/// Supports URLs, Local file paths, Pre-built Uint8List bytes, and Dynamic on-the-fly Builders.
/// Glass UI: GlassAmbientBackground, GlassCircleButton, GlassCard, GoldButton.
/// Complies with 2026 Flutter production rules (.withValues(alpha: ...), mounted guards).
class PdfPreviewScreen extends StatefulWidget {
  final String? pdfUrl;
  final Uint8List? pdfBytes;
  final FutureOr<Uint8List> Function(PdfPageFormat format)? buildCustomPdf;
  final String? title;
  final String? fileName;
  final String? subtitle;
  final bool showDownloadButton;
  final bool showShareButton;
  final bool showPrintButton;

  const PdfPreviewScreen({
    super.key,
    this.pdfUrl,
    this.pdfBytes,
    this.buildCustomPdf,
    this.title,
    this.fileName,
    this.subtitle,
    this.showDownloadButton = true,
    this.showShareButton = true,
    this.showPrintButton = true,
  }) : assert(
          pdfUrl != null || pdfBytes != null || buildCustomPdf != null,
          'Either pdfUrl, pdfBytes, or buildCustomPdf must be provided to PdfPreviewScreen',
        );

  /// Static helper for opening from remote/local URL
  static Future<void> open(
    BuildContext context, {
    required String pdfUrl,
    String? title,
    String? fileName,
    String? subtitle,
    bool showDownloadButton = true,
    bool showShareButton = true,
    bool showPrintButton = true,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfPreviewScreen(
          pdfUrl: pdfUrl,
          title: title,
          fileName: fileName,
          subtitle: subtitle,
          showDownloadButton: showDownloadButton,
          showShareButton: showShareButton,
          showPrintButton: showPrintButton,
        ),
      ),
    );
  }

  /// Static helper for opening from pre-generated Document Bytes
  static Future<void> fromBytes(
    BuildContext context, {
    required Uint8List pdfBytes,
    String? title,
    String? fileName,
    String? subtitle,
    bool showDownloadButton = true,
    bool showShareButton = true,
    bool showPrintButton = true,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfPreviewScreen(
          pdfBytes: pdfBytes,
          title: title,
          fileName: fileName,
          subtitle: subtitle,
          showDownloadButton: showDownloadButton,
          showShareButton: showShareButton,
          showPrintButton: showPrintButton,
        ),
      ),
    );
  }

  /// Static helper for opening from dynamic PDF Builder function
  static Future<void> fromBuilder(
    BuildContext context, {
    required FutureOr<Uint8List> Function(PdfPageFormat format) buildPdf,
    String? title,
    String? fileName,
    String? subtitle,
    bool showDownloadButton = true,
    bool showShareButton = true,
    bool showPrintButton = true,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfPreviewScreen(
          buildCustomPdf: buildPdf,
          title: title,
          fileName: fileName,
          subtitle: subtitle,
          showDownloadButton: showDownloadButton,
          showShareButton: showShareButton,
          showPrintButton: showPrintButton,
        ),
      ),
    );
  }

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  CancelToken? _cancelToken;
  Uint8List? _cachedBytes;
  String? _errorMessage;

  String get _resolvedFileName {
    if (widget.fileName != null && widget.fileName!.isNotEmpty) {
      return widget.fileName!.endsWith('.pdf') ? widget.fileName! : '${widget.fileName}.pdf';
    }
    if (widget.pdfUrl != null && widget.pdfUrl!.isNotEmpty) {
      final rawName = widget.pdfUrl!.split('?').first.split('/').last.split('\\').last;
      if (rawName.isNotEmpty && rawName.contains('.pdf')) {
        return rawName;
      }
    }
    return 'Document_${DateTime.now().millisecondsSinceEpoch}.pdf';
  }

  @override
  void initState() {
    super.initState();
    if (widget.pdfBytes != null) {
      _cachedBytes = widget.pdfBytes;
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel('Screen disposed');
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════
  //  LOGIC (unchanged)
  // ══════════════════════════════════════════════════════════════════════

  /// Fetches bytes from custom builder, pre-passed bytes, or remote/local URL
  Future<Uint8List> _loadPdfBytes(PdfPageFormat format) async {
    if (_cachedBytes != null) return _cachedBytes!;

    if (widget.pdfBytes != null) {
      _cachedBytes = widget.pdfBytes;
      return _cachedBytes!;
    }

    if (widget.buildCustomPdf != null) {
      try {
        _cachedBytes = await widget.buildCustomPdf!(format);
        return _cachedBytes!;
      } catch (e) {
        if (mounted) {
          setState(() => _errorMessage = 'Failed to generate document: $e');
        }
        rethrow;
      }
    }

    final url = widget.pdfUrl?.trim() ?? '';
    if (url.isEmpty) {
      throw Exception('PDF source is empty');
    }

    try {
      if (url.startsWith('http://') || url.startsWith('https://')) {
        final dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 25),
            receiveTimeout: const Duration(minutes: 2),
            responseType: ResponseType.bytes,
          ),
        );

        final response = await dio.get<List<int>>(
          url,
          cancelToken: _cancelToken,
        );

        if (response.data != null) {
          _cachedBytes = Uint8List.fromList(response.data!);
          return _cachedBytes!;
        } else {
          throw Exception('No document data received from server');
        }
      } else {
        // Local File Path
        final cleanPath = url.replaceFirst('file://', '');
        final file = File(cleanPath);
        if (await file.exists()) {
          _cachedBytes = await file.readAsBytes();
          return _cachedBytes!;
        } else {
          throw Exception('Local PDF file not found at: $cleanPath');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
      rethrow;
    }
  }

  /// Downloads PDF to App Documents directory and lets user open/share or view
  Future<void> _downloadAndSavePdf() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    _cancelToken = CancelToken();

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final savePath = '${docsDir.path}/$_resolvedFileName';
      final file = File(savePath);

      if (_cachedBytes != null) {
        await file.writeAsBytes(_cachedBytes!);
      } else if (widget.buildCustomPdf != null) {
        _cachedBytes = await widget.buildCustomPdf!(PdfPageFormat.a4);
        await file.writeAsBytes(_cachedBytes!);
      } else {
        final url = widget.pdfUrl?.trim() ?? '';
        if (url.isEmpty) {
          throw Exception('No document source available to download');
        }

        if (url.startsWith('http://') || url.startsWith('https://')) {
          final dio = Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 25),
              receiveTimeout: const Duration(minutes: 2),
            ),
          );

          await dio.download(
            url,
            savePath,
            cancelToken: _cancelToken,
            onReceiveProgress: (received, total) {
              if (total > 0 && mounted) {
                setState(() {
                  _downloadProgress = (received / total).clamp(0.0, 1.0);
                });
              }
            },
          );

          _cachedBytes = await file.readAsBytes();
        } else {
          final src = File(url.replaceFirst('file://', ''));
          if (await src.exists()) {
            await src.copy(savePath);
            _cachedBytes = await file.readAsBytes();
          } else {
            throw Exception('Local file does not exist');
          }
        }
      }

      if (!mounted) return;

      AppSnackBar.showSuccess(
        context,
        'Document saved: $_resolvedFileName',
      );

      // Offer direct native share sheet option
      _showDownloadedActionModal(file);
    } on DioException catch (dioError) {
      if (!mounted) return;
      if (CancelToken.isCancel(dioError)) {
        AppSnackBar.showInfo(context, 'Download cancelled');
      } else {
        AppSnackBar.showError(
          context,
          'Download failed: ${dioError.message ?? 'Network error'}',
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, 'Error saving PDF: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  /// Native Share PDF via share sheet
  Future<void> _sharePdfFile() async {
    try {
      final bytes = _cachedBytes ?? await _loadPdfBytes(PdfPageFormat.a4);
      await Printing.sharePdf(
        bytes: bytes,
        filename: _resolvedFileName,
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Could not share PDF: $e');
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  //  UI
  // ══════════════════════════════════════════════════════════════════════

  /// Floating glass sheet shown after a successful save.
  void _showDownloadedActionModal(File file) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      elevation: 0,
      builder: (ctx) => MediaQuery.withClampedTextScaling(
        minScaleFactor: 0.9,
        maxScaleFactor: 1.15,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: GlassCard(
              radius: 28,
              blur: 20,
              fillAlpha: 0.08,
              underlay: AppColors.surface.withValues(alpha: 0.78),
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _IconBadge(
                    icon: Icons.check_rounded,
                    color: _successColor,
                    size: 56,
                    iconSize: 28,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'PDF Ready',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 19,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _resolvedFileName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: GlassButton(
                          label: 'Share File',
                          icon: Icons.ios_share_rounded,
                          height: 48,
                          onTap: () {
                            Navigator.pop(ctx);
                            _sharePdfFile();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GoldButton(
                          label: 'Done',
                          icon: Icons.done_rounded,
                          height: 48,
                          shine: true,
                          onTap: () => Navigator.pop(ctx),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final responsive = context.responsive;

    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 8),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.68),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.09),
                  width: 0.8,
                ),
              ),
            ),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: true,
              leadingWidth: 64,
              leading: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: GlassCircleButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  size: 40,
                  iconSize: 16,
                  iconColor: AppColors.gold,
                  semanticLabel: 'Back',
                  onTap: () => Navigator.pop(context),
                ),
              ),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title ?? 'Document Preview',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: responsive.sp(15.5),
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle ?? _resolvedFileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.gold,
                      fontSize: responsive.sp(11),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              actions: [
                if (widget.showShareButton)
                  Padding(
                    padding: EdgeInsets.only(
                      right: widget.showDownloadButton ? 0 : 12,
                    ),
                    child: GlassCircleButton(
                      icon: Icons.ios_share_rounded,
                      size: 40,
                      iconSize: 18,
                      iconColor: AppColors.gold,
                      semanticLabel: 'Share Document',
                      onTap: _sharePdfFile,
                    ),
                  ),
                if (widget.showDownloadButton)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _isDownloading
                        ? _DownloadingCircle(progress: _downloadProgress)
                        : GlassCircleButton(
                            icon: Icons.download_rounded,
                            size: 40,
                            iconSize: 19,
                            iconColor: AppColors.gold,
                            semanticLabel: 'Save PDF to Device',
                            onTap: _downloadAndSavePdf,
                          ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: GlassCard(
        radius: 24,
        blur: 18,
        fillAlpha: 0.08,
        underlay: AppColors.surface.withValues(alpha: 0.70),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                strokeCap: StrokeCap.round,
                color: AppColors.gold,
                backgroundColor: AppColors.gold.withValues(alpha: 0.18),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Rendering document...',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    final responsive = context.responsive;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(responsive.pagePadding),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: GlassCard(
            radius: 28,
            blur: 20,
            fillAlpha: 0.08,
            edgeTint: AppColors.error,
            underlay: AppColors.surface.withValues(alpha: 0.72),
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _IconBadge(
                  icon: Icons.broken_image_rounded,
                  color: AppColors.error,
                  size: 76,
                  iconSize: 34,
                ),
                const SizedBox(height: 18),
                Text(
                  'Failed to Load Document',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: responsive.sp(18),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage ?? error.toString(),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: responsive.sp(12.5),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                GoldButton(
                  label: 'Retry Loading',
                  icon: Icons.refresh_rounded,
                  height: 48,
                  shine: true,
                  onTap: () {
                    setState(() {
                      _cachedBytes = null;
                      _errorMessage = null;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      minScaleFactor: 0.9,
      maxScaleFactor: 1.15,
      child: Scaffold(
        backgroundColor: AppColors.background,
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(context),
        body: Stack(
          children: [
            const Positioned.fill(child: GlassAmbientBackground()),
            SafeArea(
              child: Column(
                children: [
                  // Slim gold progress line while saving
                  if (_isDownloading)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 2),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: _downloadProgress > 0.0 ? _downloadProgress : null,
                          backgroundColor: Colors.white.withValues(alpha: 0.10),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                          minHeight: 3,
                        ),
                      ),
                    ),
                  Expanded(
                    child: PdfPreview(
                      build: (format) => _loadPdfBytes(format),
                      canChangeOrientation: false,
                      canChangePageFormat: false,
                      canDebug: false,
                      allowPrinting: widget.showPrintButton,
                      allowSharing: false, // custom glass share in AppBar
                      pdfFileName: _resolvedFileName,
                      maxPageWidth: 720,
                      previewPageMargin: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      // Transparent canvas so ambient glow shows behind pages.
                      scrollViewDecoration: const BoxDecoration(color: Colors.transparent),
                      // Pages float on a soft gold-tinted shadow.
                      pdfPreviewPageDecoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.45),
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                          ),
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.10),
                            blurRadius: 40,
                          ),
                        ],
                      ),
                      actionBarTheme: PdfActionBarTheme(
                        backgroundColor: AppColors.surface.withValues(alpha: 0.85),
                        iconColor: AppColors.gold,
                      ),
                      loadingWidget: _buildLoading(),
                      onError: (context, error) => _buildError(context, error),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  PARTS
// ════════════════════════════════════════════════════════════════════════════

const Color _successColor = Color(0xFF34D399);

/// Circular tinted icon badge with soft glow (same recipe as logout dialog).
class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  const _IconBadge({
    required this.icon,
    required this.color,
    required this.size,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.42)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.28),
            blurRadius: 20,
          ),
        ],
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

/// AppBar slot shown instead of the download button while saving.
class _DownloadingCircle extends StatelessWidget {
  final double progress;
  const _DownloadingCircle({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Saving document',
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.18),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.40)),
            ),
            child: CircularProgressIndicator(
              value: progress > 0.0 ? progress : null,
              strokeWidth: 2.2,
              strokeCap: StrokeCap.round,
              color: AppColors.gold,
              backgroundColor: AppColors.gold.withValues(alpha: 0.18),
            ),
          ),
        ),
      ),
    );
  }
}

/// Reusable glass card for PDF attachments in message bubbles or lists.
/// blur: 0 → safe inside long lists (no BackdropFilter per row).
class AppPdfCard extends StatelessWidget {
  final String pdfUrl;
  final String fileName;
  final String? fileSize;
  final VoidCallback? onTap;

  const AppPdfCard({
    super.key,
    required this.pdfUrl,
    required this.fileName,
    this.fileSize,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.98,
      semanticLabel: 'Open $fileName',
      onTap: onTap ??
          () {
            PdfPreviewScreen.open(
              context,
              pdfUrl: pdfUrl,
              fileName: fileName,
              title: 'PDF Document',
            );
          },
      child: GlassCard(
        radius: 18,
        blur: 0,
        shadow: false,
        fillAlpha: 0.08,
        underlay: AppColors.surface.withValues(alpha: 0.55),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: AppColors.error.withValues(alpha: 0.14),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.38)),
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                color: AppColors.error,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (fileSize != null) ...[
                        Text(
                          fileSize!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 10.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.textMuted.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          'Tap to preview',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.gold,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.12),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
              ),
              child: const Icon(
                Icons.arrow_outward_rounded,
                color: AppColors.gold,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
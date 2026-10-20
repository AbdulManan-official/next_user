import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../utils/app_theme_styles.dart';
import 'app_snack_bar.dart';
import 'glass_kit.dart';

/// Full-screen image previewer: pinch-to-zoom, gallery swipe, Hero,
/// gallery download. Glass header, glass download banner.
class ImagePreviewScreen extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String? title;
  final String? subtitle;
  final String albumName;
  final String? heroTag;
  final bool showDownloadButton;

  const ImagePreviewScreen({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.title,
    this.subtitle,
    this.albumName = 'NextGen_Images',
    this.heroTag,
    this.showDownloadButton = true,
  });

  /// Single image preview helper
  static Future<void> open(
    BuildContext context, {
    required String imageUrl,
    String? title,
    String? subtitle,
    String albumName = 'NextGen_Images',
    String? heroTag,
    bool showDownloadButton = true,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImagePreviewScreen(
          imageUrls: [imageUrl],
          title: title,
          subtitle: subtitle,
          albumName: albumName,
          heroTag: heroTag ?? imageUrl,
          showDownloadButton: showDownloadButton,
        ),
      ),
    );
  }

  /// Multi-image gallery preview helper
  static Future<void> openGallery(
    BuildContext context, {
    required List<String> imageUrls,
    int initialIndex = 0,
    String? title,
    String? subtitle,
    String albumName = 'NextGen_Images',
    bool showDownloadButton = true,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImagePreviewScreen(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
          title: title,
          subtitle: subtitle,
          albumName: albumName,
          showDownloadButton: showDownloadButton,
        ),
      ),
    );
  }

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  late final PageController _pageController;
  late final ValueNotifier<int> _index;

  // Granular notifiers: only header / banner rebuild, never the gallery.
  final ValueNotifier<bool> _isDownloading = ValueNotifier<bool>(false);
  final ValueNotifier<double> _progress = ValueNotifier<double>(0);

  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    final max = widget.imageUrls.isNotEmpty ? widget.imageUrls.length - 1 : 0;
    final start = widget.initialIndex.clamp(0, max);
    _index = ValueNotifier<int>(start);
    _pageController = PageController(initialPage: start);
  }

  @override
  void dispose() {
    _cancelToken?.cancel('Screen closed');
    _pageController.dispose();
    _index.dispose();
    _isDownloading.dispose();
    _progress.dispose();
    super.dispose();
  }

  void _cancelDownload() {
    _cancelToken?.cancel('Cancelled by user');
  }

  String get _currentImageUrl {
    if (widget.imageUrls.isEmpty) return '';
    return widget.imageUrls[_index.value];
  }

  bool _isNetwork(String path) =>
      path.startsWith('http://') || path.startsWith('https://');

  ImageProvider _getImageProvider(String path) {
    return _isNetwork(path)
        ? CachedNetworkImageProvider(path)
        : FileImage(File(path));
  }

  // ── Permission ───────────────────────────────────────────────────────────
  Future<bool> _requestGalleryPermission() async {
    if (Platform.isAndroid) {
      final photoStatus = await Permission.photos.status;
      if (photoStatus.isGranted || photoStatus.isLimited) return true;

      final storageStatus = await Permission.storage.status;
      if (storageStatus.isGranted) return true;

      final requestedPhotos = await Permission.photos.request();
      if (requestedPhotos.isGranted || requestedPhotos.isLimited) return true;

      final requestedStorage = await Permission.storage.request();
      if (requestedStorage.isGranted) return true;

      if (requestedPhotos.isPermanentlyDenied ||
          requestedStorage.isPermanentlyDenied) {
        _showPermissionSettingsDialog(
          title: 'Permission Required',
          message:
              'Photos or Storage permission is needed to save images to your gallery. Please enable it in Settings.',
        );
        return false;
      }

      // Android 10+ MediaStore scoped storage needs no permission.
      return true;
    } else if (Platform.isIOS) {
      final photosStatus = await Permission.photos.status;
      if (photosStatus.isGranted || photosStatus.isLimited) return true;

      final requested = await Permission.photos.request();
      if (requested.isGranted || requested.isLimited) return true;

      if (requested.isPermanentlyDenied) {
        _showPermissionSettingsDialog(
          title: 'Photos Access Required',
          message:
              'Please enable Photos access in Settings to save images to your album.',
        );
      }
      return false;
    }
    return true;
  }

  void _showPermissionSettingsDialog({
    required String title,
    required String message,
  }) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => MediaQuery.withClampedTextScaling(
        minScaleFactor: 0.9,
        maxScaleFactor: 1.15,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: GlassCard(
              radius: 28,
              blur: 20,
              fillAlpha: 0.08,
              underlay: AppColors.surface.withValues(alpha: 0.72),
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w800,
                      fontSize: 19,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: GlassButton(
                          label: 'Cancel',
                          height: 48,
                          onTap: () => Navigator.pop(ctx),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GoldButton(
                          label: 'Open Settings',
                          height: 48,
                          onTap: () {
                            Navigator.pop(ctx);
                            openAppSettings();
                          },
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

  // ── Download ─────────────────────────────────────────────────────────────
  Future<void> _saveCurrentImage() async {
    if (_isDownloading.value) return;

    final url = _currentImageUrl.trim();
    if (url.isEmpty) {
      AppSnackBar.showError(context, 'Invalid image URL');
      return;
    }

    final hasPermission = await _requestGalleryPermission();
    if (!hasPermission) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          'Permission required to save images. Please grant permission.',
        );
      }
      return;
    }
    if (!mounted) return;

    _isDownloading.value = true;
    _progress.value = 0;

    final cancelToken = CancelToken();
    _cancelToken = cancelToken;
    File? tempFile;
    Dio? dio;

    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = url.split('?').first.split('.').last.toLowerCase();
      final validExt =
          (ext == 'png' || ext == 'jpg' || ext == 'jpeg' || ext == 'webp')
          ? ext
          : 'jpg';
      final tempPath = '${tempDir.path}/image_$timestamp.$validExt';
      tempFile = File(tempPath);

      if (_isNetwork(url)) {
        // 1. Fast path: already in image cache
        final cached = await DefaultCacheManager().getFileFromCache(url);
        if (cached != null && await cached.file.exists()) {
          if (mounted) _progress.value = 1.0;
          await cached.file.copy(tempPath);
        } else {
          // 2. Network download with progress
          dio = Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 25),
              receiveTimeout: const Duration(minutes: 2),
            ),
          );

          await dio.download(
            url,
            tempPath,
            cancelToken: cancelToken,
            onReceiveProgress: (received, total) {
              if (total > 0 && mounted) {
                _progress.value = (received / total).clamp(0.0, 1.0);
              }
            },
          );
        }
      } else {
        final src = File(url);
        if (await src.exists()) {
          await src.copy(tempPath);
        } else {
          throw Exception('Local image file does not exist');
        }
      }

      if (!mounted) return;

      final bool? success = await GallerySaver.saveImage(
        tempPath,
        albumName: widget.albumName,
      );

      if (!mounted) return;
      if (success == true) {
        HapticFeedback.lightImpact();
        AppSnackBar.showSuccess(
          context,
          'Image saved successfully to gallery (${widget.albumName})',
        );
      } else {
        AppSnackBar.showError(
          context,
          'Could not save image to gallery. Please check permissions.',
        );
      }
    } on DioException catch (dioError) {
      if (!mounted) return;
      if (CancelToken.isCancel(dioError)) {
        AppSnackBar.showInfo(context, 'Download cancelled.');
      } else {
        debugPrint('Image download failed: $dioError');
        AppSnackBar.showError(
          context,
          'Failed to download image. Check your connection and try again.',
        );
      }
    } catch (e) {
      debugPrint('Image save failed: $e');
      if (!mounted) return;
      AppSnackBar.showError(context, 'Could not save image. Please try again.');
    } finally {
      dio?.close(force: true);
      if (tempFile != null) {
        try {
          if (await tempFile.exists()) await tempFile.delete();
        } catch (_) {}
      }
      if (mounted) {
        _isDownloading.value = false;
        _progress.value = 0;
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isMulti = widget.imageUrls.length > 1;
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: MediaQuery.withClampedTextScaling(
        minScaleFactor: 0.9,
        maxScaleFactor: 1.15,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // ── Gallery (full bleed)
              Positioned.fill(
                child: PhotoViewGallery.builder(
                  scrollPhysics: const BouncingScrollPhysics(),
                  pageController: _pageController,
                  itemCount: widget.imageUrls.length,
                  onPageChanged: (i) => _index.value = i,
                  backgroundDecoration: const BoxDecoration(
                    color: Colors.black,
                  ),
                  builder: (context, i) {
                    final url = widget.imageUrls[i];
                    final tag = widget.heroTag ?? url;

                    return PhotoViewGalleryPageOptions(
                      imageProvider: _getImageProvider(url),
                      heroAttributes: PhotoViewHeroAttributes(tag: tag),
                      minScale: PhotoViewComputedScale.contained,
                      maxScale: PhotoViewComputedScale.covered * 3.0,
                      initialScale: PhotoViewComputedScale.contained,
                      errorBuilder: (context, error, stackTrace) =>
                          const _ImageError(),
                    );
                  },
                  loadingBuilder: (context, event) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          value:
                              event == null ||
                                  event.expectedTotalBytes == null ||
                                  event.expectedTotalBytes == 0
                              ? null
                              : event.cumulativeBytesLoaded /
                                    event.expectedTotalBytes!,
                          strokeWidth: 2.5,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.gold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Loading high-res preview...',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Header (scrim + glass buttons)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.72),
                        Colors.black.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(12, topPad + 8, 12, 22),
                    child: Row(
                      children: [
                        GlassCircleButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          iconSize: 18,
                          iconColor: AppColors.gold,
                          semanticLabel: 'Back',
                          onTap: () => Navigator.maybePop(context),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ValueListenableBuilder<int>(
                            valueListenable: _index,
                            builder: (context, i, _) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.title ??
                                      (isMulti
                                          ? 'Photo ${i + 1} of ${widget.imageUrls.length}'
                                          : 'Image Preview'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                if (widget.subtitle != null)
                                  Text(
                                    widget.subtitle!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.gold,
                                      fontSize: 11,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (widget.showDownloadButton) ...[
                          const SizedBox(width: 12),
                          ValueListenableBuilder<bool>(
                            valueListenable: _isDownloading,
                            builder: (context, downloading, _) => SizedBox(
                              width: 44,
                              height: 44,
                              child: downloading
                                  ? const Center(
                                      child: SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                AppColors.gold,
                                              ),
                                        ),
                                      ),
                                    )
                                  : GlassCircleButton(
                                      icon: Icons.download_rounded,
                                      iconColor: AppColors.gold,
                                      semanticLabel: 'Save to Gallery',
                                      onTap: _saveCurrentImage,
                                    ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // ── Page counter
              if (isMulti)
                Positioned(
                  bottom: bottomPad + 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _isDownloading,
                      builder: (context, downloading, child) => AnimatedOpacity(
                        opacity: downloading ? 0 : 1,
                        duration: const Duration(milliseconds: 200),
                        child: child,
                      ),
                      child: GlassChip(
                        child: ValueListenableBuilder<int>(
                          valueListenable: _index,
                          builder: (context, i, _) => Text(
                            '${i + 1} / ${widget.imageUrls.length}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // ── Download banner
              Positioned(
                bottom: bottomPad + 16,
                left: 16,
                right: 16,
                child: ValueListenableBuilder<bool>(
                  valueListenable: _isDownloading,
                  builder: (context, downloading, _) => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: downloading
                        ? _DownloadBanner(
                            key: const ValueKey('banner'),
                            progress: _progress,
                            onCancel: _cancelDownload,
                          )
                        : const SizedBox.shrink(key: ValueKey('none')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  PARTS
// ════════════════════════════════════════════════════════════════════════════
class _ImageError extends StatelessWidget {
  const _ImageError();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.error.withValues(alpha: 0.12),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.error.withValues(alpha: 0.20),
                  blurRadius: 26,
                ),
              ],
            ),
            child: const Icon(
              Icons.broken_image_rounded,
              color: AppColors.error,
              size: 40,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Could not load image',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadBanner extends StatelessWidget {
  final ValueListenable<double> progress;
  final VoidCallback onCancel;

  const _DownloadBanner({
    super.key,
    required this.progress,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Saving to gallery',
      child: GlassCard(
        radius: 22,
        blur: 18,
        fillAlpha: 0.08,
        underlay: AppColors.surface.withValues(alpha: 0.78),
        padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.14),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.25),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: const Icon(
                Icons.downloading_rounded,
                color: AppColors.gold,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ValueListenableBuilder<double>(
                valueListenable: progress,
                builder: (context, p, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Saving to Gallery...',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${(p * 100).toInt()}%',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: p > 0 ? p : null,
                        backgroundColor: Colors.white.withValues(alpha: 0.10),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.gold,
                        ),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(
                Icons.close_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
              tooltip: 'Cancel',
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              onPressed: onCancel,
            ),
          ],
        ),
      ),
    );
  }
}

/// Thumbnail that opens ImagePreviewScreen on tap.
class AppImageThumbnail extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;
  final String? heroTag;
  final String? title;
  final String? subtitle;

  const AppImageThumbnail({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.borderRadius = 12.0,
    this.fit = BoxFit.cover,
    this.heroTag,
    this.title,
    this.subtitle,
  });

  Widget _placeholder() => Container(
    color: AppColors.surfaceElevated,
    child: const Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
        ),
      ),
    ),
  );

  Widget _error() => Container(
    color: AppColors.surfaceElevated,
    child: const Center(
      child: Icon(
        Icons.broken_image_rounded,
        color: AppColors.textMuted,
        size: 28,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final tag = heroTag ?? imageUrl;
    final isNetwork =
        imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

    return Pressable(
      scale: 0.97,
      semanticLabel: title ?? 'Open image',
      onTap: () => ImagePreviewScreen.open(
        context,
        imageUrl: imageUrl,
        title: title,
        subtitle: subtitle,
        heroTag: tag,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Hero(
          tag: tag,
          child: SizedBox(
            width: width,
            height: height,
            child: isNetwork
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: fit,
                    placeholder: (context, url) => _placeholder(),
                    errorWidget: (context, url, error) => _error(),
                  )
                : Image.file(
                    File(imageUrl),
                    fit: fit,
                    errorBuilder: (context, error, stackTrace) => _error(),
                  ),
          ),
        ),
      ),
    );
  }
}

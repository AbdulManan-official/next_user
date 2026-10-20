import 'dart:io';
import 'dart:ui' show ImageFilter;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import '../utils/app_theme_styles.dart';
import '../utils/responsive_helper.dart';
import 'app_snack_bar.dart';
import 'glass_kit.dart';

/// Reusable full-screen Video Viewer & Player with gallery download capability.
/// Complies with 2026 Flutter production standards, scoped permissions,
/// glass luxury UI (GlassAmbientBackground, GlassCircleButton, GlassCard,
/// GoldButton) and memory-leak-safe controller lifecycle.
class VideoViewerScreen extends StatefulWidget {
  final String videoUrl;
  final String? title;
  final String? subtitle;
  final String albumName;
  final bool autoPlay;
  final bool looping;
  final bool showDownloadButton;

  const VideoViewerScreen({
    super.key,
    required this.videoUrl,
    this.title,
    this.subtitle,
    this.albumName = 'NextGen_Surveys',
    this.autoPlay = true,
    this.looping = false,
    this.showDownloadButton = true,
  });

  /// Static helper for quick navigation
  static Future<void> open(
    BuildContext context, {
    required String videoUrl,
    String? title,
    String? subtitle,
    String albumName = 'NextGen_Surveys',
    bool showDownloadButton = true,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoViewerScreen(
          videoUrl: videoUrl,
          title: title,
          subtitle: subtitle,
          albumName: albumName,
          showDownloadButton: showDownloadButton,
        ),
      ),
    );
  }

  @override
  State<VideoViewerScreen> createState() => _VideoViewerScreenState();
}

class _VideoViewerScreenState extends State<VideoViewerScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // Download state
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadProgressText = '0%';
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void dispose() {
    _cancelToken?.cancel('Screen disposed');
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════
  //  LOGIC (unchanged, except Chewie errorBuilder + permission dialog UI)
  // ══════════════════════════════════════════════════════════════════════

  /// Initializes the video player and Chewie controllers safely
  Future<void> _initializePlayer() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final uri = Uri.parse(widget.videoUrl);
      final isNetwork = uri.isScheme('http') || uri.isScheme('https');

      File? cachedFile;
      if (isNetwork) {
        final fileInfo = await DefaultCacheManager().getFileFromCache(widget.videoUrl);
        if (fileInfo != null && fileInfo.file.existsSync()) {
          cachedFile = fileInfo.file;
        }
      }

      if (cachedFile != null) {
        debugPrint('[VideoViewerScreen] Playing instantly from disk cache: ${cachedFile.path}');
        _videoPlayerController = VideoPlayerController.file(cachedFile);
      } else if (isNetwork) {
        _videoPlayerController = VideoPlayerController.networkUrl(uri);
        // Cache in background for instant playback next time
        _cacheVideoInBackground(widget.videoUrl);
      } else {
        _videoPlayerController = VideoPlayerController.file(File(widget.videoUrl));
      }

      await _videoPlayerController!.initialize();

      if (!mounted) return;

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: widget.autoPlay,
        looping: widget.looping,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        playbackSpeeds: const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0],
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.gold,
          handleColor: AppColors.goldLight,
          bufferedColor: AppColors.gold.withValues(alpha: 0.35),
          backgroundColor: Colors.white.withValues(alpha: 0.14),
        ),
        cupertinoProgressColors: ChewieProgressColors(
          playedColor: AppColors.gold,
          handleColor: AppColors.goldLight,
          bufferedColor: AppColors.gold.withValues(alpha: 0.35),
          backgroundColor: Colors.white.withValues(alpha: 0.14),
        ),
        errorBuilder: (context, error) => _PlayerErrorPanel(
          title: 'Could not play video',
          message: null,
          retryLabel: 'Retry',
          onRetry: _initializePlayer,
          compact: true,
        ),
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load video: ${e.toString()}';
      });
    }
  }

  void _cacheVideoInBackground(String url) async {
    try {
      await DefaultCacheManager().downloadFile(url);
      debugPrint('[VideoViewerScreen] Video successfully cached in background: $url');
    } catch (_) {
      // Background cache failure is non-blocking
    }
  }

  /// Request scoped permission for Android 13+ (videos), older Android (storage), or iOS (photos)
  Future<bool> _requestGalleryPermission() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+), request Permission.videos
      final videoStatus = await Permission.videos.status;
      if (videoStatus.isGranted || videoStatus.isLimited) return true;

      // Fallback for Android 12 and below: request storage permission
      final storageStatus = await Permission.storage.status;
      if (storageStatus.isGranted) return true;

      // Request videos permission first
      final requestedVideoStatus = await Permission.videos.request();
      if (requestedVideoStatus.isGranted || requestedVideoStatus.isLimited) return true;

      // Request storage permission if videos wasn't granted
      final requestedStorage = await Permission.storage.request();
      if (requestedStorage.isGranted) return true;

      if (requestedVideoStatus.isPermanentlyDenied || storageStatus.isPermanentlyDenied) {
        _showPermissionSettingsDialog(
          title: 'Permission Required',
          message: 'Video or Storage permission is needed to save videos to your gallery. Please enable it in Settings.',
        );
        return false;
      }

      // Allow fallback attempt on Android 10+ (API 29+) MediaStore scoped storage
      return true;
    } else if (Platform.isIOS) {
      final photosStatus = await Permission.photos.status;
      if (photosStatus.isGranted || photosStatus.isLimited) return true;

      final requested = await Permission.photos.request();
      if (requested.isGranted || requested.isLimited) return true;

      if (requested.isPermanentlyDenied) {
        _showPermissionSettingsDialog(
          title: 'Photos Access Required',
          message: 'Please enable Photos access in Settings to save videos to your gallery.',
        );
      }

      return false;
    }

    return true;
  }

  /// Glass permission dialog. Same behaviour: Cancel closes, Open Settings
  /// closes then calls openAppSettings().
  void _showPermissionSettingsDialog({required String title, required String message}) {
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
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
                  Row(
                    children: [
                      const _IconBadge(
                        icon: Icons.lock_open_rounded,
                        color: AppColors.gold,
                        size: 46,
                        iconSize: 22,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 19,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                          label: 'Settings',
                          icon: Icons.settings_rounded,
                          height: 48,
                          shine: true,
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

  /// Downloads video from backend URL, saves to device gallery, then cleans up temp files
  Future<void> _saveVideoToGallery() async {
    if (_isDownloading) return;

    final url = widget.videoUrl.trim();
    if (url.isEmpty) {
      AppSnackBar.showError(context, 'Invalid video URL');
      return;
    }

    // Check permissions
    final hasPermission = await _requestGalleryPermission();
    if (!hasPermission) {
      if (mounted) {
        AppSnackBar.showError(context, 'Permission required to save video to gallery. Please grant permission.');
      }
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _downloadProgressText = '0%';
    });

    _cancelToken = CancelToken();
    File? tempFile;

    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempPath = '${tempDir.path}/survey_video_$timestamp.mp4';
      tempFile = File(tempPath);

      if (url.startsWith('http://') || url.startsWith('https://')) {
        // 1. Fast path: Check if already stored in cache
        final cachedFileInfo = await DefaultCacheManager().getFileFromCache(url);
        if (cachedFileInfo != null && await cachedFileInfo.file.exists()) {
          if (mounted) {
            setState(() {
              _downloadProgress = 1.0;
              _downloadProgressText = '100%';
            });
          }
          await cachedFileInfo.file.copy(tempPath);
        } else {
          // 2. High-speed network streaming download with progress tracking
          final dio = Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(minutes: 5),
            ),
          );

          await dio.download(
            url,
            tempPath,
            cancelToken: _cancelToken,
            onReceiveProgress: (received, total) {
              if (total > 0 && mounted) {
                final progress = (received / total).clamp(0.0, 1.0);
                setState(() {
                  _downloadProgress = progress;
                  _downloadProgressText = '${(progress * 100).toInt()}%';
                });
              }
            },
          );
        }
      } else {
        // Local file path
        final srcFile = File(url);
        if (await srcFile.exists()) {
          await srcFile.copy(tempPath);
        } else {
          throw Exception('Source video file does not exist.');
        }
      }

      if (!mounted) return;

      // Save video to native gallery album
      final bool? success = await GallerySaver.saveVideo(
        tempPath,
        albumName: widget.albumName,
      );

      if (mounted) {
        if (success == true) {
          AppSnackBar.showSuccess(
            context,
            'Video saved successfully to gallery (${widget.albumName})',
          );
        } else {
          AppSnackBar.showError(
            context,
            'Could not save video to gallery. Please check storage permissions.',
          );
        }
      }
    } on DioException catch (dioError) {
      if (!mounted) return;
      if (CancelToken.isCancel(dioError)) {
        AppSnackBar.showInfo(context, 'Download cancelled.');
      } else {
        AppSnackBar.showError(
          context,
          'Download failed: ${dioError.message ?? 'Network error'}. Tap to retry.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, 'Error saving video: ${e.toString()}');
    } finally {
      // Clean up temporary file to prevent duplicate storage bloat
      if (tempFile != null && await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
        });
      }
    }
  }

  void _cancelDownload() {
    _cancelToken?.cancel('Cancelled by user');
    setState(() {
      _isDownloading = false;
      _downloadProgress = 0.0;
    });
  }

  // ══════════════════════════════════════════════════════════════════════
  //  UI
  // ══════════════════════════════════════════════════════════════════════

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
                    widget.title ?? 'Video Player',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: responsive.sp(15.5),
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle!,
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
                ],
              ),
              actions: [
                if (widget.showDownloadButton)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _isDownloading
                        ? _DownloadingCircle(
                            progress: _downloadProgress,
                            onCancel: _cancelDownload,
                          )
                        : GlassCircleButton(
                            icon: Icons.download_rounded,
                            size: 40,
                            iconSize: 19,
                            iconColor: AppColors.gold,
                            semanticLabel: 'Save to Gallery',
                            onTap: _saveVideoToGallery,
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
    return GlassCard(
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
            'Loading video stream...',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadBanner() {
    return Semantics(
      liveRegion: true,
      label: 'Downloading to gallery',
      child: GlassCard(
        radius: 22,
        blur: 18,
        fillAlpha: 0.08,
        underlay: AppColors.surface.withValues(alpha: 0.78),
        padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
        child: Row(
          children: [
            const _IconBadge(
              icon: Icons.downloading_rounded,
              color: AppColors.gold,
              size: 38,
              iconSize: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Downloading to Gallery...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _downloadProgressText,
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
                      value: _downloadProgress > 0 ? _downloadProgress : null,
                      backgroundColor: Colors.white.withValues(alpha: 0.10),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                      minHeight: 5,
                    ),
                  ),
                ],
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
              onPressed: _cancelDownload,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return _buildLoading();

    if (_hasError) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: _PlayerErrorPanel(
          title: 'Unable to play video',
          message: _errorMessage.isNotEmpty
              ? _errorMessage
              : 'Please check your connection and try again.',
          retryLabel: 'Retry Playback',
          onRetry: _initializePlayer,
        ),
      );
    }

    if (_chewieController != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: _VideoFrame(
          radius: 22,
          child: Chewie(controller: _chewieController!),
        ),
      );
    }

    return const SizedBox.shrink();
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
              child: Stack(
                children: [
                  Center(child: _buildContent()),

                  // Floating glass banner while a download is running
                  if (_isDownloading)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: _buildDownloadBanner(),
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

/// Rounded black frame with white hairline + soft gold-tinted glow.
class _VideoFrame extends StatelessWidget {
  final Widget child;
  final double radius;

  const _VideoFrame({required this.child, required this.radius});

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);

    return RepaintBoundary(
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: br,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.50),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.08),
              blurRadius: 40,
            ),
          ],
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: br,
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: child,
      ),
    );
  }
}

/// AppBar slot shown while saving: progress ring around a cancel (x) button.
class _DownloadingCircle extends StatelessWidget {
  final double progress;
  final VoidCallback onCancel;

  const _DownloadingCircle({required this.progress, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onCancel,
      scale: 0.92,
      semanticLabel: 'Cancel Download',
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Container(
            width: 40,
            height: 40,
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
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    value: progress > 0 ? progress : null,
                    strokeWidth: 2.2,
                    strokeCap: StrokeCap.round,
                    color: AppColors.gold,
                    backgroundColor: AppColors.gold.withValues(alpha: 0.18),
                  ),
                ),
                const Icon(
                  Icons.close_rounded,
                  size: 13,
                  color: AppColors.gold,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Error state used full-screen and inside the Chewie player.
/// `compact: true` = no card (already sits on black video frame).
class _PlayerErrorPanel extends StatelessWidget {
  final String title;
  final String? message;
  final String retryLabel;
  final VoidCallback onRetry;
  final bool compact;

  const _PlayerErrorPanel({
    required this.title,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _IconBadge(
          icon: Icons.videocam_off_rounded,
          color: AppColors.error,
          size: compact ? 60 : 76,
          iconSize: compact ? 28 : 34,
        ),
        SizedBox(height: compact ? 14 : 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: compact ? 16 : 18,
            letterSpacing: -0.3,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 8),
          Text(
            message!,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
        ],
        SizedBox(height: compact ? 16 : 22),
        SizedBox(
          width: compact ? 160 : double.infinity,
          child: GoldButton(
            label: retryLabel,
            icon: Icons.refresh_rounded,
            height: compact ? 44 : 48,
            shine: true,
            onTap: onRetry,
          ),
        ),
      ],
    );

    if (compact) return Center(child: body);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: GlassCard(
        radius: 28,
        blur: 20,
        fillAlpha: 0.08,
        edgeTint: AppColors.error,
        underlay: AppColors.surface.withValues(alpha: 0.72),
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
        child: body,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  EMBEDDABLE PLAYER
// ════════════════════════════════════════════════════════════════════════════

/// Standalone Embeddable Video Player Widget for cards or custom layouts
class AppVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final double aspectRatio;
  final bool autoPlay;
  final bool looping;
  final bool showControls;
  final VoidCallback? onVideoEnd;

  const AppVideoPlayer({
    super.key,
    required this.videoUrl,
    this.aspectRatio = 16 / 9,
    this.autoPlay = false,
    this.looping = false,
    this.showControls = true,
    this.onVideoEnd,
  });

  @override
  State<AppVideoPlayer> createState() => _AppVideoPlayerState();
}

class _AppVideoPlayerState extends State<AppVideoPlayer> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void didUpdateWidget(covariant AppVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeControllers();
      _initPlayer();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    _chewieController = null;
    _videoPlayerController = null;
  }

  Future<void> _initPlayer() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final uri = Uri.parse(widget.videoUrl);
      final isNetwork = uri.isScheme('http') || uri.isScheme('https');

      _videoPlayerController = isNetwork
          ? VideoPlayerController.networkUrl(uri)
          : VideoPlayerController.file(File(widget.videoUrl));

      await _videoPlayerController!.initialize();

      if (!mounted) return;

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        aspectRatio: widget.aspectRatio,
        autoPlay: widget.autoPlay,
        looping: widget.looping,
        showControls: widget.showControls,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.gold,
          handleColor: AppColors.goldLight,
          bufferedColor: AppColors.gold.withValues(alpha: 0.35),
          backgroundColor: Colors.white.withValues(alpha: 0.14),
        ),
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(18);

    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: RepaintBoundary(
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: br,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.30),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: br,
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: _isLoading
              ? Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      strokeCap: StrokeCap.round,
                      color: AppColors.gold,
                      backgroundColor: AppColors.gold.withValues(alpha: 0.18),
                    ),
                  ),
                )
              : _hasError
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _IconBadge(
                            icon: Icons.videocam_off_rounded,
                            color: AppColors.error,
                            size: 48,
                            iconSize: 22,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Video unavailable',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: 120,
                            child: GlassButton(
                              label: 'Retry',
                              icon: Icons.refresh_rounded,
                              height: 38,
                              radius: 16,
                              onTap: _initPlayer,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _chewieController != null
                      ? Chewie(controller: _chewieController!)
                      : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
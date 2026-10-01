import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/app_theme_styles.dart';

class AnimationHelper {
  AnimationHelper._();

  /// Creates a smooth fade + slide route transition for screen navigation.
  static PageRouteBuilder<T> smoothRoute<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return PageRouteBuilder<T>(
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curveAnim = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curveAnim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(curveAnim),
            child: child,
          ),
        );
      },
    );
  }
}

/// Reusable widget that smoothly fades, slides, and scales content into view on load.
class SmoothEntranceAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Offset offset;
  final double scaleBegin;
  final Curve curve;

  const SmoothEntranceAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 850),
    this.delay = Duration.zero,
    this.offset = const Offset(0, 0.08),
    this.scaleBegin = 0.94,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<SmoothEntranceAnimation> createState() =>
      _SmoothEntranceAnimationState();
}

class _SmoothEntranceAnimationState extends State<SmoothEntranceAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    final curvedAnim = CurvedAnimation(
      parent: _animController,
      curve: widget.curve,
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnim);
    _slideAnim = Tween<Offset>(
      begin: widget.offset,
      end: Offset.zero,
    ).animate(curvedAnim);
    _scaleAnim = Tween<double>(
      begin: widget.scaleBegin,
      end: 1.0,
    ).animate(curvedAnim);

    if (widget.delay == Duration.zero) {
      _animController.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _animController.forward();
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: ScaleTransition(scale: _scaleAnim, child: widget.child),
      ),
    );
  }
}

/// Apple-styled Glassmorphism Container with BackdropFilter blur.
class AppleGlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final BorderRadiusGeometry? customBorderRadius;
  final double blurSigma;
  final Color? surfaceColor;
  final Color? borderColor;

  const AppleGlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
    this.borderRadius = 28.0,
    this.customBorderRadius,
    this.blurSigma = 18.0,
    this.surfaceColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSurface =
        surfaceColor ?? AppColors.surfaceElevated.withValues(alpha: 0.65);
    final border = customBorderRadius ?? BorderRadius.circular(borderRadius);

    return Container(
      decoration: BoxDecoration(
        borderRadius: border,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 32,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: border,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: effectiveSurface,
              borderRadius: border,
              border: borderColor != null
                  ? Border.all(color: borderColor!, width: 1.2)
                  : Border.all(color: AppColors.border.withValues(alpha: 0.8), width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Background Ambient Glowing Orbs illuminating behind glass panels.
class AmbientBackgroundOrbs extends StatelessWidget {
  final Widget? child;

  const AmbientBackgroundOrbs({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top-Right Glowing Aura Orb
        Positioned(
          top: -60,
          right: -60,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withValues(alpha: 0.16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.20),
                  blurRadius: 100,
                  spreadRadius: 60,
                ),
              ],
            ),
          ),
        ),
        // Bottom-Left Glowing Aura Orb
        Positioned(
          bottom: -80,
          left: -80,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.goldDark.withValues(alpha: 0.14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.goldDark.withValues(alpha: 0.18),
                  blurRadius: 120,
                  spreadRadius: 80,
                ),
              ],
            ),
          ),
        ),
        ?child,
      ],
    );
  }
}

/// Animated widget for staggered appearance of individual form elements.
class StaggeredItemAnimation extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration baseDelay;
  final Duration stepDelay;
  final Duration duration;
  final Offset offset;

  const StaggeredItemAnimation({
    super.key,
    required this.index,
    required this.child,
    this.baseDelay = const Duration(milliseconds: 150),
    this.stepDelay = const Duration(milliseconds: 70),
    this.duration = const Duration(milliseconds: 600),
    this.offset = const Offset(0, 0.15),
  });

  @override
  State<StaggeredItemAnimation> createState() => _StaggeredItemAnimationState();
}

class _StaggeredItemAnimationState extends State<StaggeredItemAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    final curvedAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnim);
    _slideAnim = Tween<Offset>(
      begin: widget.offset,
      end: Offset.zero,
    ).animate(curvedAnim);

    final totalDelay = widget.baseDelay + (widget.stepDelay * widget.index);
    Future.delayed(totalDelay, () {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(position: _slideAnim, child: widget.child),
    );
  }
}

/// Fade animation helper for backward compatibility
class AppFadeAnimation extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset slideOffset;

  const AppFadeAnimation({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
    this.slideOffset = const Offset(0, 20),
  });

  @override
  Widget build(BuildContext context) {
    return SmoothEntranceAnimation(
      delay: delay,
      duration: duration,
      offset: Offset(slideOffset.dx / 100, slideOffset.dy / 100),
      child: child,
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/app_theme_styles.dart';
import 'glass_kit.dart';

/// Route helpers.
class AnimationHelper {
  AnimationHelper._();

  /// Smooth fade + slide route transition.
  static PageRouteBuilder<T> smoothRoute<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return PageRouteBuilder<T>(
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curve,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.04),
              end: Offset.zero,
            ).animate(curve),
            child: child,
          ),
        );
      },
    );
  }
}

/// Fade + slide + scale into view on first build.
/// Timer (cancelled in dispose) replaces Future.delayed.
/// Respects the OS "remove animations" setting.
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
    this.duration = const Duration(milliseconds: 700),
    this.delay = Duration.zero,
    this.offset = const Offset(0, -0.06),
    this.scaleBegin = 0.96,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<SmoothEntranceAnimation> createState() =>
      _SmoothEntranceAnimationState();
}

class _SmoothEntranceAnimationState extends State<SmoothEntranceAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;
  Timer? _timer;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curved = CurvedAnimation(parent: _controller, curve: widget.curve);
    _fade = Tween<double>(begin: 0, end: 1).animate(curved);
    _slide = Tween<Offset>(begin: widget.offset, end: Offset.zero)
        .animate(curved);
    _scale = Tween<double>(begin: widget.scaleBegin, end: 1).animate(curved);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1; // show instantly
      return;
    }
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(
          scale: _scale,
          child: RepaintBoundary(child: widget.child),
        ),
      ),
    );
  }
}

/// Glass container. Same API, now built on GlassCard (one glass look
/// everywhere: gradient fill, specular edge, top highlight).
/// surfaceColor -> underlay, borderColor -> edge tint.
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
    return GlassCard(
      padding: padding,
      radius: borderRadius,
      borderRadius: customBorderRadius?.resolve(Directionality.of(context)),
      blur: blurSigma,
      underlay: surfaceColor,
      edgeTint: borderColor ?? AppColors.gold,
      child: child,
    );
  }
}

/// Ambient backdrop. Same API, now uses GlassAmbientBackground
/// (radial orbs + vignette). Old version used 100-blur BoxShadows,
/// very expensive to rasterize.
class AmbientBackgroundOrbs extends StatelessWidget {
  final Widget? child;

  const AmbientBackgroundOrbs({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(child: GlassAmbientBackground()),
        ?child,
      ],
    );
  }
}

/// Staggered appearance for form elements / grid items.
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
    this.baseDelay = const Duration(milliseconds: 60),
    this.stepDelay = const Duration(milliseconds: 55),
    this.duration = const Duration(milliseconds: 520),
    this.offset = const Offset(0, -0.16),
  });

  @override
  State<StaggeredItemAnimation> createState() => _StaggeredItemAnimationState();
}

class _StaggeredItemAnimationState extends State<StaggeredItemAnimation>
    with SingleTickerProviderStateMixin {
  static const Duration _maxDelay = Duration(milliseconds: 700);

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  Timer? _timer;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curved =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _fade = Tween<double>(begin: 0, end: 1).animate(curved);
    _slide = Tween<Offset>(begin: widget.offset, end: Offset.zero)
        .animate(curved);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }
    // Cap: item 20 must not wait 1.5s.
    var total = widget.baseDelay + widget.stepDelay * widget.index;
    if (total > _maxDelay) total = _maxDelay;
    _timer = Timer(total, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: RepaintBoundary(child: widget.child),
      ),
    );
  }
}

/// Universal fade and slide entrance animation widget.
class AppFadeAnimation extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;
  final Curve curve;

  const AppFadeAnimation({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 550),
    this.offset = const Offset(0, -0.06),
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return SmoothEntranceAnimation(
      delay: delay,
      duration: duration,
      offset: offset,
      curve: curve,
      child: child,
    );
  }
}
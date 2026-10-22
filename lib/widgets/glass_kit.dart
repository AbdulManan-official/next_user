import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme_styles.dart';
import '../utils/responsive_helper.dart';

// ═══════════════════════════════════════════════════════════════════════
//  GLASS KIT: values aligned 1:1 with SurveyorHomeView (reference UI)
// ═══════════════════════════════════════════════════════════════════════

// ── Backdrop ─────────────────────────────────────────────────────────────

/// Dark canvas + 3 light pools (gold / blue / gold). Same as home.
/// `vignette: true` darkens the edges (off by default, home has none).
class GlassAmbientBackground extends StatelessWidget {
  final bool vignette;
  const GlassAmbientBackground({super.key, this.vignette = false});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: AppColors.background),
            const Positioned(
              top: -130,
              right: -100,
              child: _Orb(size: 340, color: AppColors.gold, alpha: 0.26),
            ),
            const Positioned(
              top: 300,
              left: -160,
              child: _Orb(size: 320, color: Color(0xFF38BDF8), alpha: 0.11),
            ),
            const Positioned(
              bottom: -150,
              right: -70,
              child: _Orb(size: 360, color: AppColors.gold, alpha: 0.14),
            ),
            if (vignette)
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      radius: 1.15,
                      colors: [Color(0x00000000), Color(0x66000000)],
                      stops: [0.55, 1.0],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  final double alpha;
  const _Orb({required this.size, required this.color, required this.alpha});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

// ── Glass card ───────────────────────────────────────────────────────────

/// Frosted glass: blur + white gradient fill + gradient hairline edge.
/// Defaults = home `_GlassPanel` (radius 28, blur 20, fillAlpha 0.07).
///
/// PERF: `blur: 0` skips BackdropFilter (use inside long lists).
/// `edgeTint` colours the bottom-right glow of the border (status colours).
/// `highlight: true` adds a thin specular line on the top edge (off = home).
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final BorderRadius? borderRadius;
  final double blur;
  final double fillAlpha;
  final bool tintGold;
  final bool shadow;
  final bool highlight;
  final Color? underlay;
  final Color edgeTint;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 28,
    this.borderRadius,
    this.blur = 20,
    this.fillAlpha = 0.07,
    this.tintGold = false,
    this.shadow = true,
    this.highlight = false,
    this.underlay,
    this.edgeTint = AppColors.gold,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(radius);
    final base = tintGold ? AppColors.gold : Colors.white;

    Widget body = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: underlay,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            base.withValues(alpha: fillAlpha + 0.05),
            base.withValues(alpha: fillAlpha * 0.45),
          ],
        ),
      ),
      child: child,
    );

    if (blur > 0) {
      body = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: body,
      );
    }

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: br,
          boxShadow: shadow
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 32,
                    offset: const Offset(0, 14),
                  ),
                ]
              : null,
        ),
        child: CustomPaint(
          foregroundPainter: _GlassEdgePainter(
            borderRadius: br,
            tint: edgeTint,
            highlight: highlight,
          ),
          child: ClipRRect(
            borderRadius: br,
            clipBehavior: Clip.antiAlias,
            child: body,
          ),
        ),
      ),
    );
  }
}

/// 1px gradient stroke: white specular top-left → fade → tint glow
/// bottom-right. Same 4 stops as home.
class _GlassEdgePainter extends CustomPainter {
  final BorderRadius borderRadius;
  final Color tint;
  final bool highlight;

  const _GlassEdgePainter({
    required this.borderRadius,
    required this.tint,
    required this.highlight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(0.5);
    final rrect = borderRadius.toRRect(rect);

    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.42),
            Colors.white.withValues(alpha: 0.06),
            tint.withValues(alpha: 0.05),
            tint.withValues(alpha: 0.34),
          ],
          stops: const [0.0, 0.38, 0.68, 1.0],
        ).createShader(rect),
    );

    if (highlight) {
      final inset = math.min(borderRadius.topLeft.x, size.width / 3) + 4;
      final lineW = size.width - inset * 2;
      if (lineW > 12) {
        canvas.drawLine(
          Offset(inset, 1.5),
          Offset(size.width - inset, 1.5),
          Paint()
            ..strokeWidth = 1
            ..strokeCap = StrokeCap.round
            ..shader = LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.0),
                Colors.white.withValues(alpha: 0.38),
                Colors.white.withValues(alpha: 0.0),
              ],
            ).createShader(Rect.fromLTWH(inset, 0, lineW, 2)),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GlassEdgePainter old) =>
      old.borderRadius != borderRadius ||
      old.tint != tint ||
      old.highlight != highlight;
}

// ── Chip + circle button ────────────────────────────────────────────────

/// Small frosted pill for badges over imagery.
class GlassChip extends StatelessWidget {
  final Widget child;
  const GlassChip({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Round frosted icon button. Press-scale + haptic, min 44 tap target.
class GlassCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;
  final Color iconColor;
  final String semanticLabel;

  const GlassCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.size = 44,
    this.iconSize = 22,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final hit = math.max(size, 44.0);

    return Pressable(
      onTap: onTap,
      scale: 0.9,
      semanticLabel: semanticLabel,
      child: SizedBox(
        width: hit,
        height: hit,
        child: Center(
          child: RepaintBoundary(
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  width: size,
                  height: size,
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
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Icon(icon, size: iconSize, color: iconColor),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Buttons ──────────────────────────────────────────────────────────────

/// Primary CTA. Gold gradient (3-stop, same as home avatar / icon tiles),
/// white edge, gold glow. `shine: true` adds a glass top-light (off = home).
/// `isLoading` → spinner, taps blocked. `onTap == null` → dimmed.
class GoldButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool shine;
  final double height;
  final double radius;

  const GoldButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.isLoading = false,
    this.shine = false,
    this.height = 46,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    final enabled = onTap != null && !isLoading;
    final dimmed = onTap == null && !isLoading;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Pressable(
        onTap: enabled ? onTap : null,
        scale: 0.97,
        child: AnimatedOpacity(
          opacity: dimmed ? 0.5 : 1,
          duration: const Duration(milliseconds: 200),
          child: RepaintBoundary(
            child: Container(
              height: height,
              decoration: BoxDecoration(
                borderRadius: r,
                gradient: const LinearGradient(
                  colors: AppColors.goldGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.38),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: r,
                child: Stack(
                  children: [
                    if (shine)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        height: height * 0.45,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: 0.32),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: isLoading
                            ? SizedBox(
                                key: const ValueKey('loading'),
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  strokeCap: StrokeCap.round,
                                  color: AppColors.textOnGold,
                                  backgroundColor:
                                      AppColors.textOnGold.withValues(alpha: 0.22),
                                ),
                              )
                            : Padding(
                                key: const ValueKey('label'),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: _ButtonContent(
                                  label: label,
                                  icon: icon,
                                  color: AppColors.textOnGold,
                                  weight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary action: translucent glass pill with gold hairline.
class GlassButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isLoading;
  final double height;
  final double radius;

  const GlassButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.isLoading = false,
    this.height = 46,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !isLoading;
    final dimmed = onTap == null && !isLoading;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Pressable(
        onTap: enabled ? onTap : null,
        scale: 0.97,
        child: AnimatedOpacity(
          opacity: dimmed ? 0.5 : 1,
          duration: const Duration(milliseconds: 200),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isLoading
                    ? const SizedBox(
                        key: ValueKey('loading'),
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.gold,
                        ),
                      )
                    : Padding(
                        key: const ValueKey('label'),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: _ButtonContent(
                          label: label,
                          icon: icon,
                          color: AppColors.gold,
                          weight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final FontWeight weight;

  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.color,
    required this.weight,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(
              label,
              maxLines: 1,
              style: AppTextStyles.labelLarge.copyWith(
                color: color,
                fontWeight: weight,
                fontSize: 13,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────

/// Tactile press: scale-down + light haptic. Null onTap = inert passthrough.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool haptic;
  final String? semanticLabel;

  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.96,
    this.haptic = true,
    this.semanticLabel,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final onTap = widget.onTap;
    if (onTap == null) return widget.child;

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapCancel: () => _set(false),
        onTapUp: (_) {
          _set(false);
          if (widget.haptic) HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedScale(
          scale: _down ? widget.scale : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Hairline divider (flat white 0.09, same as home legend divider).
class GlassHairline extends StatelessWidget {
  const GlassHairline({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.8,
      color: Colors.white.withValues(alpha: 0.09),
    );
  }
}

/// Tinted status pill (Selected / Required / Completed ...).
class StatusPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final double fontSize;

  const StatusPill({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.fontSize = 10.5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: fontSize,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dashed rounded-rect stroke (upload drop zones).
class DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double dash;
  final double gap;
  final double strokeWidth;

  const DashedRRectPainter({
    required this.color,
    this.radius = 18,
    this.dash = 6,
    this.gap = 5,
    this.strokeWidth = 1.2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    ).deflate(strokeWidth / 2);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + dash, metric.length)),
          paint,
        );
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedRRectPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.dash != dash ||
      old.gap != gap ||
      old.strokeWidth != strokeWidth;
}

// ═══════════════════════════════════════════════════════════════════════
//  NX LUXURY GLASS SUITE (Profile & Home Shared Design System)
// ═══════════════════════════════════════════════════════════════════════

/// Ambient luxury dark background with glowing gold and cyan orbs.
class NxAmbientBackground extends StatelessWidget {
  final bool vignette;
  const NxAmbientBackground({super.key, this.vignette = false});

  @override
  Widget build(BuildContext context) {
    return GlassAmbientBackground(vignette: vignette);
  }
}

/// Frosted glass panel with specular hairline border, gradient fill & optional tint.
class NxGlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final double fillAlpha;
  final Color tint;

  const NxGlassPanel({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 28,
    this.blur = 16,
    this.fillAlpha = 0.08,
    this.tint = AppColors.gold,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);

    final surface = CustomPaint(
      foregroundPainter: _NxGlassBorderPainter(borderRadius: br, tint: tint),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: br,
          color: AppColors.background.withValues(alpha: 0.85),
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: br,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (tint == AppColors.gold ? AppColors.gold : Colors.white)
                    .withValues(alpha: fillAlpha + 0.05),
                (tint == AppColors.gold ? AppColors.gold : Colors.white)
                    .withValues(alpha: fillAlpha * 0.45),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: br,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: br,
          child: blur > 0
              ? BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                  child: surface,
                )
              : surface,
        ),
      ),
    );
  }
}

class _NxGlassBorderPainter extends CustomPainter {
  const _NxGlassBorderPainter({required this.borderRadius, required this.tint});

  final BorderRadius borderRadius;
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(0.5);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.42),
          Colors.white.withValues(alpha: 0.06),
          tint.withValues(alpha: 0.05),
          tint.withValues(alpha: 0.34),
        ],
        stops: const [0.0, 0.38, 0.68, 1.0],
      ).createShader(rect);
    canvas.drawRRect(borderRadius.toRRect(rect), paint);
  }

  @override
  bool shouldRepaint(covariant _NxGlassBorderPainter old) =>
      old.borderRadius != borderRadius || old.tint != tint;
}

/// Ultra-delicate translucent hairline divider.
class NxHairline extends StatelessWidget {
  final double indent;
  final double endIndent;
  final Color? color;

  const NxHairline({
    super.key,
    this.indent = 0,
    this.endIndent = 0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: indent, right: endIndent),
      height: 0.8,
      color: color ?? Colors.white.withValues(alpha: 0.09),
    );
  }
}

/// Tactile pressable container with haptic feedback and smooth scaling.
typedef NxPressable = Pressable;

/// Section title with uppercase tracking and gold overline style.
class NxSectionTitle extends StatelessWidget {
  final String text;
  const NxSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.overline.copyWith(
        color: AppColors.textMuted,
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.8,
      ),
    );
  }
}

/// Golden glowing icon tile for settings and luxury list items.
class NxGoldIconTile extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final double radius;
  final Color? iconColor;

  const NxGoldIconTile({
    super.key,
    required this.icon,
    this.size = 40,
    this.iconSize = 19,
    this.radius = 13,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF352618),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.4),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.16),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: iconColor ?? AppColors.goldLight,
        size: iconSize,
      ),
    );
  }
}

/// Luxury frosted glass bottom sheet wrapper with pill handle, title & subtitle.
class NxSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const NxSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(22, 16, 22, bottomInset + 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.titleLarge.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.textMuted,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

/// Helper method to display a luxury frosted glass bottom sheet.
Future<T?> showNxSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.65),
    builder: builder,
  );
}

/// Group of settings tiles wrapped in an NxGlassPanel with hairline dividers.
class NxSettingsGroup extends StatelessWidget {
  const NxSettingsGroup({
    super.key,
    required this.title,
    required this.tiles,
    this.radius = 26,
    this.fillAlpha = 0.08,
  });

  final String title;
  final List<Widget> tiles;
  final double radius;
  final double fillAlpha;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      children.add(tiles[i]);
      if (i != tiles.length - 1) {
        children.add(NxHairline(indent: context.w(68)));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: context.w(2)),
          child: NxSectionTitle(title),
        ),
        SizedBox(height: context.h(10)),
        NxGlassPanel(
          radius: radius,
          fillAlpha: fillAlpha,
          child: Column(children: children),
        ),
      ],
    );
  }
}

/// Interactive row for settings and account menus with golden icon, title, subtitle & trailing.
class NxSettingsTile extends StatelessWidget {
  const NxSettingsTile({
    super.key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return NxPressable(
      scale: 0.985,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(14),
          vertical: context.h(12),
        ),
        child: Row(
          children: [
            NxGoldIconTile(
              icon: icon,
              size: context.r(40),
              iconSize: context.r(19),
              radius: 13,
            ),
            SizedBox(width: context.w(14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: context.sp(14),
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                    ),
                  ),
                  SizedBox(height: context.h(2)),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      fontSize: context.sp(11.5),
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                  size: context.r(20),
                ),
          ],
        ),
      ),
    );
  }
}

/// Compact gold statistic column (e.g., "PLATINUM" / "Tier", "0" / "Active").
class NxMiniStat extends StatelessWidget {
  const NxMiniStat({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.gold,
              fontSize: context.sp(17),
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: context.h(2)),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontSize: context.sp(10.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small status badge chip for auth methods (Email, Phone, Google).
class NxMethodChip extends StatelessWidget {
  const NxMethodChip({
    super.key,
    required this.label,
    required this.icon,
    required this.linked,
  });

  final String label;
  final IconData icon;
  final bool linked;

  @override
  Widget build(BuildContext context) {
    final color = linked ? AppColors.gold : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: linked
            ? AppColors.gold.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: linked
              ? AppColors.gold.withValues(alpha: 0.38)
              : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontSize: context.sp(11),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (linked) ...[
            const SizedBox(width: 5),
            Icon(Icons.check_circle_rounded, size: 12, color: color),
          ],
        ],
      ),
    );
  }
}

/// Glass prompt card with action button (e.g. "Link phone/email").
class NxLinkPrompt extends StatelessWidget {
  const NxLinkPrompt({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.onLink,
    this.actionLabel = 'Link',
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onLink;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return NxGlassPanel(
      radius: 18,
      fillAlpha: 0.08,
      padding: EdgeInsets.all(context.r(14)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gold, size: 22),
          SizedBox(width: context.w(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: context.h(2)),
                Text(
                  message,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onLink,
            child: Text(
              actionLabel,
              style: const TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Luxury rounded badge pill (e.g. "DEFAULT", "ID: NX-88219", etc.).
class NxBadge extends StatelessWidget {
  const NxBadge({
    super.key,
    required this.text,
    this.color = AppColors.gold,
    this.fontSize,
    this.letterSpacing = 0.5,
  });

  final String text;
  final Color color;
  final double? fontSize;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontSize: fontSize ?? context.sp(10),
          fontWeight: FontWeight.w800,
          letterSpacing: letterSpacing,
        ),
      ),
    );
  }
}
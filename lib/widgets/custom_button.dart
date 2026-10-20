import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../utils/app_theme_styles.dart';
import 'glass_kit.dart';

enum ButtonVariant { primary, secondary, outlined, danger }

/// Luxury gold glass button.
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final dynamic icon;
  final double? width;
  final double height;
  final Color? backgroundColor;
  final ButtonVariant variant;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 54,
    this.backgroundColor,
    this.variant = ButtonVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final dimmed = onPressed == null && !isLoading;

    final isOutlined = variant == ButtonVariant.outlined;
    final isDanger = variant == ButtonVariant.danger;

    final base = backgroundColor ?? (isDanger ? AppColors.error : null);
    final glow = isOutlined ? Colors.transparent : (base ?? AppColors.gold);
    final colors = isOutlined
        ? [Colors.transparent, Colors.transparent]
        : base == null
            ? AppColors.goldGradient
            : [Color.lerp(base, Colors.white, 0.18)!, base, base];
    final fg = isOutlined
        ? AppColors.gold
        : base == null
            ? AppColors.textOnGold
            : (ThemeData.estimateBrightnessForColor(base) == Brightness.dark
                ? Colors.white
                : AppColors.textOnGold);

    const radius = 18.0;

    return Semantics(
      button: true,
      enabled: enabled,
      label: text,
      child: SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: Pressable(
          onTap: enabled ? onPressed : null, // blocked while loading
          scale: 0.97,
          child: AnimatedOpacity(
            opacity: dimmed ? 0.5 : 1,
            duration: const Duration(milliseconds: 200),
            child: RepaintBoundary(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                  ),
                  border: isOutlined
                      ? Border.all(
                          color: AppColors.gold.withValues(alpha: 0.7),
                          width: 1.5,
                        )
                      : Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                  boxShadow: isOutlined
                      ? null
                      : [
                          BoxShadow(
                            color: glow.withValues(alpha: 0.38),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: Stack(
                    children: [
                      // Top glass light
                      if (!isOutlined)
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
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.6,
                                    strokeCap: StrokeCap.round,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(fg),
                                    backgroundColor:
                                        fg.withValues(alpha: 0.22),
                                  ),
                                )
                              : Padding(
                                  key: const ValueKey('label'),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (icon != null) ...[
                                        if (icon is Widget)
                                          icon as Widget
                                        else if (icon is FaIconData)
                                          FaIcon(icon as FaIconData, color: fg, size: 18)
                                        else if (icon is IconData)
                                          Icon(icon as IconData, color: fg, size: 20),
                                        const SizedBox(width: 10),
                                      ],
                                      Flexible(
                                         child: FittedBox(
                                           fit: BoxFit.scaleDown,
                                           alignment: Alignment.center,
                                           child: Text(
                                          text,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.button.copyWith(
                                            color: fg,
                                               fontSize: 14,
                                               letterSpacing: 0.2,
                                            fontWeight: FontWeight.w800,
                                           ),
                                         ),
                                        ),
                                      ),
                                    ],
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
      ),
    );
  }
}
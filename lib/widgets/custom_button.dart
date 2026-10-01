import 'package:flutter/material.dart';
import '../utils/app_theme_styles.dart';

enum ButtonVariant { primary, outlined, text, danger }

/// Reusable premium styled button with gradient, loading state, and icons.
class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.height = 52,
    this.width = double.infinity,
    this.borderRadius = 14,
    this.textStyle,
  });

  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final bool isDisabled;
  final Widget? icon;
  final double height;
  final double width;
  final double borderRadius;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final bool active = !isDisabled && !isLoading && onPressed != null;

    if (variant == ButtonVariant.outlined) {
      return SizedBox(
        width: width,
        height: height,
        child: OutlinedButton(
          onPressed: active ? onPressed : null,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: active ? AppColors.gold : AppColors.border,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: _buildContent(
            textColor: active ? AppColors.gold : AppColors.textMuted,
          ),
        ),
      );
    }

    if (variant == ButtonVariant.text) {
      return SizedBox(
        width: width,
        height: height,
        child: TextButton(
          onPressed: active ? onPressed : null,
          child: _buildContent(
            textColor: active ? AppColors.gold : AppColors.textMuted,
          ),
        ),
      );
    }

    if (variant == ButtonVariant.danger) {
      return SizedBox(
        width: width,
        height: height,
        child: ElevatedButton(
          onPressed: active ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: active ? AppColors.error : AppColors.surfaceElevated,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            elevation: 0,
          ),
          child: _buildContent(textColor: Colors.white),
        ),
      );
    }

    // Default: Primary Gold Gradient
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: active ? AppColors.goldGradient : null,
        color: active ? null : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: active ? onPressed : null,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Center(
            child: _buildContent(
              textColor: active ? AppColors.textOnGold : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent({required Color textColor}) {
    if (isLoading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    }

    final effectiveStyle = (textStyle ?? AppTextStyles.labelLarge).copyWith(
      color: textColor,
    );

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          const SizedBox(width: 8),
          Text(text, style: effectiveStyle),
        ],
      );
    }

    return Text(text, style: effectiveStyle);
  }
}

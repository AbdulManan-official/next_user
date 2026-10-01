import 'package:flutter/material.dart';
import '../utils/app_theme_styles.dart';

enum ButtonVariant { primary, outlined, text, danger }

/// Luxury gradient primary button supporting loading spinner, icon,
/// and responsive font scaling.
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final dynamic icon; // IconData or Widget
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
    final isDisabled = onPressed == null || isLoading;

    if (variant == ButtonVariant.outlined) {
      return SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: isDisabled ? AppColors.border : AppColors.gold,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _buildChild(
            isDisabled ? AppColors.textMuted : AppColors.gold,
          ),
        ),
      );
    }

    if (variant == ButtonVariant.danger) {
      return SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDisabled ? AppColors.surfaceElevated : AppColors.error,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: _buildChild(Colors.white),
        ),
      );
    }

    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: isDisabled
            ? null
            : const LinearGradient(
                colors: AppColors.goldGradient,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        color: isDisabled ? AppColors.surfaceElevated : null,
        boxShadow: isDisabled
            ? null
            : [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: _buildChild(
                isDisabled ? AppColors.textMuted : AppColors.textOnGold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChild(Color textColor) {
    if (isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    }

    Widget? iconWidget;
    if (icon is IconData) {
      iconWidget = Icon(icon as IconData, color: textColor, size: 20);
    } else if (icon is Widget) {
      iconWidget = IconTheme(
        data: IconThemeData(color: textColor, size: 20),
        child: icon as Widget,
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (iconWidget != null) ...[
          iconWidget,
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.button.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

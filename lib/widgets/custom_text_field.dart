import 'package:flutter/material.dart';
import '../utils/app_theme_styles.dart';

/// Reusable text field component with embedded icons, error validation,
/// scrollPadding support and native keyboard action handling.
class CustomTextField extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final dynamic prefixIcon; // Accepts IconData or Widget
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final EdgeInsets scrollPadding;
  final Color? fillColor;

  const CustomTextField({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.scrollPadding = const EdgeInsets.only(bottom: 120),
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget? builtPrefixIcon;
    if (prefixIcon is IconData) {
      builtPrefixIcon = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Icon(
          prefixIcon as IconData,
          color: AppColors.gold,
          size: 22,
        ),
      );
    } else if (prefixIcon is Widget) {
      builtPrefixIcon = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: IconTheme(
          data: const IconThemeData(color: AppColors.gold, size: 22),
          child: prefixIcon as Widget,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          enabled: enabled,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          scrollPadding: scrollPadding,
          onTapOutside: (event) {
            FocusScope.of(context).unfocus();
          },
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textPrimary,
          ),
          cursorColor: AppColors.gold,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTextStyles.hint,
            filled: true,
            fillColor: fillColor ?? AppColors.surfaceElevated,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            prefixIcon: builtPrefixIcon,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error, width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../utils/app_theme_styles.dart';

/// Reusable text field component with embedded icons (Material & FontAwesome),
/// error validation, scrollPadding support and native keyboard action handling.
class CustomTextField extends StatelessWidget {
  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final dynamic prefixIcon;
  final dynamic suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;
  final bool readOnly;
  final bool canRequestFocus;
  final VoidCallback? onTap;
  final bool autofocus;
  final FocusNode? focusNode;
  final EdgeInsets scrollPadding;

  const CustomTextField({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.canRequestFocus = true,
    this.onTap,
    this.autofocus = false,
    this.focusNode,
    this.scrollPadding = const EdgeInsets.only(bottom: 120),
  });

  @override
  Widget build(BuildContext context) {
    Widget? effectivePrefix;
    if (prefixIcon is Widget) {
      effectivePrefix = prefixIcon as Widget;
    } else if (prefixIcon is FaIconData) {
      effectivePrefix = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Center(
          widthFactor: 1.0,
          child: FaIcon(prefixIcon as FaIconData, color: AppColors.gold, size: 18),
        ),
      );
    } else if (prefixIcon is IconData) {
      effectivePrefix = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Icon(prefixIcon as IconData, color: AppColors.gold, size: 22),
      );
    }

    Widget? effectiveSuffix;
    if (suffixIcon is Widget) {
      effectiveSuffix = suffixIcon as Widget;
    } else if (suffixIcon is FaIconData) {
      effectiveSuffix = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Center(
          widthFactor: 1.0,
          child: FaIcon(suffixIcon as FaIconData, color: AppColors.gold, size: 18),
        ),
      );
    } else if (suffixIcon is IconData) {
      effectiveSuffix = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Icon(suffixIcon as IconData, color: AppColors.gold, size: 22),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null && label!.isNotEmpty) ...[
          Text(
            label!,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          enabled: enabled,
          readOnly: readOnly,
          canRequestFocus: canRequestFocus,
          onTap: onTap,
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
            fillColor: AppColors.surfaceElevated,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            prefixIcon: effectivePrefix,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
            suffixIcon: effectiveSuffix,
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

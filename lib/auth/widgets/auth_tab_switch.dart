import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../utils/app_theme_styles.dart';

enum AuthMethod { email, phone }

/// Luxury sliding pill tab switch between Email and Phone sign-in methods.
class AuthTabSwitch extends StatelessWidget {
  final AuthMethod selectedMethod;
  final ValueChanged<AuthMethod> onMethodChanged;

  const AuthTabSwitch({
    super.key,
    required this.selectedMethod,
    required this.onMethodChanged,
  });

  static const double _height = 48;
  static const double _pad = 4;
  static const Duration _dur = Duration(milliseconds: 280);

  void _select(AuthMethod method) {
    if (method == selectedMethod) return;
    HapticFeedback.selectionClick();
    onMethodChanged(method);
  }

  @override
  Widget build(BuildContext context) {
    final isEmail = selectedMethod == AuthMethod.email;

    return RepaintBoundary(
      child: Container(
        height: _height,
        padding: const EdgeInsets.all(_pad),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.surface,
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            // Sliding gold indicator pill
            AnimatedAlign(
              duration: _dur,
              curve: Curves.easeInOutCubic,
              alignment: isEmail
                  ? AlignmentDirectional.centerStart
                  : AlignmentDirectional.centerEnd,
              child: const FractionallySizedBox(
                widthFactor: 0.5,
                heightFactor: 1,
                child: _PillIndicator(),
              ),
            ),
            // Clickable tab options
            Row(
              children: [
                Expanded(
                  child: _TabOption(
                    icon: FontAwesomeIcons.envelope,
                    label: 'Email',
                    selected: isEmail,
                    onTap: () => _select(AuthMethod.email),
                  ),
                ),
                Expanded(
                  child: _TabOption(
                    icon: FontAwesomeIcons.phone,
                    label: 'Phone',
                    selected: !isEmail,
                    onTap: () => _select(AuthMethod.phone),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PillIndicator extends StatelessWidget {
  const _PillIndicator();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.goldLight, AppColors.gold],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Align(
          alignment: Alignment.topCenter,
          child: FractionallySizedBox(
            heightFactor: 0.5,
            widthFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.3),
                    Colors.white.withValues(alpha: 0.0),
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

class _TabOption extends StatelessWidget {
  final dynamic icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = selected ? AppColors.textOnGold : AppColors.textSecondary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon is Widget)
              icon as Widget
            else if (icon is FaIconData)
              FaIcon(icon as FaIconData, size: 14, color: activeColor)
            else if (icon is IconData)
              Icon(icon as IconData, size: 14, color: activeColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: activeColor,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

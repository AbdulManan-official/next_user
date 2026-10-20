import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../utils/app_theme_styles.dart';

/// Ultra-Luxury Brand Header identical to the Reference UI specification.
/// Features a glowing gold circular emblem, official app logo asset,
/// overline tracker, ShaderMask gold gradient brand title, and descriptive subtitle.
class AuthHeader extends StatelessWidget {
  final String overline;
  final String title;
  final String subtitle;

  const AuthHeader({
    super.key,
    required this.overline,
    this.title = 'NEXT USER',
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Ultra-Luxury circular brand emblem matching user specification
        // Outer 2.5px radiant gold gradient border ring with warm gold halo glow
        RepaintBoundary(
          child: Container(
            width: 98,
            height: 98,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: AppColors.goldGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.38),
                  blurRadius: 30,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(2.5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF13161A),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/app_logo.png',
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFF13161A),
                    child: const Center(
                      child: FaIcon(
                        FontAwesomeIcons.truckFast,
                        color: AppColors.gold,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Overline text in gold letter spacing
        Text(
          overline.toUpperCase(),
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.gold,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.6,
          ),
        ),
        const SizedBox(height: 6),

        // Big ShaderMask brand title
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (rect) => const LinearGradient(
            colors: AppColors.goldGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(rect),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.displayMedium.copyWith(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: 3.0,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Subtitle description
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12.5,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

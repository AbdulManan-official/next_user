import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme_styles.dart';
import '../../widgets/animation_helper.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../widgets/auth_header.dart';

/// Ultra-Luxury Firebase Password Reset View for Next User.
/// Implements standard Firebase sendPasswordResetEmail flow with
/// top-to-bottom waterfall entrance animations, glassmorphism, and instant feedback.
class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  static final RegExp _emailRegExp =
      RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$');

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _linkSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleResetPassword() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      HapticFeedback.selectionClick();
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    final email = _emailController.text.trim();

    try {
      await AuthService.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _linkSent = true;
      });

      HapticFeedback.lightImpact();
      AppSnackBar.showSuccess(
        context,
        'Password reset link sent to $email. Please check your inbox or spam.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      HapticFeedback.heavyImpact();
      final errorMsg = AuthService.instance.getReadableErrorMessage(e);
      AppSnackBar.showError(context, errorMsg);
    }
  }

  void _handleResend() async {
    if (_isLoading) return;
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      await AuthService.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackBar.showSuccess(
        context,
        'A fresh password reset link has been sent to $email.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      HapticFeedback.heavyImpact();
      final errorMsg = AuthService.instance.getReadableErrorMessage(e);
      AppSnackBar.showError(context, errorMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: MediaQuery.withClampedTextScaling(
        minScaleFactor: 0.9,
        maxScaleFactor: 1.15,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Scaffold(
            backgroundColor: AppColors.background,
            resizeToAvoidBottomInset: true,
            body: Stack(
              children: [
                const Positioned.fill(
                  child: AmbientBackgroundOrbs(),
                ),
                SafeArea(
                  child: Stack(
                    children: [
                      CustomScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        slivers: [
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 68, 20, 24),
                              child: Center(
                                child: SmoothEntranceAnimation(
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 440),
                                    child: AppleGlassContainer(
                                      padding: const EdgeInsets.fromLTRB(
                                          24, 30, 24, 26),
                                      child: Form(
                                        key: _formKey,
                                        child: AnimatedSwitcher(
                                          duration:
                                              const Duration(milliseconds: 320),
                                          switchInCurve: Curves.easeOutCubic,
                                          switchOutCurve: Curves.easeInCubic,
                                          transitionBuilder: (child, anim) =>
                                              FadeTransition(
                                            opacity: anim,
                                            child: SlideTransition(
                                              position: Tween<Offset>(
                                                begin: const Offset(0, -0.06),
                                                end: Offset.zero,
                                              ).animate(anim),
                                              child: child,
                                            ),
                                          ),
                                          child: _linkSent
                                              ? _buildSuccessContent()
                                              : _buildFormContent(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Floating glass back button from reference UI
                      Positioned(
                        top: 12,
                        left: 16,
                        child: _GlassBackButton(
                          onTap: () => Navigator.maybePop(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent() {
    return Column(
      key: const ValueKey('fp_form_content'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 0. Header with gold circular emblem
        const StaggeredItemAnimation(
          index: 0,
          child: AuthHeader(
            overline: 'FORGOT PASSWORD',
            title: 'NEXT USER',
            subtitle:
                'Enter your email address below. We will send you instructions to reset your password.',
          ),
        ),
        const SizedBox(height: 24),

        // 1. Email Input Field
        StaggeredItemAnimation(
          index: 1,
          child: CustomTextField(
            label: 'Email',
            hintText: 'name@example.com',
            controller: _emailController,
            focusNode: _emailFocus,
            prefixIcon: FontAwesomeIcons.envelope,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleResetPassword(),
            validator: (v) {
              final val = v?.trim() ?? '';
              if (val.isEmpty) {
                return 'Please enter your email';
              }
              if (!_emailRegExp.hasMatch(val)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 24),

        // 2. Primary Action Button: RESET PASSWORD
        StaggeredItemAnimation(
          index: 2,
          child: CustomButton(
            text: 'RESET PASSWORD',
            icon: FontAwesomeIcons.paperPlane,
            isLoading: _isLoading,
            onPressed: _handleResetPassword,
          ),
        ),
        const SizedBox(height: 16),

        // 3. Secondary Link: Back to Sign In
        StaggeredItemAnimation(
          index: 3,
          child: Center(
            child: TextButton.icon(
              icon: const FaIcon(
                FontAwesomeIcons.arrowLeft,
                size: 12,
                color: AppColors.gold,
              ),
              label: Text(
                'Back to sign in',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              onPressed: () => Navigator.maybePop(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessContent() {
    final email = _emailController.text.trim();
    return Column(
      key: const ValueKey('fp_success_content'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 0. Header with gold circular emblem
        const StaggeredItemAnimation(
          index: 0,
          child: AuthHeader(
            overline: 'FORGOT PASSWORD',
            title: 'NEXT USER',
            subtitle:
                'A secure reset link has been dispatched to your email address.',
          ),
        ),
        const SizedBox(height: 20),

        // 1. Success Message Card
        StaggeredItemAnimation(
          index: 1,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold.withValues(alpha: 0.15),
                    border: Border.all(
                      color: AppColors.gold,
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: FaIcon(
                      FontAwesomeIcons.circleCheck,
                      color: AppColors.gold,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Check Your Inbox',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'We sent a password reset link to:',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please check your inbox (and spam folder) and click the link to choose a new password.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),

        // 2. Primary Return Button
        StaggeredItemAnimation(
          index: 2,
          child: CustomButton(
            text: 'BACK TO SIGN IN',
            icon: FontAwesomeIcons.arrowRightToBracket,
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        const SizedBox(height: 14),

        // 3. Resend Link Button
        StaggeredItemAnimation(
          index: 3,
          child: Center(
            child: TextButton.icon(
              icon: const FaIcon(
                FontAwesomeIcons.rotateRight,
                size: 12,
                color: AppColors.gold,
              ),
              label: Text(
                'Resend reset link',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: _isLoading ? null : _handleResend,
            ),
          ),
        ),
      ],
    );
  }
}

/// Floating glass back button identical to the reference UI specification.
class _GlassBackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _GlassBackButton({required this.onTap});

  @override
  State<_GlassBackButton> createState() => _GlassBackButtonState();
}

class _GlassBackButtonState extends State<_GlassBackButton> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapCancel: () => _set(false),
        onTapUp: (_) {
          _set(false);
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _down ? 0.90 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: FaIcon(
                FontAwesomeIcons.arrowLeft,
                color: AppColors.gold,
                size: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

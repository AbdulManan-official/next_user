import 'package:flutter/material.dart';
import '../../utils/app_theme_styles.dart';
import '../../widgets/animation_helper.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

/// Luxury Glassmorphism Forgot Password Screen for Next User.
class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  static final RegExp _emailRegExp =
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController =
      TextEditingController(text: 'test@gmail.com');
  bool _isLoading = false;
  String? _errorMessage;

  void _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    setState(() => _isLoading = false);

    AppSnackBar.showSuccess(
      context,
      'Password reset instructions have been sent to your email.',
    );

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withNoTextScaling(
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0C09),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.gold,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: AmbientBackgroundOrbs(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight > 48
                          ? constraints.maxHeight - 48
                          : 0,
                    ),
                    child: Center(
                      child: SmoothEntranceAnimation(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: AppleGlassContainer(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Item 0: Header Image / Icon circle with Gold Gradient
                                  StaggeredItemAnimation(
                                    index: 0,
                                    child: Center(
                                      child: Container(
                                        width: 96,
                                        height: 96,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const LinearGradient(
                                            colors: AppColors.goldGradient,
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.gold.withValues(
                                                alpha: 0.3,
                                              ),
                                              blurRadius: 20,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: ClipOval(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Image.asset(
                                              'assets/7.png',
                                              fit: BoxFit.contain,
                                              errorBuilder: (ctx, err, stack) =>
                                                  const Icon(
                                                Icons.lock_reset_rounded,
                                                color: AppColors.textOnGold,
                                                size: 44,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Item 1: App Title & Reset Instructions
                                  StaggeredItemAnimation(
                                    index: 1,
                                    child: Column(
                                      children: [
                                        Text(
                                          'NEXT USER',
                                          textAlign: TextAlign.center,
                                          style: AppTextStyles.displayMedium
                                              .copyWith(
                                            color: AppColors.gold,
                                            letterSpacing: 2.5,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 28,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'RESET PASSWORD',
                                          textAlign: TextAlign.center,
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Enter your registered email address below. We will send you instructions to reset your password.',
                                          textAlign: TextAlign.center,
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                            color: AppColors.textMuted,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Error Banner
                                  if (_errorMessage != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.error.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.error_outline_rounded,
                                            color: AppColors.error,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _errorMessage!,
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                color: AppColors.error,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],

                                  // Item 2: Email Input Field
                                  StaggeredItemAnimation(
                                    index: 2,
                                    child: CustomTextField(
                                      label: 'Email Address',
                                      hintText: 'name@example.com',
                                      controller: _emailController,
                                      prefixIcon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _handleReset(),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Please enter your email';
                                        }
                                        if (!_emailRegExp
                                            .hasMatch(value.trim())) {
                                          return 'Please enter a valid email address';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 28),

                                  // Item 3: Submit Action Button
                                  StaggeredItemAnimation(
                                    index: 3,
                                    child: CustomButton(
                                      text: 'SEND RESET LINK',
                                      icon: Icons.send_rounded,
                                      isLoading: _isLoading,
                                      onPressed: _handleReset,
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
              },
            ),
          ),
        ),
      ),
    );
  }
}

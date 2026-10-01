import 'package:flutter/material.dart';
import '../../utils/app_theme_styles.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/animation_helper.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/app_snack_bar.dart';
import '../../user_side/views/home_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void _handleLogin() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      AppSnackBar.showWarning(context, 'Please fill in all fields.');
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _isLoading = false);

    AppSnackBar.showSuccess(context, 'Welcome back!');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeView()),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(context.responsive.pagePadding),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: context.hp(90),
              maxWidth: context.responsive.maxContentWidth,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: context.hp(5)),
                AppFadeAnimation(
                  child: Center(
                    child: Container(
                      width: context.r(72),
                      height: context.r(72),
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.diamond_outlined,
                        color: AppColors.textOnGold,
                        size: 38,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: context.hp(4)),
                AppFadeAnimation(
                  delay: const Duration(milliseconds: 100),
                  child: Text(
                    'Welcome Back',
                    style: AppTextStyles.displayMedium.copyWith(
                      fontSize: context.sp(28),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                AppFadeAnimation(
                  delay: const Duration(milliseconds: 150),
                  child: Text(
                    'Sign in to your luxury experience account',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: context.sp(14),
                    ),
                  ),
                ),
                SizedBox(height: context.hp(4)),
                AppFadeAnimation(
                  delay: const Duration(milliseconds: 200),
                  child: CustomTextField(
                    controller: _emailController,
                    label: 'Email or Phone',
                    hintText: 'Enter your email or phone',
                    prefixIcon: const Icon(Icons.email_outlined),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(height: 16),
                AppFadeAnimation(
                  delay: const Duration(milliseconds: 250),
                  child: CustomTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hintText: 'Enter your password',
                    obscureText: true,
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      'Forgot Password?',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AppFadeAnimation(
                  delay: const Duration(milliseconds: 300),
                  child: CustomButton(
                    text: 'Sign In',
                    isLoading: _isLoading,
                    onPressed: _handleLogin,
                  ),
                ),
                SizedBox(height: context.hp(4)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

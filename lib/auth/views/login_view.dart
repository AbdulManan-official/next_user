import 'package:flutter/material.dart';
import '../../services/session_service.dart';
import '../../utils/app_theme_styles.dart';
import '../../widgets/animation_helper.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../controllers/login_controller.dart';
import '../../user_side/views/home_view.dart';
import 'forgot_password_view.dart';

/// Performance-optimized Login View with Apple Glassmorphism UI, Responsive Viewport Scroll & Keyboard Handling.
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with WidgetsBindingObserver {
  static final RegExp _emailRegExp =
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  late final LoginController _controller;
  late final FocusNode _emailFocusNode;
  late final FocusNode _passwordFocusNode;
  late final ScrollController _scrollController;
  final GlobalKey _passwordFieldKey = GlobalKey();
  final GlobalKey _emailFieldKey = GlobalKey();
  bool _kbOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = LoginController();
    _emailFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();
    _scrollController = ScrollController();

    // Auto-scroll when fields gain focus
    _passwordFocusNode.addListener(_onPasswordFocusChanged);
    _emailFocusNode.addListener(_onEmailFocusChanged);

    _checkExistingSession();
  }

  @override
  void didChangeMetrics() {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return;
    final bottom = views.first.viewInsets.bottom;
    final open = bottom > 0;

    if (_kbOpen && !open) {
      FocusManager.instance.primaryFocus?.unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
    if (_kbOpen != open) {
      setState(() => _kbOpen = open);
    }
  }

  void _onPasswordFocusChanged() {
    if (mounted) setState(() {});
    if (_passwordFocusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted || !_passwordFocusNode.hasFocus) return;
        final ctx = _passwordFieldKey.currentContext;
        if (ctx != null && ctx.mounted) {
          Scrollable.ensureVisible(
            ctx,
            alignment: 0.5,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  void _onEmailFocusChanged() {
    if (mounted) setState(() {});
    if (_emailFocusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted || !_emailFocusNode.hasFocus) return;
        final ctx = _emailFieldKey.currentContext;
        if (ctx != null && ctx.mounted) {
          Scrollable.ensureVisible(
            ctx,
            alignment: 0.5,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  Future<void> _checkExistingSession() async {
    if (SessionService.instance.isAuthenticated && mounted) {
      Navigator.pushReplacement(
        context,
        AnimationHelper.smoothRoute(page: const HomeView()),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _emailFocusNode.removeListener(_onEmailFocusChanged);
    _passwordFocusNode.removeListener(_onPasswordFocusChanged);
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final success = await _controller.login(context);
    if (!mounted) return;

    if (success) {
      AppSnackBar.showSuccess(
        context,
        'Signed in successfully!',
      );

      Navigator.pushReplacement(
        context,
        AnimationHelper.smoothRoute(page: const HomeView()),
      );
    } else if (_controller.errorMessage != null) {
      AppSnackBar.showError(context, _controller.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withNoTextScaling(
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0C09),
        resizeToAvoidBottomInset: true,
        body: AmbientBackgroundOrbs(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  controller: _scrollController,
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
                              key: _controller.formKey,
                              child: ListenableBuilder(
                                listenable: _controller,
                                builder: (context, _) {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // Item 0: Dynamic Header icon with smooth animated switcher
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
                                                  color: AppColors.gold
                                                      .withValues(alpha: 0.3),
                                                  blurRadius: 20,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: ClipOval(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Image.asset(
                                                  'assets/1.png',
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (ctx, err,
                                                          stack) =>
                                                      const Icon(
                                                    Icons.person_rounded,
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

                                      // Item 1: App Title & Subtitle
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
                                              'Sign in to access your user portal',
                                              textAlign: TextAlign.center,
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 24),

                                      // Item 2: Email Input Field
                                      StaggeredItemAnimation(
                                        index: 2,
                                        child: CustomTextField(
                                          key: _emailFieldKey,
                                          label: 'Email',
                                          hintText: 'name@example.com',
                                          controller:
                                              _controller.emailController,
                                          focusNode: _emailFocusNode,
                                          prefixIcon: Icons.email_outlined,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          textInputAction: TextInputAction.next,
                                          scrollPadding:
                                              const EdgeInsets.only(bottom: 80),
                                          onChanged: (_) =>
                                              _controller.clearErrorMessage(),
                                          onFieldSubmitted: (_) =>
                                              FocusScope.of(context)
                                                  .requestFocus(
                                                      _passwordFocusNode),
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
                                      const SizedBox(height: 16),

                                      // Item 3: Password Input Field
                                      StaggeredItemAnimation(
                                        index: 3,
                                        child: CustomTextField(
                                          key: _passwordFieldKey,
                                          label: 'Password',
                                          hintText: 'Enter your password',
                                          controller:
                                              _controller.passwordController,
                                          focusNode: _passwordFocusNode,
                                          prefixIcon:
                                              Icons.lock_outline_rounded,
                                          obscureText:
                                              !_controller.isPasswordVisible,
                                          textInputAction: TextInputAction.done,
                                          scrollPadding:
                                              const EdgeInsets.only(bottom: 80),
                                          onChanged: (_) =>
                                              _controller.clearErrorMessage(),
                                          onFieldSubmitted: (_) =>
                                              _handleLogin(),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Please enter your password';
                                            }
                                            if (value.length < 6) {
                                              return 'Password must be at least 6 characters';
                                            }
                                            return null;
                                          },
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _controller.isPasswordVisible
                                                  ? Icons.visibility_outlined
                                                  : Icons.visibility_off_outlined,
                                              color: AppColors.textMuted,
                                              size: 18,
                                            ),
                                            onPressed: _controller
                                                .togglePasswordVisibility,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),

                                      // Item 4: Forgot Password Link
                                      StaggeredItemAnimation(
                                        index: 4,
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                AnimationHelper.smoothRoute(
                                                  page:
                                                      const ForgotPasswordView(),
                                                ),
                                              );
                                            },
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: Size.zero,
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            child: Text(
                                              'Forgot password?',
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                color: AppColors.gold,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),

                                      // Item 5: Primary Submit Button
                                      StaggeredItemAnimation(
                                        index: 5,
                                        child: CustomButton(
                                          text: 'SIGN IN',
                                          icon: Icons.login_rounded,
                                          isLoading: _controller.isLoading,
                                          onPressed: _handleLogin,
                                        ),
                                      ),
                                    ],
                                  );
                                },
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

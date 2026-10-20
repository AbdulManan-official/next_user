import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/backend_sync_service.dart';
import '../../services/session_service.dart';
import '../../utils/app_theme_styles.dart';
import '../../views/bottom_tab_view.dart';
import '../../widgets/animation_helper.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../widgets/auth_divider.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_tab_switch.dart';
import '../widgets/otp_verification_view.dart';
import '../widgets/phone_input_field.dart';
import '../widgets/social_auth_buttons.dart';
import 'complete_profile_view.dart';
import 'forgot_password_view.dart';
import 'signup_view.dart';

/// Ultra-Luxury Login View for Next User.
/// Displays official assets/app_logo.png, UK phone default, professional copy, and live session state.
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with WidgetsBindingObserver {
  static final RegExp _emailRegExp =
      RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$');

  final GlobalKey<FormState> _emailFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _phoneFormKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();

  AuthMethod _authMethod = AuthMethod.email;
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isPhoneOtpStep = false;
  String? _verificationId;
  int? _resendToken;
  String _selectedDialCode = '+44';
  String _selectedIsoCode = 'GB';
  String _selectedCountryName = 'United Kingdom';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkExistingSession();
    });
  }

  Future<void> _checkExistingSession() async {
    if (SessionService.instance.isAuthenticated && mounted) {
      Navigator.pushReplacement(
        context,
        AnimationHelper.smoothRoute(page: const BottomTabView()),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();

    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _processAuthSuccess(
    User user, {
    required String loginType,
    required String login,
    String? name,
    String? email,
  }) async {
    final syncResult = await BackendSyncService.instance.syncUserWithBackend(
      loginType: loginType,
      login: login,
      firebaseUid: user.uid,
      name: name ?? user.displayName,
      email: email ?? user.email,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    final displayName = SessionService.instance.clientName.isNotEmpty
        ? SessionService.instance.clientName
        : (user.displayName ?? 'Valued Client');

    AppSnackBar.showSuccess(
      context,
      'Welcome back, $displayName!',
    );

    final isComplete = syncResult['is_profile_complete'] == true;
    if (!isComplete) {
      Navigator.pushReplacement(
        context,
        AnimationHelper.smoothRoute(page: const CompleteProfileView()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        AnimationHelper.smoothRoute(page: const BottomTabView()),
      );
    }
  }

  void _handleSignIn() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!(_authMethod == AuthMethod.email
        ? (_emailFormKey.currentState?.validate() ?? false)
        : (_phoneFormKey.currentState?.validate() ?? false))) {
      HapticFeedback.selectionClick();
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final credential = await AuthService.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;
      if (credential.user != null) {
        await _processAuthSuccess(
          credential.user!,
          loginType: 'email',
          login: email,
          email: email,
        );
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      HapticFeedback.heavyImpact();
      final errorMsg = AuthService.instance.getReadableErrorMessage(e);
      AppSnackBar.showError(context, errorMsg);
    }
  }

  void _handleSendPhoneOtp() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final rawPhone = _phoneController.text.trim();
    final cleanDigits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (cleanDigits.isEmpty) {
      HapticFeedback.heavyImpact();
      AppSnackBar.showError(context, 'Please enter your mobile number');
      return;
    }
    if (cleanDigits.length < 8) {
      HapticFeedback.heavyImpact();
      AppSnackBar.showError(context, 'Please enter a valid mobile number');
      return;
    }

    String fullPhoneNumber;
    if (rawPhone.startsWith('+')) {
      fullPhoneNumber = '+$cleanDigits';
    } else if (cleanDigits.startsWith('0')) {
      fullPhoneNumber = '$_selectedDialCode${cleanDigits.substring(1)}';
    } else {
      fullPhoneNumber = '$_selectedDialCode$cleanDigits';
    }

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      await AuthService.instance.verifyPhoneNumber(
        phoneNumber: fullPhoneNumber,
        resendToken: _resendToken,
        onCodeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _isLoading = false;
            _isPhoneOtpStep = true;
          });
          AppSnackBar.showSuccess(
            context,
            '6-digit verification code sent to $fullPhoneNumber',
          );
        },
        onVerificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          HapticFeedback.heavyImpact();
          final errorMsg = AuthService.instance.getReadableErrorMessage(e);
          AppSnackBar.showError(context, errorMsg);
        },
        onVerificationCompleted: (PhoneAuthCredential credential) async {
          if (!mounted) return;
          try {
            final userCred =
                await FirebaseAuth.instance.signInWithCredential(credential);
            if (userCred.user != null) {
              await _processAuthSuccess(
                userCred.user!,
                loginType: 'phone',
                login: fullPhoneNumber,
              );
            }
          } catch (_) {
            if (mounted) setState(() => _isLoading = false);
          }
        },
        onCodeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      HapticFeedback.heavyImpact();
      final errorMsg = AuthService.instance.getReadableErrorMessage(e);
      AppSnackBar.showError(context, errorMsg);
    }
  }

  void _handleVerifyPhoneOtp(String code) async {
    if (_verificationId == null) {
      AppSnackBar.showError(
        context,
        'Verification session expired. Please request a new code.',
      );
      setState(() => _isPhoneOtpStep = false);
      return;
    }

    final rawPhone = _phoneController.text.trim();
    final cleanDigits = rawPhone.replaceAll(RegExp(r'\D'), '');
    String fullPhoneNumber;
    if (rawPhone.startsWith('+')) {
      fullPhoneNumber = '+$cleanDigits';
    } else if (cleanDigits.startsWith('0')) {
      fullPhoneNumber = '$_selectedDialCode${cleanDigits.substring(1)}';
    } else {
      fullPhoneNumber = '$_selectedDialCode$cleanDigits';
    }

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      final credential = await AuthService.instance.verifyOtpAndSignIn(
        verificationId: _verificationId!,
        smsCode: code,
      );

      if (!mounted) return;
      if (credential.user != null) {
        final phone = credential.user?.phoneNumber ?? fullPhoneNumber;
        await _processAuthSuccess(
          credential.user!,
          loginType: 'phone',
          login: phone,
        );
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      HapticFeedback.heavyImpact();
      final errorMsg = AuthService.instance.getReadableErrorMessage(e);
      AppSnackBar.showError(context, errorMsg);
    }
  }

  void _handleResendOtp() {
    _handleSendPhoneOtp();
  }

  void _handleSocialSignIn(String provider) async {
    if (_isLoading) return;
    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);

    try {
      UserCredential? credential;
      if (provider.toLowerCase() == 'google') {
        credential = await AuthService.instance.signInWithGoogle();
      } else if (provider.toLowerCase() == 'apple') {
        credential = await AuthService.instance.signInWithApple();
      }

      if (!mounted) return;
      if (credential == null) {
        setState(() => _isLoading = false);
        return;
      }

      if (credential.user != null) {
        await _processAuthSuccess(
          credential.user!,
          loginType: provider.toLowerCase(),
          login: credential.user!.email ?? credential.user!.uid,
          name: credential.user!.displayName,
          email: credential.user!.email,
        );
      } else {
        setState(() => _isLoading = false);
      }
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
        child: Scaffold(
          backgroundColor: AppColors.background,
          resizeToAvoidBottomInset: true,
          body: AmbientBackgroundOrbs(
            child: SafeArea(
              child: CustomScrollView(
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      child: Center(
                        child: SmoothEntranceAnimation(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: AppleGlassContainer(
                              padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
                              child: Form(
                                key: _authMethod == AuthMethod.email
                                    ? _emailFormKey
                                    : _phoneFormKey,
                                child: AnimatedSize(
                                  duration: const Duration(milliseconds: 380),
                                  curve: Curves.easeInOutCubic,
                                  alignment: Alignment.topCenter,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // 0. Header with Glowing Ring and Real App Logo
                                      StaggeredItemAnimation(
                                        index: 0,
                                        child: _buildHeader(),
                                      ),
                                      const SizedBox(height: 22),

                                      // If in Phone OTP Step: Show 6-Digit OTP verification
                                      if (_isPhoneOtpStep) ...[
                                        StaggeredItemAnimation(
                                          index: 1,
                                          child: OtpVerificationStep(
                                            phoneNumber: '$_selectedDialCode ${_phoneController.text.trim().replaceFirst(RegExp(r"^0+"), "")}',
                                            countryIsoCode: _selectedIsoCode,
                                            countryName: _selectedCountryName,
                                            buttonText: 'VERIFY & SIGN IN',
                                            isLoading: _isLoading,
                                            onVerify: _handleVerifyPhoneOtp,
                                            onResend: _handleResendOtp,
                                            onChangeNumber: () {
                                              HapticFeedback.lightImpact();
                                              setState(() => _isPhoneOtpStep = false);
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Center(
                                          child: TextButton.icon(
                                            icon: const FaIcon(
                                              FontAwesomeIcons.arrowLeft,
                                              size: 12,
                                              color: AppColors.gold,
                                            ),
                                            label: Text(
                                              'Back to Sign In options',
                                              style: AppTextStyles.bodySmall.copyWith(
                                                color: AppColors.gold,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            onPressed: () {
                                              HapticFeedback.lightImpact();
                                              setState(() => _isPhoneOtpStep = false);
                                            },
                                          ),
                                        ),
                                      ] else ...[
                                        // 1. Method Toggle Switch (Email vs Phone)
                                        StaggeredItemAnimation(
                                          index: 1,
                                          child: AuthTabSwitch(
                                            selectedMethod: _authMethod,
                                            onMethodChanged: (method) {
                                              FocusManager.instance
                                                  .primaryFocus
                                                  ?.unfocus();
                                              setState(() {
                                                _authMethod = method;
                                                _isPhoneOtpStep = false;
                                                // Reset both forms to clear stale errors
                                                _emailFormKey.currentState
                                                    ?.reset();
                                                _phoneFormKey.currentState
                                                    ?.reset();
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 18),

                                        // 2. Dynamic Input Fields (Morphing smoothly between Email & Phone)
                                        AnimatedSize(
                                          duration:
                                              const Duration(milliseconds: 360),
                                          curve: Curves.easeInOutCubic,
                                          alignment: Alignment.topCenter,
                                          child: AnimatedSwitcher(
                                            duration:
                                                const Duration(milliseconds: 280),
                                            switchInCurve: Curves.easeOutCubic,
                                            switchOutCurve: Curves.easeInCubic,
                                            transitionBuilder: (child, anim) =>
                                                FadeTransition(
                                              opacity: CurvedAnimation(
                                                parent: anim,
                                                curve: const Interval(0.2, 1.0,
                                                    curve: Curves.easeOut),
                                              ),
                                              child: SlideTransition(
                                                position: Tween<Offset>(
                                                  begin: const Offset(0, -0.05),
                                                  end: Offset.zero,
                                                ).animate(CurvedAnimation(
                                                  parent: anim,
                                                  curve: Curves.easeOutCubic,
                                                )),
                                                child: child,
                                              ),
                                            ),
                                            child: _authMethod == AuthMethod.email
                                                ? Column(
                                                    key: const ValueKey(
                                                        'login_email_fields'),
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.stretch,
                                                    children: [
                                                      // Email field
                                                      CustomTextField(
                                                        key: const ValueKey(
                                                            'email_field'),
                                                        label: 'Email Address',
                                                        hintText:
                                                            'name@example.com',
                                                        controller:
                                                            _emailController,
                                                        focusNode: _emailFocus,
                                                        prefixIcon:
                                                            FontAwesomeIcons
                                                                .envelope,
                                                        keyboardType:
                                                            TextInputType
                                                                .emailAddress,
                                                        textInputAction:
                                                          TextInputAction.next,
                                                        onFieldSubmitted: (_) =>
                                                            _passwordFocus
                                                                .requestFocus(),
                                                        validator: (v) {
                                                          final val =
                                                              v?.trim() ?? '';
                                                          if (val.isEmpty) {
                                                            return 'Please enter your email';
                                                          }
                                                          if (!_emailRegExp
                                                              .hasMatch(val)) {
                                                            return 'Please enter a valid email address';
                                                          }
                                                          return null;
                                                        },
                                                      ),
                                                      const SizedBox(height: 14),

                                                      // Password field
                                                      CustomTextField(
                                                        label: 'Password',
                                                        hintText:
                                                            'Enter your password',
                                                        controller:
                                                          _passwordController,
                                                        focusNode:
                                                          _passwordFocus,
                                                        prefixIcon:
                                                            FontAwesomeIcons.lock,
                                                        obscureText:
                                                            !_isPasswordVisible,
                                                        textInputAction:
                                                          TextInputAction.done,
                                                        onFieldSubmitted: (_) =>
                                                            _handleSignIn(),
                                                        validator: (v) {
                                                          if (v == null ||
                                                              v.isEmpty) {
                                                            return 'Please enter your password';
                                                          }
                                                          if (v.length < 6) {
                                                            return 'Password must be at least 6 characters';
                                                          }
                                                          return null;
                                                        },
                                                        suffixIcon: IconButton(
                                                          icon: FaIcon(
                                                            _isPasswordVisible
                                                                ? FontAwesomeIcons
                                                                    .eye
                                                                : FontAwesomeIcons
                                                                    .eyeSlash,
                                                            color: AppColors
                                                                .textMuted,
                                                            size: 16,
                                                          ),
                                                          onPressed: () {
                                                            setState(() =>
                                                                _isPasswordVisible =
                                                                    !_isPasswordVisible);
                                                          },
                                                        ),
                                                      ),
                                                      const SizedBox(height: 10),

                                                      // Forgot Password Link
                                                      Align(
                                                        alignment: Alignment
                                                            .centerRight,
                                                        child: TextButton(
                                                          onPressed: () {
                                                            HapticFeedback
                                                                .lightImpact();
                                                            Navigator.push(
                                                              context,
                                                              AnimationHelper
                                                                  .smoothRoute(
                                                                page:
                                                                    const ForgotPasswordView(),
                                                              ),
                                                            );
                                                          },
                                                          style: TextButton
                                                              .styleFrom(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                              horizontal: 4,
                                                              vertical: 4,
                                                            ),
                                                            minimumSize:
                                                                Size.zero,
                                                            tapTargetSize:
                                                                MaterialTapTargetSize
                                                                    .shrinkWrap,
                                                          ),
                                                          child: Text(
                                                            'Forgot password?',
                                                            style: AppTextStyles
                                                                .bodySmall
                                                                .copyWith(
                                                              color:
                                                                  AppColors.gold,
                                                              fontWeight:
                                                                  FontWeight.w600,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 18),

                                                      // Email Sign-In Button
                                                      CustomButton(
                                                        text: 'SIGN IN',
                                                        icon: FontAwesomeIcons
                                                            .arrowRightToBracket,
                                                        isLoading: _isLoading,
                                                        onPressed: _handleSignIn,
                                                      ),
                                                    ],
                                                  )
                                                : Column(
                                                    key: const ValueKey(
                                                        'login_phone_fields'),
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.stretch,
                                                    children: [
                                                      // Phone input field (UK / PK selector)
                                                      PhoneInputField(
                                                        key: const ValueKey(
                                                            'phone_field'),
                                                        label: 'Mobile Number',
                                                        controller:
                                                            _phoneController,
                                                        focusNode: _phoneFocus,
                                                        textInputAction:
                                                            TextInputAction.done,
                                                        initialCountry: supportedCountries.firstWhere(
                                                          (c) => c.isoCode == _selectedIsoCode,
                                                          orElse: () => supportedCountries.first,
                                                        ),
                                                        onCountryChanged: (c) {
                                                          setState(() {
                                                            _selectedDialCode = c.dialCode;
                                                            _selectedIsoCode = c.isoCode;
                                                            _selectedCountryName = c.name;
                                                          });
                                                        },
                                                        onFieldSubmitted: (_) =>
                                                            _handleSendPhoneOtp(),
                                                        validator: (v) {
                                                          if (v == null ||
                                                              v.trim().isEmpty) {
                                                            return 'Please enter your mobile number';
                                                          }
                                                          return null;
                                                        },
                                                      ),
                                                      const SizedBox(height: 20),

                                                      // Get OTP via SMS Button
                                                      CustomButton(
                                                        text: 'GET OTP VIA SMS',
                                                        icon: FontAwesomeIcons
                                                            .paperPlane,
                                                        isLoading: _isLoading,
                                                        onPressed:
                                                            _handleSendPhoneOtp,
                                                      ),
                                                    ],
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(height: 22),

                                      // Divider
                                      const StaggeredItemAnimation(
                                        index: 6,
                                        child: AuthDivider(
                                          text: 'Or continue with',
                                        ),
                                      ),
                                      const SizedBox(height: 18),

                                      // Social Buttons (Google & Apple)
                                      StaggeredItemAnimation(
                                        index: 7,
                                        child: SocialAuthButtons(
                                          isLoading: _isLoading,
                                          onGooglePressed: () =>
                                              _handleSocialSignIn('Google'),
                                          onApplePressed: () =>
                                              _handleSocialSignIn('Apple'),
                                        ),
                                      ),
                                      const SizedBox(height: 24),

                                      // Footer Link (Don't have an account?)
                                      StaggeredItemAnimation(
                                        index: 8,
                                        child: _buildFooterLink(),
                                      ),
                                    ],
                                  ],
                                ),
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.05),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: _isPhoneOtpStep
          ? const AuthHeader(
              key: ValueKey('header_otp_step'),
              overline: 'SMS Verification Step',
              title: 'NEXT USER',
              subtitle:
                  'Enter the 6-digit verification code sent to your mobile.',
            )
          : const AuthHeader(
              key: ValueKey('header_login_step'),
              overline: 'Welcome Back',
              title: 'NEXT USER',
              subtitle:
                  'Sign in to access your account and manage your moves.',
            ),
    );
  }

  Widget _buildFooterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pushReplacement(
              context,
              AnimationHelper.smoothRoute(page: const SignUpView()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              'Sign Up',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.gold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

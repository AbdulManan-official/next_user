import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/auth_errors.dart';
import '../../services/auth_routing_helper.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../../utils/app_theme_styles.dart';
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
import 'login_view.dart';

/// Ultra-Luxury Sign Up View for Next User.
/// Displays official assets/app_logo.png, UK phone default, professional copy, and live session state.
class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  static final RegExp _emailRegExp =
      RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$');

  final GlobalKey<FormState> _emailFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _phoneFormKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  final ScrollController _scrollController = ScrollController();

  AuthMethod _authMethod = AuthMethod.email;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreeToTerms = true;
  bool _isLoading = false;
  bool _isPhoneOtpStep = false;
  String? _verificationId;
  int? _resendToken;
  String _selectedDialCode = '+44';
  String _selectedIsoCode = 'GB';
  String _selectedCountryName = 'United Kingdom';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();

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
    if (!mounted) return;
    setState(() => _isLoading = false);

    final displayName = SessionService.instance.clientName.isNotEmpty
        ? SessionService.instance.clientName
        : (name ?? user.displayName ?? 'Valued Client');

    AppSnackBar.showSuccess(
      context,
      'Welcome to Next User, $displayName!',
    );

    await routeAfterAuth(context);
  }

  void _handleSignUp() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_agreeToTerms) {
      HapticFeedback.heavyImpact();
      AppSnackBar.showError(
        context,
        'Please accept the Terms of Service to proceed.',
      );
      return;
    }

    if (!(_authMethod == AuthMethod.email
        ? (_emailFormKey.currentState?.validate() ?? false)
        : (_phoneFormKey.currentState?.validate() ?? false))) {
      HapticFeedback.selectionClick();
      return;
    }

    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    if (password != confirmPassword) {
      HapticFeedback.heavyImpact();
      AppSnackBar.showError(context, 'Passwords do not match. Please verify.');
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    try {
      final credential = await AuthService.instance.signUpWithEmailAndPassword(
        name: name,
        email: email,
        password: password,
      );

      if (!mounted) return;
      if (credential.user != null) {
        await _processAuthSuccess(
          credential.user!,
          loginType: 'email',
          login: email,
          name: name,
          email: email,
        );
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      HapticFeedback.heavyImpact();
      final errorMsg = readableError(e);
      AppSnackBar.showError(context, errorMsg);
    }
  }

  void _handleSendPhoneOtp() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_agreeToTerms) {
      HapticFeedback.heavyImpact();
      AppSnackBar.showError(
        context,
        'Please accept the Terms of Service to proceed.',
      );
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      HapticFeedback.heavyImpact();
      AppSnackBar.showError(context, 'Please enter your full name');
      return;
    }

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
          final errorMsg = readableError(e);
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
                name: _nameController.text.trim(),
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
      final errorMsg = readableError(e);
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

    final name = _nameController.text.trim();

    try {
      final credential = await AuthService.instance.verifyOtpAndSignIn(
        verificationId: _verificationId!,
        smsCode: code,
        displayName: name,
      );

      if (!mounted) return;
      if (credential.user != null) {
        final phone = credential.user?.phoneNumber ?? fullPhoneNumber;
        await _processAuthSuccess(
          credential.user!,
          loginType: 'phone',
          login: phone,
          name: name,
        );
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      HapticFeedback.heavyImpact();
      final errorMsg = readableError(e);
      AppSnackBar.showError(context, errorMsg);
    }
  }

  void _handleResendOtp() {
    _handleSendPhoneOtp();
  }

  void _handleSocialSignUp(String provider) async {
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
          name: credential.user!.displayName ?? _nameController.text.trim(),
          email: credential.user!.email,
        );
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      HapticFeedback.heavyImpact();
      final errorMsg = readableError(e);
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
                              padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
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
                                      const SizedBox(height: 20),

                                      // If in Phone OTP Step: Show 6-digit OTP verification
                                      if (_isPhoneOtpStep) ...[
                                        StaggeredItemAnimation(
                                          index: 1,
                                          child: OtpVerificationStep(
                                            phoneNumber: '$_selectedDialCode ${_phoneController.text.trim().replaceFirst(RegExp(r"^0+"), "")}',
                                            countryIsoCode: _selectedIsoCode,
                                            countryName: _selectedCountryName,
                                            buttonText: 'VERIFY & CREATE ACCOUNT',
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
                                              'Back to Registration options',
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
                                                _emailFormKey.currentState
                                                    ?.reset();
                                                _phoneFormKey.currentState
                                                    ?.reset();
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 18),

                                        // 2. Full Name Input
                                        StaggeredItemAnimation(
                                          index: 2,
                                          child: CustomTextField(
                                            label: 'Full Name',
                                            hintText: 'Enter your full name',
                                            controller: _nameController,
                                            focusNode: _nameFocus,
                                            prefixIcon: FontAwesomeIcons.user,
                                            textInputAction: TextInputAction.next,
                                            onFieldSubmitted: (_) {
                                              if (_authMethod == AuthMethod.email) {
                                                _emailFocus.requestFocus();
                                              } else {
                                                _phoneFocus.requestFocus();
                                              }
                                            },
                                            validator: (v) {
                                              if (v == null || v.trim().isEmpty) {
                                                return 'Please enter your full name';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 14),

                                        // 3. Dynamic Inputs (Morphing smoothly between Email and Phone)
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
                                                        'su_email_fields'),
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.stretch,
                                                    children: [
                                                      // Email field
                                                      CustomTextField(
                                                        key: const ValueKey(
                                                            'su_email'),
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
                                                            'Create secure password',
                                                        controller:
                                                            _passwordController,
                                                        focusNode:
                                                            _passwordFocus,
                                                        prefixIcon:
                                                            FontAwesomeIcons.lock,
                                                        obscureText:
                                                            !_isPasswordVisible,
                                                        textInputAction:
                                                            TextInputAction.next,
                                                        onFieldSubmitted: (_) =>
                                                            _confirmPasswordFocus
                                                                .requestFocus(),
                                                        validator: (v) {
                                                          if (v == null ||
                                                              v.isEmpty) {
                                                            return 'Please create a password';
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
                                                      const SizedBox(height: 14),

                                                      // Confirm Password field
                                                      CustomTextField(
                                                        label: 'Confirm Password',
                                                        hintText:
                                                            'Re-enter your password',
                                                        controller:
                                                            _confirmPasswordController,
                                                        focusNode:
                                                            _confirmPasswordFocus,
                                                        prefixIcon:
                                                            FontAwesomeIcons
                                                                .shield,
                                                        obscureText:
                                                            !_isConfirmPasswordVisible,
                                                        textInputAction:
                                                            TextInputAction.done,
                                                        onFieldSubmitted: (_) =>
                                                            _handleSignUp(),
                                                        validator: (v) {
                                                          if (v !=
                                                              _passwordController
                                                                  .text) {
                                                            return 'Passwords do not match';
                                                          }
                                                          return null;
                                                        },
                                                        suffixIcon: IconButton(
                                                          icon: FaIcon(
                                                            _isConfirmPasswordVisible
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
                                                                _isConfirmPasswordVisible =
                                                                    !_isConfirmPasswordVisible);
                                                          },
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                : Column(
                                                    key: const ValueKey(
                                                        'su_phone_fields'),
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.stretch,
                                                    children: [
                                                      // Phone input field (UK / PK selector)
                                                      PhoneInputField(
                                                        key: const ValueKey(
                                                            'su_phone'),
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
                                                    ],
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(height: 14),

                                        // Terms & Privacy Checkbox
                                        StaggeredItemAnimation(
                                          index: 6,
                                          child: _buildTermsCheckbox(),
                                        ),
                                        const SizedBox(height: 20),

                                        // Submit Button
                                        StaggeredItemAnimation(
                                          index: 7,
                                          child: CustomButton(
                                            text: _authMethod == AuthMethod.email
                                                ? 'CREATE ACCOUNT'
                                                : 'GET OTP VIA SMS',
                                            icon: _authMethod == AuthMethod.email
                                                ? FontAwesomeIcons.userPlus
                                                : FontAwesomeIcons.paperPlane,
                                            isLoading: _isLoading,
                                            onPressed: _authMethod ==
                                                    AuthMethod.email
                                                ? _handleSignUp
                                                : _handleSendPhoneOtp,
                                          ),
                                        ),
                                        const SizedBox(height: 22),

                                        // Divider
                                        const StaggeredItemAnimation(
                                          index: 8,
                                          child: AuthDivider(
                                            text: 'Or sign up with',
                                          ),
                                        ),
                                        const SizedBox(height: 18),

                                        // Social Buttons (Google & Apple)
                                        StaggeredItemAnimation(
                                          index: 9,
                                          child: SocialAuthButtons(
                                            isLoading: _isLoading,
                                            onGooglePressed: () =>
                                                _handleSocialSignUp('Google'),
                                            onApplePressed: () =>
                                                _handleSocialSignUp('Apple'),
                                          ),
                                        ),
                                        const SizedBox(height: 24),

                                        // Footer Link (Already have account?)
                                        StaggeredItemAnimation(
                                          index: 10,
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
              key: ValueKey('signup_header_otp'),
              overline: 'SMS Verification Step',
              title: 'NEXT USER',
              subtitle:
                  'Enter the 6-digit verification code to complete your registration.',
            )
          : const AuthHeader(
              key: ValueKey('signup_header_main'),
              overline: 'Create Your Account',
              title: 'NEXT USER',
              subtitle:
                  'Sign up to book and manage your moves with live tracking.',
            ),
    );
  }

  Widget _buildTermsCheckbox() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _agreeToTerms = !_agreeToTerms);
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: _agreeToTerms ? AppColors.gold : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _agreeToTerms ? AppColors.gold : AppColors.border,
                width: 1.2,
              ),
            ),
            child: _agreeToTerms
                ? const Center(
                    child: FaIcon(
                      FontAwesomeIcons.check,
                      size: 13,
                      color: AppColors.textOnGold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'I agree to the ',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                children: [
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: ' & '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
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
              AnimationHelper.smoothRoute(page: const LoginView()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              'Sign In',
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

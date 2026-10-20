import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/auth_errors.dart';
import '../../services/auth_routing_helper.dart';
import '../../services/auth_service.dart';
import '../../services/backend_sync_service.dart';
import '../../services/session_service.dart';
import '../../utils/app_theme_styles.dart';
import '../../widgets/animation_helper.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../widgets/auth_header.dart';
import '../widgets/phone_input_field.dart';

/// Ultra-Luxury Complete Profile Screen (Profile Gate).
/// Strictly enforced: PopScope(canPop: false).
/// Shows only the fields missing from the account:
/// - Phone signups: Must enter Full Name, Email, Password, and Confirm Password (calls linkEmailPassword).
/// - Email/Google signups: Must enter Full Name (if missing) and link Phone OTP (calls verifyPhone(linking: true) & linkPhone).
/// - Email cannot be changed once set.
class CompleteProfileView extends StatefulWidget {
  const CompleteProfileView({
    super.key,
    this.missing = const [],
  });

  final List<String> missing;

  @override
  State<CompleteProfileView> createState() => _CompleteProfileViewState();
}

class _CompleteProfileViewState extends State<CompleteProfileView> {
  static final RegExp _emailRegExp =
      RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$');

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _otpFocus = FocusNode();

  final ScrollController _scrollController = ScrollController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  // Phone OTP Linking state
  bool _isPhoneOtpStep = false;
  String? _verificationId;
  int? _resendToken;
  int _resendCooldown = 60;
  Timer? _cooldownTimer;

  String _selectedDialCode = '+44';
  String _selectedIsoCode = 'GB';

  late List<String> _missingFields;

  @override
  void initState() {
    super.initState();
    _computeMissingFields();
    _prefillExistingData();
  }

  void _computeMissingFields() {
    final user = FirebaseAuth.instance.currentUser;
    final providers =
        user?.providerData.map((p) => p.providerId).toList() ?? [];

    if (widget.missing.isNotEmpty) {
      _missingFields = List<String>.from(widget.missing);
    } else {
      _missingFields = [];
      final name = (user?.displayName ?? SessionService.instance.clientName).trim();
      final email = (user?.email ?? SessionService.instance.clientEmail).trim();
      final phone = (user?.phoneNumber ?? SessionService.instance.clientPhone).trim();

      if (name.isEmpty || name.length < 2 || name == 'Valued Client') {
        _missingFields.add('name');
      }
      if (email.isEmpty) {
        _missingFields.add('email');
      }
      if (phone.isEmpty) {
        _missingFields.add('phone');
      }
      final hasLogin =
          providers.contains('password') || providers.contains('google.com');
      if (!hasLogin) {
        _missingFields.add('password');
      }
    }
  }

  void _prefillExistingData() {
    final user = FirebaseAuth.instance.currentUser;
    final existingName =
        user?.displayName ?? SessionService.instance.clientName;
    if (existingName.isNotEmpty && !existingName.contains('Valued Client')) {
      _nameController.text = existingName;
    }

    final existingEmail = user?.email ?? SessionService.instance.clientEmail;
    if (existingEmail.isNotEmpty) {
      _emailController.text = existingEmail;
    }

    final existingPhone =
        user?.phoneNumber ?? SessionService.instance.clientPhone;
    if (existingPhone.isNotEmpty) {
      if (existingPhone.startsWith('+92')) {
        _selectedDialCode = '+92';
        _selectedIsoCode = 'PK';
        _phoneController.text = existingPhone.replaceFirst('+92', '');
      } else if (existingPhone.startsWith('+44')) {
        _selectedDialCode = '+44';
        _selectedIsoCode = 'GB';
        _phoneController.text = existingPhone.replaceFirst('+44', '');
      } else {
        _phoneController.text = existingPhone;
      }
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();

    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _phoneFocus.dispose();
    _otpFocus.dispose();

    _scrollController.dispose();
    super.dispose();
  }

  bool get _needsName =>
      _missingFields.contains('name') || _nameController.text.trim().isEmpty;

  bool get _needsEmail => _missingFields.contains('email');

  bool get _needsPassword =>
      _missingFields.contains('password') || _needsEmail;

  bool get _needsPhone => _missingFields.contains('phone');

  // ---------- Phone OTP Linking Flow ----------

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  String _formatE164Phone() {
    final rawPhone = _phoneController.text.trim();
    final cleanDigits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (rawPhone.startsWith('+')) {
      return '+$cleanDigits';
    } else if (cleanDigits.startsWith('0')) {
      return '$_selectedDialCode${cleanDigits.substring(1)}';
    } else {
      return '$_selectedDialCode$cleanDigits';
    }
  }

  Future<void> _handleSendPhoneCode() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final rawPhone = _phoneController.text.trim();
    if (rawPhone.replaceAll(RegExp(r'\D'), '').length < 8) {
      AppSnackBar.showError(
        context,
        'Please enter a valid mobile number for SMS verification.',
      );
      return;
    }

    final fullPhone = _formatE164Phone();
    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      await AuthService.instance.verifyPhone(
        phoneNumber: fullPhone,
        linking: true, // IMPORTANT: Link with current account
        resendToken: _resendToken,
        onCodeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _isLoading = false;
            _isPhoneOtpStep = true;
          });
          _startCooldown();
          AppSnackBar.showSuccess(
            context,
            '6-digit verification code sent to $fullPhone',
          );
        },
        onAutoDone: () async {
          // Instant verification via Android Play Services
          if (!mounted) return;
          await _finishSubmission(phoneLinked: true);
        },
        onError: (Object e) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          HapticFeedback.heavyImpact();
          final msg = readableError(e);
          AppSnackBar.showError(context, msg);
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      HapticFeedback.heavyImpact();
      AppSnackBar.showError(context, readableError(e));
    }
  }

  Future<void> _handleVerifyPhoneCode() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      AppSnackBar.showError(context, 'Please enter the 6-digit SMS code.');
      return;
    }
    if (_verificationId == null) {
      AppSnackBar.showError(
        context,
        'Verification session expired. Please request a new code.',
      );
      setState(() => _isPhoneOtpStep = false);
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      await AuthService.instance.linkPhone(_verificationId!, code);
      if (!mounted) return;
      await _finishSubmission(phoneLinked: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      HapticFeedback.heavyImpact();
      AppSnackBar.showError(context, readableError(e));
    }
  }

  // ---------- Full Form Submission Flow ----------

  Future<void> _handlePhoneSignupSubmit() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      HapticFeedback.selectionClick();
      return;
    }

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      // 1. Link Email & Password to Phone User
      await AuthService.instance.linkEmailPassword(email, password);

      // 2. Finish profile update & sync
      if (!mounted) return;
      await _finishSubmission(name: name, email: email);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      HapticFeedback.heavyImpact();
      AppSnackBar.showError(context, readableError(e));
    }
  }

  Future<void> _finishSubmission({
    String? name,
    String? email,
    bool phoneLinked = false,
  }) async {
    final cleanName = (name ?? _nameController.text).trim();
    final cleanEmail = (email ?? _emailController.text).trim();

    try {
      // 1. Refresh Firebase Token to carry linked credentials
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (cleanName.isNotEmpty) {
          await user.updateDisplayName(cleanName);
        }
        await user.getIdToken(true);
      }

      // 2. PUT /users/me
      await BackendSyncService.instance.updateProfile(
        name: cleanName.isNotEmpty ? cleanName : 'Valued Client',
        email: cleanEmail.isNotEmpty ? cleanEmail : null,
      );

      // 3. POST /auth/sync
      final syncResult =
          await BackendSyncService.instance.syncUserWithBackend();

      if (!mounted) return;
      setState(() => _isLoading = false);

      AppSnackBar.showSuccess(
        context,
        'Profile complete! Welcome to Platinum Concierge.',
      );

      // 4. Centralized routing
      await routeAfterAuth(context, precomputedSync: syncResult);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      HapticFeedback.heavyImpact();
      AppSnackBar.showError(context, readableError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final verifiedPhone = user?.phoneNumber ?? '';
    final verifiedEmail = user?.email ?? '';

    return PopScope(
      canPop: false, // Strict Profile Gate: User cannot bypass
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          AppSnackBar.showError(
            context,
            'Please complete your profile to continue.',
          );
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
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
                              constraints:
                                  const BoxConstraints(maxWidth: 440),
                              child: AppleGlassContainer(
                                padding: const EdgeInsets.fromLTRB(
                                    22, 28, 22, 24),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // Header
                                      const AuthHeader(
                                        overline:
                                            'FINAL STEP · CLIENT ONBOARDING',
                                        title: 'NEXT USER',
                                        subtitle:
                                            'Link your credentials to secure your concierge moving account.',
                                      ),

                                      const SizedBox(height: 20),

                                      // Verified Phone Pill (for Phone Signups)
                                      if (verifiedPhone.isNotEmpty) ...[
                                        _buildVerifiedPill(
                                          icon: FontAwesomeIcons.phone,
                                          title:
                                              'Verified Phone: $verifiedPhone',
                                        ),
                                        const SizedBox(height: 16),
                                      ],

                                      // Verified Email Pill (for Email/Google Signups)
                                      if (verifiedEmail.isNotEmpty) ...[
                                        _buildVerifiedPill(
                                          icon: FontAwesomeIcons.envelope,
                                          title:
                                              'Verified Email: $verifiedEmail',
                                          subtitle:
                                              'Email cannot be changed once set.',
                                        ),
                                        const SizedBox(height: 16),
                                      ],

                                      // Full Name Field (Always shown if missing)
                                      if (_needsName) ...[
                                        Text(
                                          'Full Name',
                                          style: AppTextStyles.labelMedium
                                              .copyWith(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        CustomTextField(
                                          controller: _nameController,
                                          focusNode: _nameFocus,
                                          hintText: 'Enter your full name',
                                          prefixIcon:
                                              FontAwesomeIcons.userTie,
                                          textInputAction: _needsEmail
                                              ? TextInputAction.next
                                              : TextInputAction.done,
                                          keyboardType: TextInputType.name,
                                          validator: (val) {
                                            if (val == null ||
                                                val.trim().isEmpty) {
                                              return 'Please enter your full name';
                                            }
                                            if (val.trim().length < 2) {
                                              return 'Name must be at least 2 characters';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                      ],

                                      // FLOW A: Phone Signups -> Needs Email & Password
                                      if (_needsEmail || _needsPassword) ...[
                                        Text(
                                          'Email Address',
                                          style: AppTextStyles.labelMedium
                                              .copyWith(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        CustomTextField(
                                          controller: _emailController,
                                          focusNode: _emailFocus,
                                          hintText: 'client@example.com',
                                          prefixIcon:
                                              FontAwesomeIcons.envelope,
                                          textInputAction:
                                              TextInputAction.next,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          validator: (val) {
                                            if (val == null ||
                                                val.trim().isEmpty) {
                                              return 'Please enter your email';
                                            }
                                            if (!_emailRegExp
                                                .hasMatch(val.trim())) {
                                              return 'Please enter a valid email';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Create Password',
                                          style: AppTextStyles.labelMedium
                                              .copyWith(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        CustomTextField(
                                          controller: _passwordController,
                                          focusNode: _passwordFocus,
                                          hintText:
                                              'Minimum 8 characters',
                                          prefixIcon:
                                              FontAwesomeIcons.lock,
                                          obscureText: !_isPasswordVisible,
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _isPasswordVisible
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                              color: AppColors.textMuted,
                                              size: 18,
                                            ),
                                            onPressed: () => setState(
                                                () => _isPasswordVisible =
                                                    !_isPasswordVisible),
                                          ),
                                          textInputAction:
                                              TextInputAction.next,
                                          validator: (val) {
                                            if (val == null ||
                                                val.isEmpty) {
                                              return 'Please enter a password';
                                            }
                                            if (val.length < 8) {
                                              return 'Password must be at least 8 characters';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Confirm Password',
                                          style: AppTextStyles.labelMedium
                                              .copyWith(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        CustomTextField(
                                          controller:
                                              _confirmPasswordController,
                                          focusNode: _confirmPasswordFocus,
                                          hintText: 'Re-enter password',
                                          prefixIcon:
                                              FontAwesomeIcons.shieldHalved,
                                          obscureText:
                                              !_isConfirmPasswordVisible,
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _isConfirmPasswordVisible
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                              color: AppColors.textMuted,
                                              size: 18,
                                            ),
                                            onPressed: () => setState(() =>
                                                _isConfirmPasswordVisible =
                                                    !_isConfirmPasswordVisible),
                                          ),
                                          textInputAction:
                                              TextInputAction.done,
                                          validator: (val) {
                                            if (val !=
                                                _passwordController.text) {
                                              return 'Passwords do not match';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 24),
                                        CustomButton(
                                          text: 'Link Email & Enter',
                                          icon: FontAwesomeIcons.arrowRight,
                                          isLoading: _isLoading,
                                          onPressed:
                                              _handlePhoneSignupSubmit,
                                        ),
                                      ],

                                      // FLOW B: Email/Google Signups -> Needs Phone OTP
                                      if (_needsPhone && !_needsEmail) ...[
                                        if (!_isPhoneOtpStep) ...[
                                          Text(
                                            'Mobile Number (SMS OTP Required)',
                                            style: AppTextStyles.labelMedium
                                                .copyWith(
                                              color:
                                                  AppColors.textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          PhoneInputField(
                                            controller: _phoneController,
                                            focusNode: _phoneFocus,
                                            initialCountry:
                                                supportedCountries.firstWhere(
                                              (c) =>
                                                  c.isoCode ==
                                                  _selectedIsoCode,
                                              orElse: () =>
                                                  supportedCountries[0],
                                            ),
                                            onCountryChanged: (c) {
                                              setState(() {
                                                _selectedDialCode =
                                                    c.dialCode;
                                                _selectedIsoCode =
                                                    c.isoCode;
                                              });
                                            },
                                          ),
                                          const SizedBox(height: 24),
                                          CustomButton(
                                            text: 'Send Verification Code',
                                            icon: FontAwesomeIcons.paperPlane,
                                            isLoading: _isLoading,
                                            onPressed: _handleSendPhoneCode,
                                          ),
                                        ] else ...[
                                          Text(
                                            'Enter 6-Digit SMS Code',
                                            style: AppTextStyles.labelMedium
                                                .copyWith(
                                              color:
                                                  AppColors.textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          CustomTextField(
                                            controller: _otpController,
                                            focusNode: _otpFocus,
                                            hintText: '123456',
                                            prefixIcon:
                                                FontAwesomeIcons.key,
                                            keyboardType:
                                                TextInputType.number,
                                            textInputAction:
                                                TextInputAction.done,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                              LengthLimitingTextInputFormatter(
                                                  6),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment
                                                    .spaceBetween,
                                            children: [
                                              TextButton(
                                                onPressed: () => setState(() =>
                                                    _isPhoneOtpStep =
                                                        false),
                                                child: Text(
                                                  'Change Number',
                                                  style: AppTextStyles
                                                      .labelSmall
                                                      .copyWith(
                                                    color: AppColors
                                                        .textSecondary,
                                                  ),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed:
                                                    _resendCooldown == 0
                                                        ? _handleSendPhoneCode
                                                        : null,
                                                child: Text(
                                                  _resendCooldown > 0
                                                      ? 'Resend in ${_resendCooldown}s'
                                                      : 'Resend Code',
                                                  style: AppTextStyles
                                                      .labelSmall
                                                      .copyWith(
                                                    color: _resendCooldown ==
                                                            0
                                                        ? AppColors.gold
                                                        : AppColors
                                                            .textMuted,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 18),
                                          CustomButton(
                                            text: 'Verify & Link Phone',
                                            icon: FontAwesomeIcons
                                                .circleCheck,
                                            isLoading: _isLoading,
                                            onPressed:
                                                _handleVerifyPhoneCode,
                                          ),
                                        ],
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerifiedPill({
    required dynamic icon,
    required String title,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          if (icon is IconData)
            Icon(icon, color: AppColors.gold, size: 15)
          else
            FaIcon(icon, color: AppColors.gold, size: 14),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const FaIcon(
            FontAwesomeIcons.circleCheck,
            color: AppColors.gold,
            size: 14,
          ),
        ],
      ),
    );
  }
}

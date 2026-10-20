import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_errors.dart';
import '../services/auth_service.dart';
import '../services/backend_sync_service.dart';
import '../services/session_service.dart';
import '../utils/app_theme_styles.dart';
import '../utils/responsive_helper.dart';
import '../widgets/animation_helper.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/logout_dialog.dart';
import '../auth/views/login_view.dart';
import '../auth/widgets/phone_input_field.dart';
import '../widgets/notification_sheet.dart';
import 'refer_earn_screen.dart';

/// Ultra-Luxury Concierge Profile & Settings Experience.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'Valued Client';
  String _userEmail = '';
  String _userPhone = '';

  @override
  void initState() {
    super.initState();
    final data = SessionService.instance.userData;
    if (data != null) {
      if (data['name'] != null && data['name'].toString().isNotEmpty) {
        _userName = data['name'].toString();
      }
      if (data['email'] != null && data['email'].toString().isNotEmpty) {
        _userEmail = data['email'].toString();
      }
      if (data['phone'] != null && data['phone'].toString().isNotEmpty) {
        _userPhone = data['phone'].toString();
      }
    }
  }

  void _onSignOut(BuildContext context) async {
    HapticFeedback.lightImpact();
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to log out of your Platinum account?',
      confirmText: 'Sign Out',
      isDanger: true,
    );

    if (confirmed == true && context.mounted) {
      await AuthService.instance.signOut();
      if (context.mounted) {
        AppSnackBar.showSuccess(context, 'Signed out successfully.');
        Navigator.of(context).pushAndRemoveUntil(
          AnimationHelper.smoothRoute(page: const LoginView()),
          (route) => false,
        );
      }
    }
  }

  void _showPersonalInfoSheet() {
    HapticFeedback.lightImpact();
    final nameCtrl = TextEditingController(text: _userName);
    final emailCtrl = TextEditingController(text: _userEmail);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            context.w(22),
            context.h(20),
            context.w(22),
            MediaQuery.of(ctx).viewInsets.bottom + context.h(24),
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(context.r(28)),
            ),
            border: Border.all(color: AppColors.border),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: context.w(38),
                    height: context.h(4),
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(context.r(2)),
                    ),
                  ),
                ),
                SizedBox(height: context.h(16)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Personal Information',
                      style: AppTextStyles.titleLarge.copyWith(
                        fontSize: context.sp(18),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      color: AppColors.textMuted,
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                SizedBox(height: context.h(16)),

                // FULL NAME
                CustomTextField(
                  label: 'FULL NAME',
                  controller: nameCtrl,
                  prefixIcon: Icons.person_outline_rounded,
                ),
                SizedBox(height: context.h(14)),

                // EMAIL ADDRESS (Read-only if set; linking option if missing)
                if (_userEmail.isNotEmpty) ...[
                  CustomTextField(
                    label: 'EMAIL ADDRESS',
                    controller: emailCtrl,
                    readOnly: true,
                    prefixIcon: Icons.email_outlined,
                    suffixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.gold,
                      size: 18,
                    ),
                  ),
                  SizedBox(height: context.h(4)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: context.w(4)),
                    child: Text(
                      'Email cannot be changed once set.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: EdgeInsets.all(context.r(14)),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(context.r(12)),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.mail_outline_rounded, color: AppColors.gold, size: 20),
                        SizedBox(width: context.w(12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'No Email Linked',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Link an email and password to secure email login.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showLinkEmailSheet();
                          },
                          child: const Text('Link', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: context.h(14)),

                // PHONE NUMBER (Verified pill or Link Phone flow)
                if (_userPhone.isNotEmpty) ...[
                  CustomTextField(
                    label: 'VERIFIED CONTACT NUMBER',
                    controller: TextEditingController(text: _userPhone),
                    readOnly: true,
                    prefixIcon: Icons.phone_outlined,
                    suffixIcon: const Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppColors.gold,
                      size: 18,
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: EdgeInsets.all(context.r(14)),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(context.r(12)),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.phone_outlined, color: AppColors.gold, size: 20),
                        SizedBox(width: context.w(12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'No Phone Linked',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Link your mobile number for SMS OTP login.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showLinkPhoneSheet();
                          },
                          child: const Text('Link', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: context.h(22)),

                CustomButton(
                  text: 'Save Changes',
                  height: context.h(48),
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    final newName = nameCtrl.text.trim();
                    if (newName.length < 2) {
                      AppSnackBar.showError(context, 'Name must be at least 2 characters.');
                      return;
                    }
                    try {
                      await BackendSyncService.instance.updateProfile(name: newName);
                      await FirebaseAuth.instance.currentUser?.updateDisplayName(newName);
                      setState(() => _userName = newName);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        AppSnackBar.showSuccess(
                          context,
                          'Profile name updated successfully.',
                        );
                      }
                    } catch (e) {
                      final msg = readableError(e);
                      if (mounted) AppSnackBar.showError(context, msg);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Sheet to link Phone via verifyPhone(linking: true) and linkPhone
  void _showLinkPhoneSheet() {
    final phoneCtrl = TextEditingController();
    final otpCtrl = TextEditingController();
    String selectedDial = '+44';
    String? verificationId;
    int? resendToken;
    bool isOtpStep = false;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetInnerCtx, setSheetState) {
            String formatPhone() {
              final raw = phoneCtrl.text.trim();
              final digits = raw.replaceAll(RegExp(r'\D'), '');
              if (raw.startsWith('+')) return '+$digits';
              if (digits.startsWith('0')) return '$selectedDial${digits.substring(1)}';
              return '$selectedDial$digits';
            }

            return Container(
              padding: EdgeInsets.fromLTRB(
                context.w(22),
                context.h(20),
                context.w(22),
                MediaQuery.of(context).viewInsets.bottom + context.h(24),
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(context.r(28))),
                border: Border.all(color: AppColors.border),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: context.w(38),
                        height: context.h(4),
                        decoration: BoxDecoration(
                          color: AppColors.textMuted.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(context.r(2)),
                        ),
                      ),
                    ),
                    SizedBox(height: context.h(16)),
                    Text(
                      'Link Mobile Number',
                      style: AppTextStyles.titleLarge.copyWith(
                        fontSize: context.sp(18),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: context.h(16)),
                    if (!isOtpStep) ...[
                      PhoneInputField(
                        label: 'CONTACT NUMBER',
                        controller: phoneCtrl,
                        initialCountry: supportedCountries[0],
                        onCountryChanged: (c) => selectedDial = c.dialCode,
                      ),
                      SizedBox(height: context.h(20)),
                      CustomButton(
                        text: 'Send Verification Code',
                        isLoading: isLoading,
                        height: context.h(48),
                        onPressed: () async {
                          final full = formatPhone();
                          if (full.length < 9) {
                            AppSnackBar.showError(context, 'Enter a valid mobile number.');
                            return;
                          }
                          setSheetState(() => isLoading = true);
                          try {
                            await AuthService.instance.verifyPhone(
                              phoneNumber: full,
                              linking: true, // NEVER signInWithCredential!
                              resendToken: resendToken,
                              onCodeSent: (id, token) {
                                setSheetState(() {
                                  verificationId = id;
                                  resendToken = token;
                                  isOtpStep = true;
                                  isLoading = false;
                                });
                                if (mounted) AppSnackBar.showSuccess(context, 'SMS code sent to $full');
                              },
                              onAutoDone: () async {
                                // Auto verified
                                await FirebaseAuth.instance.currentUser?.getIdToken(true);
                                await BackendSyncService.instance.syncUserWithBackend();
                                if (mounted) setState(() => _userPhone = full);
                                if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                                if (mounted) AppSnackBar.showSuccess(context, 'Phone linked successfully.');
                              },
                              onError: (e) {
                                setSheetState(() => isLoading = false);
                                if (mounted) AppSnackBar.showError(context, readableError(e));
                              },
                            );
                          } catch (e) {
                            setSheetState(() => isLoading = false);
                            if (mounted) AppSnackBar.showError(context, readableError(e));
                          }
                        },
                      ),
                    ] else ...[
                      CustomTextField(
                        label: '6-DIGIT SMS CODE',
                        controller: otpCtrl,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.lock_clock_outlined,
                      ),
                      SizedBox(height: context.h(20)),
                      CustomButton(
                        text: 'Verify & Link',
                        isLoading: isLoading,
                        height: context.h(48),
                        onPressed: () async {
                          final code = otpCtrl.text.trim();
                          if (code.length != 6 || verificationId == null) {
                            if (mounted) AppSnackBar.showError(context, 'Enter the valid 6-digit code.');
                            return;
                          }
                          setSheetState(() => isLoading = true);
                          try {
                            await AuthService.instance.linkPhone(verificationId!, code);
                            await FirebaseAuth.instance.currentUser?.getIdToken(true);
                            await BackendSyncService.instance.syncUserWithBackend();
                            if (mounted) setState(() => _userPhone = formatPhone());
                            if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                            if (mounted) AppSnackBar.showSuccess(context, 'Phone linked successfully.');
                          } catch (e) {
                            setSheetState(() => isLoading = false);
                            if (mounted) AppSnackBar.showError(context, readableError(e));
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Sheet to link Email + Password via linkEmailPassword
  void _showLinkEmailSheet() {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetInnerCtx, setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                context.w(22),
                context.h(20),
                context.w(22),
                MediaQuery.of(context).viewInsets.bottom + context.h(24),
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(context.r(28))),
                border: Border.all(color: AppColors.border),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: context.w(38),
                        height: context.h(4),
                        decoration: BoxDecoration(
                          color: AppColors.textMuted.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(context.r(2)),
                        ),
                      ),
                    ),
                    SizedBox(height: context.h(16)),
                    Text(
                      'Link Email & Password',
                      style: AppTextStyles.titleLarge.copyWith(
                        fontSize: context.sp(18),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: context.h(16)),
                    CustomTextField(
                      label: 'EMAIL ADDRESS',
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                    ),
                    SizedBox(height: context.h(12)),
                    CustomTextField(
                      label: 'CREATE PASSWORD',
                      controller: passCtrl,
                      obscureText: true,
                      prefixIcon: Icons.lock_outline_rounded,
                    ),
                    SizedBox(height: context.h(12)),
                    CustomTextField(
                      label: 'CONFIRM PASSWORD',
                      controller: confirmCtrl,
                      obscureText: true,
                      prefixIcon: Icons.shield_outlined,
                    ),
                    SizedBox(height: context.h(20)),
                    CustomButton(
                      text: 'Link Email',
                      isLoading: isLoading,
                      height: context.h(48),
                      onPressed: () async {
                        final email = emailCtrl.text.trim().toLowerCase();
                        final pass = passCtrl.text;
                        final confirm = confirmCtrl.text;

                        if (email.isEmpty || !email.contains('@')) {
                          AppSnackBar.showError(context, 'Enter a valid email address.');
                          return;
                        }
                        if (pass.length < 8) {
                          AppSnackBar.showError(context, 'Password must be at least 8 characters.');
                          return;
                        }
                        if (pass != confirm) {
                          AppSnackBar.showError(context, 'Passwords do not match.');
                          return;
                        }

                        setSheetState(() => isLoading = true);
                        try {
                          await AuthService.instance.linkEmailPassword(email, pass);
                          await FirebaseAuth.instance.currentUser?.getIdToken(true);
                          await BackendSyncService.instance.updateProfile(name: _userName, email: email);
                          await BackendSyncService.instance.syncUserWithBackend();
                          if (mounted) setState(() => _userEmail = email);
                          if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                          if (mounted) {
                            AppSnackBar.showSuccess(
                              context,
                              'Email linked successfully. Verification link sent to inbox.',
                            );
                          }
                        } catch (e) {
                          setSheetState(() => isLoading = false);
                          if (mounted) AppSnackBar.showError(context, readableError(e));
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSavedAddressesSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.all(context.r(22)),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(context.r(28)),
            ),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: context.w(38),
                  height: context.h(4),
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(context.r(2)),
                  ),
                ),
              ),
              SizedBox(height: context.h(16)),
              Text(
                'Saved Luxury Residences',
                style: AppTextStyles.titleLarge.copyWith(
                  fontSize: context.sp(18),
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: context.h(16)),
              _buildAddressItem(
                context,
                title: 'Rosewood Manor (Primary)',
                address: '14 St. Leonard\'s Hill, Windsor SL4 2HJ',
                isDefault: true,
              ),
              SizedBox(height: context.h(10)),
              _buildAddressItem(
                context,
                title: 'City Penthouse',
                address: '12 Kingsway, Slough SL1 1XN',
                isDefault: false,
              ),
              SizedBox(height: context.h(18)),
              CustomButton(
                text: 'Add New Residence',
                icon: Icons.add_location_alt_rounded,
                variant: ButtonVariant.outlined,
                height: context.h(46),
                onPressed: () {
                  Navigator.pop(ctx);
                  AppSnackBar.showInfo(context, 'Address locator opening...');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddressItem(
    BuildContext context, {
    required String title,
    required String address,
    required bool isDefault,
  }) {
    return Container(
      padding: EdgeInsets.all(context.r(14)),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(context.r(16)),
        border: Border.all(
          color: isDefault
              ? AppColors.gold.withValues(alpha: 0.45)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.r(8)),
            decoration: BoxDecoration(
              color: const Color(0xFF352618),
              borderRadius: BorderRadius.circular(context.r(10)),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.4),
              ),
            ),
            child: Icon(
              Icons.home_work_rounded,
              color: AppColors.goldLight,
              size: context.r(18),
            ),
          ),
          SizedBox(width: context.w(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: context.sp(13),
                        ),
                      ),
                    ),
                    if (isDefault)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.w(6),
                          vertical: context.h(2),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(context.r(6)),
                        ),
                        child: Text(
                          'DEFAULT',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.gold,
                            fontSize: context.sp(9),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: context.h(3)),
                Text(
                  address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    fontSize: context.sp(11.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.all(context.r(22)),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(context.r(28)),
            ),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: context.w(38),
                  height: context.h(4),
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(context.r(2)),
                  ),
                ),
              ),
              SizedBox(height: context.h(16)),
              Text(
                'Payment Methods',
                style: AppTextStyles.titleLarge.copyWith(
                  fontSize: context.sp(18),
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: context.h(16)),
              // Gold Black Luxury Card Mockup
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(context.r(18)),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E2419), Color(0xFF1B140D), Color(0xFF120E0A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(context.r(18)),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.16),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PLATINUM CONCIERGE',
                          style: AppTextStyles.overline.copyWith(
                            color: AppColors.gold,
                            letterSpacing: 1.5,
                            fontSize: context.sp(10),
                          ),
                        ),
                        Icon(
                          Icons.contactless_rounded,
                          color: AppColors.goldLight,
                          size: context.r(20),
                        ),
                      ],
                    ),
                    SizedBox(height: context.h(16)),
                    Text(
                      '••••  ••••  ••••  4242',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: context.sp(16),
                        letterSpacing: 2.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: context.h(14)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _userName.toUpperCase(),
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: context.sp(11),
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          'EXP 08/28',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.gold,
                            fontSize: context.sp(11),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.h(20)),
              CustomButton(
                text: 'Add New Card',
                icon: Icons.add_card_rounded,
                variant: ButtonVariant.outlined,
                height: context.h(46),
                onPressed: () {
                  Navigator.pop(ctx);
                  AppSnackBar.showInfo(context, 'Secure payment gateway opening...');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showWhiteGlovePreferencesSheet() {
    HapticFeedback.lightImpact();
    bool ecoPacking = true;
    bool fineArtHandling = true;
    bool priorityDispatch = true;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.all(context.r(22)),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(context.r(28)),
                ),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: context.w(38),
                      height: context.h(4),
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(context.r(2)),
                      ),
                    ),
                  ),
                  SizedBox(height: context.h(16)),
                  Text(
                    'White-Glove Preferences',
                    style: AppTextStyles.titleLarge.copyWith(
                      fontSize: context.sp(18),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: context.h(6)),
                  Text(
                    'Default luxury standards applied to all your relocation bookings.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      fontSize: context.sp(12),
                    ),
                  ),
                  SizedBox(height: context.h(16)),
                  SwitchListTile(
                    value: ecoPacking,
                    activeThumbColor: AppColors.gold,
                    activeTrackColor: AppColors.gold.withValues(alpha: 0.3),
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Eco-Friendly Wooden Crating',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: context.sp(13.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Zero single-use plastics during residential packing',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: context.sp(11),
                      ),
                    ),
                    onChanged: (v) => setSheetState(() => ecoPacking = v),
                  ),
                  SwitchListTile(
                    value: fineArtHandling,
                    activeThumbColor: AppColors.gold,
                    activeTrackColor: AppColors.gold.withValues(alpha: 0.3),
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Fine Art & Antique Protocol',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: context.sp(13.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Temperature controlled vehicle requirement flag',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: context.sp(11),
                      ),
                    ),
                    onChanged: (v) => setSheetState(() => fineArtHandling = v),
                  ),
                  SwitchListTile(
                    value: priorityDispatch,
                    activeThumbColor: AppColors.gold,
                    activeTrackColor: AppColors.gold.withValues(alpha: 0.3),
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Priority Concierge Dispatch',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: context.sp(13.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Guaranteed elite crew lead assignment',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: context.sp(11),
                      ),
                    ),
                    onChanged: (v) => setSheetState(() => priorityDispatch = v),
                  ),
                  SizedBox(height: context.h(16)),
                  CustomButton(
                    text: 'Save Preferences',
                    height: context.h(46),
                    onPressed: () {
                      Navigator.pop(ctx);
                      AppSnackBar.showSuccess(
                        context,
                        'White-Glove preferences updated.',
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: r.maxContentWidth),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            r.pagePadding,
            context.h(14),
            r.pagePadding,
            context.h(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------------------------------------------------------
              // 1. TOP HEADER & VIP BADGE
              // ---------------------------------------------------------------
              AppFadeAnimation(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CONCIERGE ACCOUNT',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.overline.copyWith(
                              fontSize: context.sp(10),
                              letterSpacing: 1.8,
                              color: AppColors.gold,
                            ),
                          ),
                          SizedBox(height: context.h(2)),
                          Text(
                            'Profile & Settings',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleLarge.copyWith(
                              fontSize: context.sp(20),
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: context.w(10)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(11),
                        vertical: context.h(5),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF352618),
                        borderRadius: BorderRadius.circular(context.r(20)),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.55),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.22),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.workspace_premium_rounded,
                            color: AppColors.goldLight,
                            size: context.r(14),
                          ),
                          SizedBox(width: context.w(5)),
                          Text(
                            'Platinum VIP',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.goldLight,
                              fontSize: context.sp(11),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.h(16)),

              // ---------------------------------------------------------------
              // 2. BESPOKE VIP MEMBERSHIP CARD
              // ---------------------------------------------------------------
              AppFadeAnimation(
                delay: const Duration(milliseconds: 100),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(context.r(20)),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(context.r(24)),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.38),
                      width: 1.2,
                    ),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF281E15),
                        Color(0xFF1B140E),
                        Color(0xFF120E0A),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.12),
                        blurRadius: 18,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Glowing Monogram Avatar
                          Container(
                            width: context.r(58),
                            height: context.r(58),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE8C888), Color(0xFFC49A50)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.gold.withValues(alpha: 0.4),
                                  blurRadius: 14,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _userName.trim().isNotEmpty
                                    ? _userName
                                        .trim()
                                        .split(RegExp(r'\s+'))
                                        .map((w) => w.isNotEmpty ? w[0] : '')
                                        .take(2)
                                        .join()
                                        .toUpperCase()
                                    : 'VC',
                                style: AppTextStyles.headlineMedium.copyWith(
                                  color: const Color(0xFF1B140E),
                                  fontSize: context.sp(20),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: context.w(14)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _userName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.titleLarge.copyWith(
                                          fontSize: context.sp(18),
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.verified_rounded,
                                      color: AppColors.gold,
                                      size: context.r(16),
                                    ),
                                  ],
                                ),
                                SizedBox(height: context.h(3)),
                                Text(
                                  _userEmail,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textMuted,
                                    fontSize: context.sp(12),
                                  ),
                                ),
                                SizedBox(height: context.h(4)),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: context.w(7),
                                    vertical: context.h(2),
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceElevated,
                                    borderRadius:
                                        BorderRadius.circular(context.r(8)),
                                    border: Border.all(
                                      color: AppColors.gold
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    'ID: NX-88219 · Priority Access',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.gold,
                                      fontSize: context.sp(10),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: context.h(18)),
                      Divider(
                        color: AppColors.gold.withValues(alpha: 0.2),
                        height: 1,
                      ),
                      SizedBox(height: context.h(14)),
                      // Stats Row
                      Row(
                        children: [
                          _buildMiniStat(context, '4', 'Moves Completed'),
                          Container(
                            width: 1,
                            height: context.h(26),
                            color: AppColors.border.withValues(alpha: 0.6),
                          ),
                          _buildMiniStat(context, '£350', 'Referral Earned'),
                          Container(
                            width: 1,
                            height: context.h(26),
                            color: AppColors.border.withValues(alpha: 0.6),
                          ),
                          _buildMiniStat(context, '100%', 'White-Glove'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: context.h(22)),

              // ---------------------------------------------------------------
              // 3. GROUP 1: ACCOUNT & CREDENTIALS
              // ---------------------------------------------------------------
              _buildSectionHeader(context, 'ACCOUNT & CREDENTIALS'),
              SizedBox(height: context.h(8)),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(context.r(22)),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      context,
                      icon: Icons.badge_outlined,
                      label: 'Personal Information',
                      subtitle: 'Name, email & phone number',
                      onTap: _showPersonalInfoSheet,
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      context,
                      icon: Icons.location_on_outlined,
                      label: 'Saved Residences',
                      subtitle: '2 addresses · Windsor & Slough',
                      onTap: _showSavedAddressesSheet,
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      context,
                      icon: Icons.credit_card_rounded,
                      label: 'Payment & Billing',
                      subtitle: 'Mastercard •••• 4242 · Primary Card',
                      onTap: _showPaymentSheet,
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.h(20)),

              // ---------------------------------------------------------------
              // 4. GROUP 2: REWARDS & CONCIERGE PREFERENCES
              // ---------------------------------------------------------------
              _buildSectionHeader(context, 'REWARDS & CONCIERGE'),
              SizedBox(height: context.h(8)),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(context.r(22)),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      context,
                      icon: Icons.card_giftcard_rounded,
                      label: 'Refer & Earn Rewards',
                      subtitle: 'Invite friends & earn £50 credit each',
                      onTap: () {
                        Navigator.push(
                          context,
                          AnimationHelper.smoothRoute(
                            page: const ReferEarnScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      context,
                      icon: Icons.auto_awesome_rounded,
                      label: 'White-Glove Standards',
                      subtitle: 'Eco-crates, fine art & priority crew',
                      onTap: _showWhiteGlovePreferencesSheet,
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      context,
                      icon: Icons.notifications_none_rounded,
                      label: 'Notifications & Alerts',
                      subtitle: 'Live transit tracking & SMS alerts',
                      onTap: () => NotificationSheet.show(context),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      context,
                      icon: Icons.security_rounded,
                      label: 'Insurance & Coverage',
                      subtitle: 'Platinum £100,000 policy included',
                      onTap: () {
                        AppSnackBar.showInfo(
                          context,
                          'Platinum Transit Insurance Policy active for all moves.',
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.h(20)),

              // ---------------------------------------------------------------
              // 5. GROUP 3: LEGAL & APP INFO
              // ---------------------------------------------------------------
              _buildSectionHeader(context, 'LEGAL & APP INFO'),
              SizedBox(height: context.h(8)),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(context.r(22)),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      context,
                      icon: Icons.privacy_tip_outlined,
                      label: 'Terms & Privacy Policy',
                      subtitle: 'Noble Moving luxury terms v2.4',
                      onTap: () {
                        AppSnackBar.showInfo(
                          context,
                          'Noble Moving Terms & Conditions v2.4',
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      context,
                      icon: Icons.star_border_rounded,
                      label: 'Rate Experience',
                      subtitle: 'Share your concierge review',
                      onTap: () {
                        AppSnackBar.showSuccess(
                          context,
                          'Thank you for your rating!',
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.h(26)),

              // ---------------------------------------------------------------
              // 7. SIGN OUT BUTTON & METADATA
              // ---------------------------------------------------------------
              AppFadeAnimation(
                delay: const Duration(milliseconds: 200),
                child: Center(
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () => _onSignOut(context),
                        borderRadius: BorderRadius.circular(context.r(16)),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.w(24),
                            vertical: context.h(13),
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2B1414),
                            borderRadius: BorderRadius.circular(context.r(16)),
                            border: Border.all(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.14),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.logout_rounded,
                                color: const Color(0xFFEF4444),
                                size: context.r(18),
                              ),
                              SizedBox(width: context.w(8)),
                              Text(
                                'Sign Out of Platinum Account',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: const Color(0xFFEF4444),
                                  fontSize: context.sp(13.5),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: context.h(14)),
                      Text(
                        'Next User Concierge · v2.4.0 (Build 108)',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: context.sp(11),
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(left: context.w(4)),
      child: Text(
        title,
        style: AppTextStyles.overline.copyWith(
          fontSize: context.sp(10.5),
          letterSpacing: 1.5,
          color: AppColors.textMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildMiniStat(BuildContext context, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.gold,
              fontSize: context.sp(16),
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: context.h(2)),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontSize: context.sp(10.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.r(16)),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(16),
          vertical: context.h(13),
        ),
        child: Row(
          children: [
            // Quick-Action Inspired Amber Glowing Box
            Container(
              padding: EdgeInsets.all(context.r(8)),
              decoration: BoxDecoration(
                color: const Color(0xFF352618),
                borderRadius: BorderRadius.circular(context.r(11)),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.4),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.16),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: AppColors.goldLight,
                size: context.r(17),
              ),
            ),
            SizedBox(width: context.w(14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: context.sp(13.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: context.h(2)),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: context.sp(11.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: context.r(18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: AppColors.border.withValues(alpha: 0.5),
      indent: context.w(56),
    );
  }
}

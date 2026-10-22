import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../widgets/notification_sheet.dart';
import '../widgets/glass_kit.dart';
import '../auth/views/login_view.dart';
import '../auth/widgets/phone_input_field.dart';
import 'refer_earn_screen.dart';

const Color _red = Color(0xFFEF4444);

/// Profile & settings — luxury dark, gold & frosted glass.
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
      final name = data['name']?.toString() ?? '';
      final email = data['email']?.toString() ?? '';
      final phone = data['phone']?.toString() ?? '';
      if (name.isNotEmpty) _userName = name;
      if (email.isNotEmpty) _userEmail = email;
      if (phone.isNotEmpty) _userPhone = phone;
    }
  }

  // Phone-only users have no email: show the phone instead of a blank line.
  String get _contactLine => _userEmail.isNotEmpty ? _userEmail : _userPhone;

  String get _initials {
    final words = _userName.trim().split(RegExp(r'\s+'));
    final letters = words
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join()
        .toUpperCase();
    return letters.isEmpty ? 'VC' : letters;
  }

  Future<void> _onSignOut() async {
    HapticFeedback.lightImpact();
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to log out of your Platinum account?',
      confirmText: 'Sign Out',
      isDanger: true,
    );

    if (confirmed == true && mounted) {
      await AuthService.instance.signOut();
      if (!mounted) return;
      AppSnackBar.showSuccess(context, 'Signed out successfully.');
      Navigator.of(context).pushAndRemoveUntil(
        AnimationHelper.smoothRoute(page: const LoginView()),
        (route) => false,
      );
    }
  }

  // ── Sheet openers ──────────────────────────────────────────────────────────
  void _showPersonalInfoSheet() {
    HapticFeedback.lightImpact();
    showNxSheet<void>(
      context,
      builder: (ctx) => _PersonalInfoSheet(
        name: _userName,
        email: _userEmail,
        phone: _userPhone,
        onSaved: (newName) {
          if (!mounted) return;
          setState(() => _userName = newName);
          AppSnackBar.showSuccess(context, 'Profile name updated successfully.');
        },
        onLinkEmail: () {
          Navigator.pop(ctx);
          _showLinkEmailSheet();
        },
        onLinkPhone: () {
          Navigator.pop(ctx);
          _showLinkPhoneSheet();
        },
      ),
    );
  }

  void _showLinkPhoneSheet() {
    showNxSheet<void>(
      context,
      builder: (_) => _LinkPhoneSheet(
        onLinked: (phone) {
          if (!mounted) return;
          setState(() => _userPhone = phone);
          AppSnackBar.showSuccess(context, 'Phone linked successfully.');
        },
      ),
    );
  }

  void _showLinkEmailSheet() {
    showNxSheet<void>(
      context,
      builder: (_) => _LinkEmailSheet(
        userName: _userName,
        onLinked: (email) {
          if (!mounted) return;
          setState(() => _userEmail = email);
          AppSnackBar.showSuccess(
            context,
            'Email linked successfully. Verification link sent to inbox.',
          );
        },
      ),
    );
  }

  void _showSavedAddressesSheet() {
    HapticFeedback.lightImpact();
    showNxSheet<void>(
      context,
      builder: (ctx) => NxSheet(
        title: 'Saved Luxury Residences',
        child: Column(
          children: [
            const _AddressItem(
              title: 'Rosewood Manor (Primary)',
              address: "14 St. Leonard's Hill, Windsor SL4 2HJ",
              isDefault: true,
            ),
            SizedBox(height: context.h(10)),
            const _AddressItem(
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
                if (mounted) {
                  AppSnackBar.showInfo(context, 'Address locator opening...');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentSheet() {
    HapticFeedback.lightImpact();
    showNxSheet<void>(
      context,
      builder: (ctx) => NxSheet(
        title: 'Payment Methods',
        child: Column(
          children: [
            _PaymentCard(holder: _userName),
            SizedBox(height: context.h(20)),
            CustomButton(
              text: 'Add New Card',
              icon: Icons.add_card_rounded,
              variant: ButtonVariant.outlined,
              height: context.h(46),
              onPressed: () {
                Navigator.pop(ctx);
                if (mounted) {
                  AppSnackBar.showInfo(
                      context, 'Secure payment gateway opening...');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showWhiteGlovePreferencesSheet() {
    HapticFeedback.lightImpact();
    showNxSheet<void>(
      context,
      builder: (_) => _PreferencesSheet(
        onSaved: () {
          if (!mounted) return;
          AppSnackBar.showSuccess(context, 'White-Glove preferences updated.');
        },
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Stack(
      children: [
        const Positioned.fill(child: NxAmbientBackground()),
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: r.maxContentWidth),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                r.pagePadding,
                context.h(14),
                r.pagePadding,
                context.h(24) + (bottomInset > 60 ? bottomInset : bottomInset + 88),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppFadeAnimation(child: _buildHeader(context)),
                  SizedBox(height: context.h(18)),

                  AppFadeAnimation(
                    delay: const Duration(milliseconds: 100),
                    child: _buildMembershipCard(context),
                  ),
                  SizedBox(height: context.h(24)),

                  NxSettingsGroup(
                    title: 'ACCOUNT & CREDENTIALS',
                    tiles: [
                      NxSettingsTile(
                        icon: Icons.badge_outlined,
                        label: 'Personal Information',
                        subtitle: 'Name, email & phone number',
                        onTap: _showPersonalInfoSheet,
                      ),
                      NxSettingsTile(
                        icon: Icons.location_on_outlined,
                        label: 'Saved Residences',
                        subtitle: '2 addresses · Windsor & Slough',
                        onTap: _showSavedAddressesSheet,
                      ),
                      NxSettingsTile(
                        icon: Icons.credit_card_rounded,
                        label: 'Payment & Billing',
                        subtitle: 'Mastercard •••• 4242 · Primary Card',
                        onTap: _showPaymentSheet,
                      ),
                    ],
                  ),
                  SizedBox(height: context.h(22)),

                  NxSettingsGroup(
                    title: 'REWARDS & CONCIERGE',
                    tiles: [
                      NxSettingsTile(
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
                      NxSettingsTile(
                        icon: Icons.auto_awesome_rounded,
                        label: 'White-Glove Standards',
                        subtitle: 'Eco-crates, fine art & priority crew',
                        onTap: _showWhiteGlovePreferencesSheet,
                      ),
                      NxSettingsTile(
                        icon: Icons.notifications_none_rounded,
                        label: 'Notifications & Alerts',
                        subtitle: 'Live transit tracking & SMS alerts',
                        onTap: () => NotificationSheet.show(context),
                      ),
                      NxSettingsTile(
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
                  SizedBox(height: context.h(22)),

                  NxSettingsGroup(
                    title: 'LEGAL & APP INFO',
                    tiles: [
                      NxSettingsTile(
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
                      NxSettingsTile(
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
                  SizedBox(height: context.h(26)),

                  AppFadeAnimation(
                    delay: const Duration(milliseconds: 200),
                    child: _buildSignOut(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
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
                  color: AppColors.gold,
                  fontSize: context.sp(10.5),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.4,
                ),
              ),
              SizedBox(height: context.h(3)),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Profile & Settings',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: context.sp(26),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: context.w(10)),
        NxGlassPanel(
          radius: 20,
          fillAlpha: 0.10,
          padding: EdgeInsets.symmetric(
            horizontal: context.w(12),
            vertical: context.h(7),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.workspace_premium_rounded,
                  color: AppColors.goldLight, size: context.r(15)),
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
    );
  }

  Widget _buildMembershipCard(BuildContext context) {
    return NxGlassPanel(
      radius: 30,
      blur: 16,
      fillAlpha: 0.09,
      padding: EdgeInsets.all(context.r(20)),
      child: Column(
        children: [
          Row(
            children: [
              // Monogram avatar with glass ring + glow
              Container(
                width: context.r(60),
                height: context.r(60),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.goldLinearGradient,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.45),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.38),
                      blurRadius: 22,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _initials,
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.textOnGold,
                      fontSize: context.sp(21),
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
                        Flexible(
                          child: Text(
                            _userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleLarge.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: context.sp(19),
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        if (_userPhone.isNotEmpty) ...[
                          SizedBox(width: context.w(6)),
                          Icon(Icons.verified_rounded,
                              color: AppColors.gold, size: context.r(17)),
                        ],
                      ],
                    ),
                    if (_contactLine.isNotEmpty) ...[
                      SizedBox(height: context.h(3)),
                      Text(
                        _contactLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMuted,
                          fontSize: context.sp(12),
                        ),
                      ),
                    ],
                    SizedBox(height: context.h(7)),
                    NxBadge(
                      text: 'ID: NX-88219 · Priority Access',
                      fontSize: context.sp(10),
                      letterSpacing: 0.3,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(18)),
          const NxHairline(),
          SizedBox(height: context.h(14)),
          Row(
            children: [
              const NxMiniStat(value: '4', label: 'Moves Completed'),
              Container(
                width: 1,
                height: context.h(28),
                color: Colors.white.withValues(alpha: 0.10),
              ),
              const NxMiniStat(value: '£350', label: 'Referral Earned'),
              Container(
                width: 1,
                height: context.h(28),
                color: Colors.white.withValues(alpha: 0.10),
              ),
              const NxMiniStat(value: '100%', label: 'White-Glove'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignOut(BuildContext context) {
    return Center(
      child: Column(
        children: [
          NxPressable(
            onTap: _onSignOut,
            child: NxGlassPanel(
              radius: 18,
              tint: _red,
              padding: EdgeInsets.symmetric(
                horizontal: context.w(24),
                vertical: context.h(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.logout_rounded, color: _red, size: context.r(18)),
                  SizedBox(width: context.w(8)),
                  Text(
                    'Sign Out of Platinum Account',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: _red,
                      fontSize: context.sp(13.5),
                      fontWeight: FontWeight.w800,
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
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  SETTINGS LIST PARTS
// ════════════════════════════════════════════════════════════════════════════
//  SHEETS (each owns and disposes its own controllers)
// ════════════════════════════════════════════════════════════════════════════

// ── Personal information ────────────────────────────────────────────────────
class _PersonalInfoSheet extends StatefulWidget {
  const _PersonalInfoSheet({
    required this.name,
    required this.email,
    required this.phone,
    required this.onSaved,
    required this.onLinkEmail,
    required this.onLinkPhone,
  });

  final String name;
  final String email;
  final String phone;
  final ValueChanged<String> onSaved;
  final VoidCallback onLinkEmail;
  final VoidCallback onLinkPhone;

  @override
  State<_PersonalInfoSheet> createState() => _PersonalInfoSheetState();
}

class _PersonalInfoSheetState extends State<_PersonalInfoSheet> {
  late final TextEditingController _nameCtrl =
      TextEditingController(text: widget.name);
  late final TextEditingController _emailCtrl =
      TextEditingController(text: widget.email);
  late final TextEditingController _phoneCtrl =
      TextEditingController(text: widget.phone);
  bool _saving = false;
  bool _sendingVerify = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();
    final newName = _nameCtrl.text.trim();
    if (newName.length < 2) {
      AppSnackBar.showError(context, 'Name must be at least 2 characters.');
      return;
    }
    setState(() => _saving = true);
    try {
      await BackendSyncService.instance.updateProfile(name: newName);
      await FirebaseAuth.instance.currentUser?.updateDisplayName(newName);
      if (!mounted) return;
      final onSaved = widget.onSaved;
      Navigator.pop(context);
      onSaved(newName);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackBar.showError(context, readableError(e));
    }
  }

  Future<void> _sendVerify() async {
    setState(() => _sendingVerify = true);
    try {
      await AuthService.instance.sendEmailVerification();
      if (!mounted) return;
      AppSnackBar.showSuccess(context, 'Verification link sent to your inbox.');
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, readableError(e));
    } finally {
      if (mounted) setState(() => _sendingVerify = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final providers =
        user?.providerData.map((p) => p.providerId).toSet() ?? <String>{};
    final emailVerified = user?.emailVerified ?? false;

    return NxSheet(
      title: 'Personal Information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sign-in methods
          Text(
            'SIGN-IN METHODS',
            style: AppTextStyles.overline.copyWith(
              color: AppColors.textMuted,
              fontSize: context.sp(10),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
            ),
          ),
          SizedBox(height: context.h(8)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              NxMethodChip(
                label: 'Email',
                icon: Icons.email_outlined,
                linked: providers.contains('password'),
              ),
              NxMethodChip(
                label: 'Phone',
                icon: Icons.phone_outlined,
                linked: providers.contains('phone'),
              ),
              NxMethodChip(
                label: 'Google',
                icon: Icons.g_mobiledata_rounded,
                linked: providers.contains('google.com'),
              ),
            ],
          ),
          SizedBox(height: context.h(18)),

          CustomTextField(
            label: 'FULL NAME',
            controller: _nameCtrl,
            prefixIcon: Icons.person_outline_rounded,
          ),
          SizedBox(height: context.h(14)),

          // Email
          if (widget.email.isNotEmpty) ...[
            CustomTextField(
              label: 'EMAIL ADDRESS',
              controller: _emailCtrl,
              readOnly: true,
              prefixIcon: Icons.email_outlined,
              suffixIcon: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.gold,
                size: 18,
              ),
            ),
            SizedBox(height: context.h(6)),
            if (!emailVerified)
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.gold, size: 15),
                  SizedBox(width: context.w(6)),
                  Expanded(
                    child: Text(
                      'Email not verified yet.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _sendingVerify ? null : _sendVerify,
                    child: Text(
                      _sendingVerify ? 'Sending...' : 'Send link',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              )
            else
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
          ] else
            NxLinkPrompt(
              icon: Icons.mail_outline_rounded,
              title: 'No Email Linked',
              message: 'Link an email and password to secure email login.',
              onLink: widget.onLinkEmail,
            ),
          SizedBox(height: context.h(14)),

          // Phone
          if (widget.phone.isNotEmpty)
            CustomTextField(
              label: 'VERIFIED CONTACT NUMBER',
              controller: _phoneCtrl,
              readOnly: true,
              prefixIcon: Icons.phone_outlined,
              suffixIcon: const Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.gold,
                size: 18,
              ),
            )
          else
            NxLinkPrompt(
              icon: Icons.phone_outlined,
              title: 'No Phone Linked',
              message: 'Link your mobile number for SMS OTP login.',
              onLink: widget.onLinkPhone,
            ),
          SizedBox(height: context.h(22)),

          CustomButton(
            text: 'Save Changes',
            isLoading: _saving,
            height: context.h(48),
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

// ── Link phone (verifyPhone(linking: true) -> linkPhone) ────────────────────
class _LinkPhoneSheet extends StatefulWidget {
  const _LinkPhoneSheet({required this.onLinked});

  final ValueChanged<String> onLinked;

  @override
  State<_LinkPhoneSheet> createState() => _LinkPhoneSheetState();
}

class _LinkPhoneSheetState extends State<_LinkPhoneSheet> {
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _otpCtrl = TextEditingController();
  late String _dial = supportedCountries[0].dialCode;
  String? _verificationId;
  int? _resendToken;
  bool _otpStep = false;
  bool _loading = false;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  String _formatPhone() {
    final raw = _phoneCtrl.text.trim();
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (raw.startsWith('+')) return '+$digits';
    if (digits.startsWith('0')) return '$_dial${digits.substring(1)}';
    return '$_dial$digits';
  }

  void _startCooldown() {
    _timer?.cancel();
    if (!mounted) return;
    setState(() => _cooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  void _fail(Object e) {
    if (!mounted) return;
    setState(() => _loading = false);
    final msg = readableError(e);
    if (msg.isNotEmpty) AppSnackBar.showError(context, msg);
    if (e is FirebaseAuthException && e.code == 'too-many-requests') {
      _startCooldown();
    }
  }

  void _finish(String phone) {
    if (!mounted) return;
    final onLinked = widget.onLinked;
    Navigator.pop(context);
    onLinked(phone);
  }

  Future<void> _sendCode() async {
    if (_cooldown > 0 || _loading) return;
    final full = _formatPhone();
    if (full.length < 9) {
      AppSnackBar.showError(context, 'Enter a valid mobile number.');
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthService.instance.verifyPhone(
        phoneNumber: full,
        linking: true, // NEVER signInWithCredential in this flow
        resendToken: _resendToken,
        onCodeSent: (id, token) {
          if (!mounted) return;
          setState(() {
            _verificationId = id;
            _resendToken = token;
            _otpStep = true;
            _loading = false;
          });
          _startCooldown();
          AppSnackBar.showSuccess(context, 'SMS code sent to $full');
        },
        onAutoDone: () async {
          try {
            await FirebaseAuth.instance.currentUser?.getIdToken(true);
            await BackendSyncService.instance.syncUserWithBackend();
            _finish(full);
          } catch (e) {
            _fail(e);
          }
        },
        onError: _fail,
      );
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> _verify() async {
    final code = _otpCtrl.text.trim();
    if (code.length != 6 || _verificationId == null) {
      AppSnackBar.showError(context, 'Enter the valid 6-digit code.');
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthService.instance.linkPhone(_verificationId!, code);
      await FirebaseAuth.instance.currentUser?.getIdToken(true);
      await BackendSyncService.instance.syncUserWithBackend();
      _finish(_formatPhone());
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NxSheet(
      title: 'Link Mobile Number',
      subtitle: 'Add a phone so you can also sign in with an SMS code.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_otpStep) ...[
            PhoneInputField(
              label: 'CONTACT NUMBER',
              controller: _phoneCtrl,
              initialCountry: supportedCountries[0],
              onCountryChanged: (c) => _dial = c.dialCode,
            ),
            SizedBox(height: context.h(20)),
            CustomButton(
              text: 'Send Verification Code',
              isLoading: _loading,
              height: context.h(48),
              onPressed: _sendCode,
            ),
          ] else ...[
            CustomTextField(
              label: '6-DIGIT SMS CODE',
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.lock_clock_outlined,
            ),
            SizedBox(height: context.h(20)),
            CustomButton(
              text: 'Verify & Link',
              isLoading: _loading,
              height: context.h(48),
              onPressed: _verify,
            ),
            SizedBox(height: context.h(6)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => setState(() {
                            _otpStep = false;
                            _otpCtrl.clear();
                          }),
                  child: const Text(
                    'Change number',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
                TextButton(
                  onPressed: (_loading || _cooldown > 0) ? null : _sendCode,
                  child: Text(
                    _cooldown > 0 ? 'Resend in ${_cooldown}s' : 'Resend code',
                    style: TextStyle(
                      color: _cooldown > 0
                          ? AppColors.textMuted
                          : AppColors.gold,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Link email + password ───────────────────────────────────────────────────
class _LinkEmailSheet extends StatefulWidget {
  const _LinkEmailSheet({required this.userName, required this.onLinked});

  final String userName;
  final ValueChanged<String> onLinked;

  @override
  State<_LinkEmailSheet> createState() => _LinkEmailSheetState();
}

class _LinkEmailSheetState extends State<_LinkEmailSheet> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _link() async {
    final email = _emailCtrl.text.trim().toLowerCase();
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
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

    setState(() => _loading = true);
    try {
      await AuthService.instance.linkEmailPassword(email, pass);
      await FirebaseAuth.instance.currentUser?.getIdToken(true);
      await BackendSyncService.instance
          .updateProfile(name: widget.userName, email: email);
      await BackendSyncService.instance.syncUserWithBackend();
      if (!mounted) return;
      final onLinked = widget.onLinked;
      Navigator.pop(context);
      onLinked(email);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final msg = readableError(e);
      if (msg.isNotEmpty) AppSnackBar.showError(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NxSheet(
      title: 'Link Email & Password',
      subtitle: 'Add an email so you can also sign in with a password.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomTextField(
            label: 'EMAIL ADDRESS',
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
          ),
          SizedBox(height: context.h(12)),
          CustomTextField(
            label: 'CREATE PASSWORD',
            controller: _passCtrl,
            obscureText: true,
            prefixIcon: Icons.lock_outline_rounded,
          ),
          SizedBox(height: context.h(12)),
          CustomTextField(
            label: 'CONFIRM PASSWORD',
            controller: _confirmCtrl,
            obscureText: true,
            prefixIcon: Icons.shield_outlined,
          ),
          SizedBox(height: context.h(20)),
          CustomButton(
            text: 'Link Email',
            isLoading: _loading,
            height: context.h(48),
            onPressed: _link,
          ),
        ],
      ),
    );
  }
}

// ── White-glove preferences ─────────────────────────────────────────────────
class _PreferencesSheet extends StatefulWidget {
  const _PreferencesSheet({required this.onSaved});

  final VoidCallback onSaved;

  @override
  State<_PreferencesSheet> createState() => _PreferencesSheetState();
}

class _PreferencesSheetState extends State<_PreferencesSheet> {
  bool _ecoPacking = true;
  bool _fineArt = true;
  bool _priority = true;

  Widget _switch({
    required bool value,
    required String title,
    required String subtitle,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      activeThumbColor: AppColors.gold,
      activeTrackColor: AppColors.gold.withValues(alpha: 0.3),
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textPrimary,
          fontSize: context.sp(13.5),
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textMuted,
          fontSize: context.sp(11),
        ),
      ),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return NxSheet(
      title: 'White-Glove Preferences',
      subtitle: 'Default luxury standards applied to all your bookings.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _switch(
            value: _ecoPacking,
            title: 'Eco-Friendly Wooden Crating',
            subtitle: 'Zero single-use plastics during residential packing',
            onChanged: (v) => setState(() => _ecoPacking = v),
          ),
          const NxHairline(),
          _switch(
            value: _fineArt,
            title: 'Fine Art & Antique Protocol',
            subtitle: 'Temperature controlled vehicle requirement flag',
            onChanged: (v) => setState(() => _fineArt = v),
          ),
          const NxHairline(),
          _switch(
            value: _priority,
            title: 'Priority Concierge Dispatch',
            subtitle: 'Guaranteed elite crew lead assignment',
            onChanged: (v) => setState(() => _priority = v),
          ),
          SizedBox(height: context.h(18)),
          CustomButton(
            text: 'Save Preferences',
            height: context.h(46),
            onPressed: () {
              final onSaved = widget.onSaved;
              Navigator.pop(context);
              onSaved();
            },
          ),
        ],
      ),
    );
  }
}

// ── Addresses / payment bodies ──────────────────────────────────────────────
class _AddressItem extends StatelessWidget {
  const _AddressItem({
    required this.title,
    required this.address,
    required this.isDefault,
  });

  final String title;
  final String address;
  final bool isDefault;

  @override
  Widget build(BuildContext context) {
    return NxGlassPanel(
      radius: 20,
      fillAlpha: 0.08,
      tint: isDefault ? AppColors.gold : Colors.white,
      padding: EdgeInsets.all(context.r(14)),
      child: Row(
        children: [
          NxGoldIconTile(
            icon: Icons.home_work_rounded,
            size: context.r(40),
            iconSize: context.r(19),
            radius: 13,
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
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: context.sp(13.5),
                        ),
                      ),
                    ),
                    if (isDefault)
                      NxBadge(
                        text: 'DEFAULT',
                        fontSize: context.sp(9),
                        letterSpacing: 0.8,
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
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.holder});

  final String holder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.r(20)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E2419), Color(0xFF1B140D), Color(0xFF120E0A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 6),
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
                  letterSpacing: 2.0,
                  fontSize: context.sp(10),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(Icons.contactless_rounded,
                  color: AppColors.goldLight, size: context.r(22)),
            ],
          ),
          SizedBox(height: context.h(18)),
          Text(
            '••••  ••••  ••••  4242',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textPrimary,
              fontSize: context.sp(17),
              letterSpacing: 2.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: context.h(16)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  holder.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textMuted,
                    fontSize: context.sp(11),
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Text(
                'EXP 08/28',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.gold,
                  fontSize: context.sp(11),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../utils/app_theme_styles.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'phone_input_field.dart';

/// Clean Single-Field SMS Verification Step designed for Firebase Phone Auth.
/// Uses a rock-solid single CustomTextField to prevent keyboard/layout glitches,
/// with UK destination badge, change number action, 45s resend timer, and gold action button.
class OtpVerificationStep extends StatefulWidget {
  final String phoneNumber;
  final String? countryIsoCode;
  final String? countryName;
  final String buttonText;
  final bool isLoading;
  final ValueChanged<String> onVerify;
  final VoidCallback onResend;
  final VoidCallback onChangeNumber;

  const OtpVerificationStep({
    super.key,
    required this.phoneNumber,
    this.countryIsoCode,
    this.countryName,
    this.buttonText = 'VERIFY & SIGN IN',
    this.isLoading = false,
    required this.onVerify,
    required this.onResend,
    required this.onChangeNumber,
  });

  @override
  State<OtpVerificationStep> createState() => _OtpVerificationStepState();
}

class _OtpVerificationStepState extends State<OtpVerificationStep> {
  static const int _countdownInitial = 45;

  late final TextEditingController _otpController;
  late final FocusNode _otpFocusNode;

  Timer? _timer;
  int _secondsRemaining = _countdownInitial;

  String get _effectiveIsoCode {
    if (widget.countryIsoCode != null && widget.countryIsoCode!.isNotEmpty) {
      return widget.countryIsoCode!;
    }
    if (widget.phoneNumber.contains('+92')) return 'PK';
    return 'GB';
  }

  String get _effectiveCountryLabel {
    if (widget.countryName != null && widget.countryName!.isNotEmpty) {
      if (widget.countryName!.contains('(')) {
        return widget.countryName!;
      }
      final dial = _effectiveIsoCode == 'PK' ? '(+92)' : '(+44)';
      return '${widget.countryName} $dial';
    }
    if (widget.phoneNumber.contains('+92') || _effectiveIsoCode == 'PK') {
      return 'Pakistan (+92)';
    }
    return 'United Kingdom (+44)';
  }

  @override
  void initState() {
    super.initState();
    // Clean empty controller — NO pre-filled dummy/demo code
    _otpController = TextEditingController();
    _otpFocusNode = FocusNode();
    _startCountdown();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _otpFocusNode.requestFocus();
      }
    });
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsRemaining = _countdownInitial);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _triggerVerification() {
    final code = _otpController.text.trim();
    if (code.length < 4) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the full verification code')),
      );
      return;
    }
    if (!widget.isLoading) {
      HapticFeedback.lightImpact();
      widget.onVerify(code);
    }
  }

  void _handleResend() {
    if (_secondsRemaining > 0 || widget.isLoading) return;
    HapticFeedback.mediumImpact();
    _otpController.clear();
    _otpFocusNode.requestFocus();
    _startCountdown();
    widget.onResend();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Dynamic destination badge with country flag and edit action
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              CountryFlag(isoCode: _effectiveIsoCode, width: 26, height: 17),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SMS sent to $_effectiveCountryLabel',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.phoneNumber,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: widget.onChangeNumber,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.penToSquare,
                        size: 12,
                        color: AppColors.goldLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Change',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.goldLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // 2. Simple, rock-solid single text field for OTP verification
        CustomTextField(
          label: 'VERIFICATION CODE',
          hintText: 'Enter 6-digit verification code',
          controller: _otpController,
          focusNode: _otpFocusNode,
          prefixIcon: FontAwesomeIcons.shieldHalved,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          onFieldSubmitted: (_) => _triggerVerification(),
          suffixIcon: _otpController.text.isNotEmpty
              ? IconButton(
                  icon: const FaIcon(
                    FontAwesomeIcons.circleXmark,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () {
                    _otpController.clear();
                    setState(() {});
                  },
                )
              : null,
        ),
        const SizedBox(height: 12),

        // 3. Resend timer & guidance info
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Didn't receive code?",
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
            if (_secondsRemaining > 0)
              Text(
                'Resend in 0:${_secondsRemaining.toString().padLeft(2, '0')}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              )
            else
              GestureDetector(
                onTap: _handleResend,
                child: Text(
                  'Resend SMS Code',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 22),

        // 4. Verify Action Button
        CustomButton(
          text: widget.buttonText,
          icon: FontAwesomeIcons.shieldHalved,
          isLoading: widget.isLoading,
          onPressed: _triggerVerification,
        ),
      ],
    );
  }
}

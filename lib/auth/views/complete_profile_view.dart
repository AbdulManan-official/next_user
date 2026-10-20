import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/backend_sync_service.dart';
import '../../services/session_service.dart';
import '../../utils/app_theme_styles.dart';
import '../../views/bottom_tab_view.dart';
import '../../widgets/animation_helper.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../widgets/auth_header.dart';

/// Ultra-Luxury Complete Profile Screen for new clients registering via Passwordless OTP or OAuth.
/// Prompts the client for their Full Name and Email before proceeding to the Dashboard.
class CompleteProfileView extends StatefulWidget {
  const CompleteProfileView({super.key});

  @override
  State<CompleteProfileView> createState() => _CompleteProfileViewState();
}

class _CompleteProfileViewState extends State<CompleteProfileView> {
  static final RegExp _emailRegExp =
      RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$');

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final existingName = SessionService.instance.clientName;
    if (existingName.isNotEmpty && !existingName.contains('Valued Client')) {
      _nameController.text = existingName;
    }
    final existingEmail = SessionService.instance.clientEmail;
    if (existingEmail.isNotEmpty) {
      _emailController.text = existingEmail;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      HapticFeedback.selectionClick();
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();

    try {
      final result = await BackendSyncService.instance.updateProfile(
        name: name,
        email: email,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        HapticFeedback.lightImpact();
        AppSnackBar.showSuccess(
          context,
          'Profile completed successfully! Welcome, $name.',
        );

        Navigator.pushReplacement(
          context,
          AnimationHelper.smoothRoute(page: const BottomTabView()),
        );
      } else {
        HapticFeedback.heavyImpact();
        AppSnackBar.showError(
          context,
          result['message']?.toString() ?? 'Failed to update profile. Please try again.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      HapticFeedback.heavyImpact();
      AppSnackBar.showError(context, 'An unexpected error occurred: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final verifiedPhone = SessionService.instance.clientPhone;

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
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Brand Header
                                    const AuthHeader(
                                      overline: 'STEP 2 OF 2 · VIP ONBOARDING',
                                      title: 'NEXT USER',
                                      subtitle:
                                          'Complete your client profile to unlock personalized concierge booking and white-glove moving services.',
                                    ),

                                    const SizedBox(height: 22),

                                    // Verified Phone pill if authenticated via phone
                                    if (verifiedPhone.isNotEmpty) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.gold.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: AppColors.gold.withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const FaIcon(
                                              FontAwesomeIcons.circleCheck,
                                              color: AppColors.gold,
                                              size: 15,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                'Verified Phone: $verifiedPhone',
                                                style: AppTextStyles.labelMedium.copyWith(
                                                  color: AppColors.gold,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                    ],

                                    // Full Name Field
                                    Text(
                                      'Full Name',
                                      style: AppTextStyles.labelMedium.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    CustomTextField(
                                      controller: _nameController,
                                      focusNode: _nameFocus,
                                      hintText: 'Enter your full name',
                                      prefixIcon: FontAwesomeIcons.userTie,
                                      textInputAction: TextInputAction.next,
                                      keyboardType: TextInputType.name,
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Please enter your full name';
                                        }
                                        if (value.trim().length < 2) {
                                          return 'Name must be at least 2 characters';
                                        }
                                        return null;
                                      },
                                      onFieldSubmitted: (_) {
                                        _emailFocus.requestFocus();
                                      },
                                    ),

                                    const SizedBox(height: 16),

                                    // Email Field
                                    Text(
                                      'Email Address',
                                      style: AppTextStyles.labelMedium.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    CustomTextField(
                                      controller: _emailController,
                                      focusNode: _emailFocus,
                                      hintText: 'client@example.com',
                                      prefixIcon: FontAwesomeIcons.envelope,
                                      textInputAction: TextInputAction.done,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Please enter your email address';
                                        }
                                        if (!_emailRegExp.hasMatch(value.trim())) {
                                          return 'Please enter a valid email address';
                                        }
                                        return null;
                                      },
                                      onFieldSubmitted: (_) => _handleSubmit(),
                                    ),

                                    const SizedBox(height: 24),

                                    // Submit Button
                                    CustomButton(
                                      text: 'Save & Enter Concierge',
                                      icon: FontAwesomeIcons.arrowRight,
                                      isLoading: _isLoading,
                                      onPressed: _handleSubmit,
                                    ),
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
    );
  }
}

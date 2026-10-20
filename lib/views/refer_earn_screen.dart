import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme_styles.dart';
import '../utils/responsive_helper.dart';
import '../widgets/animation_helper.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/custom_button.dart';
import '../controllers/move_store.dart';

/// Ultra-Luxury Concierge Refer & Earn Screen.
class ReferEarnScreen extends StatefulWidget {
  const ReferEarnScreen({super.key});

  @override
  State<ReferEarnScreen> createState() => _ReferEarnScreenState();
}

class _ReferEarnScreenState extends State<ReferEarnScreen> {
  final MoveStore _store = MoveStore.instance;
  bool _isCopied = false;

  void _copyCode() {
    HapticFeedback.lightImpact();
    Clipboard.setData(const ClipboardData(text: 'ELEANOR50'));
    setState(() => _isCopied = true);
    AppSnackBar.showSuccess(context, 'Referral code ELEANOR50 copied to clipboard!');

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  void _shareInvite() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
          context.w(24),
          context.h(16),
          context.w(24),
          context.h(32),
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(context.r(28)),
          ),
          border: Border.all(color: AppColors.border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: context.w(44),
              height: context.h(4),
              decoration: BoxDecoration(
                color: AppColors.border.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(context.r(2)),
              ),
            ),
            SizedBox(height: context.h(22)),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(12),
                vertical: context.h(4),
              ),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(context.r(20)),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'VIP INVITATION',
                style: AppTextStyles.overline.copyWith(
                  color: AppColors.gold,
                  fontSize: context.sp(9.5),
                  letterSpacing: 1.6,
                ),
              ),
            ),
            SizedBox(height: context.h(10)),
            Text(
              'Share Platinum Benefit',
              style: AppTextStyles.headlineSmall.copyWith(
                fontSize: context.sp(18),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: context.h(6)),
            Text(
              'Gift £50 moving credit to colleagues & friends. When they complete their relocation, you receive £50 credit.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontSize: context.sp(12.5),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.h(24)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _shareOption(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Messages',
                  onTap: () {
                    Navigator.pop(ctx);
                    AppSnackBar.showInfo(context, 'Opening Messages...');
                  },
                ),
                _shareOption(
                  icon: Icons.mail_outline_rounded,
                  label: 'Email',
                  onTap: () {
                    Navigator.pop(ctx);
                    AppSnackBar.showInfo(context, 'Opening Mail app...');
                  },
                ),
                _shareOption(
                  icon: Icons.copy_rounded,
                  label: 'Copy Code',
                  onTap: () {
                    Navigator.pop(ctx);
                    _copyCode();
                  },
                ),
              ],
            ),
            SizedBox(height: context.h(12)),
          ],
        ),
      ),
    );
  }

  Widget _shareOption({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.r(16)),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(14),
          vertical: context.h(10),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(context.r(14)),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.35),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.08),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: AppColors.gold,
                size: context.r(22),
              ),
            ),
            SizedBox(height: context.h(8)),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textPrimary,
                fontSize: context.sp(11),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(context.r(6)),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.gold,
              size: context.r(15),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'REFERRAL PROGRAMME',
              style: AppTextStyles.overline.copyWith(
                fontSize: context.sp(9.5),
                letterSpacing: 1.8,
              ),
            ),
            SizedBox(height: context.h(2)),
            Text(
              'Refer & Earn',
              style: AppTextStyles.headlineSmall.copyWith(
                fontSize: context.sp(15.5),
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: r.maxContentWidth),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                r.pagePadding,
                context.h(10),
                r.pagePadding,
                context.h(36),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Luxury VIP Reward Banner
                  AppFadeAnimation(
                    delay: const Duration(milliseconds: 60),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(context.r(20)),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(context.r(24)),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.surfaceElevated,
                            AppColors.surface,
                            AppColors.gold.withValues(alpha: 0.08),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.1),
                            blurRadius: 18,
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
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.w(10),
                                  vertical: context.h(4),
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withValues(alpha: 0.15),
                                  borderRadius:
                                      BorderRadius.circular(context.r(16)),
                                  border: Border.all(
                                    color: AppColors.gold.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.stars_rounded,
                                      color: AppColors.gold,
                                      size: context.r(13),
                                    ),
                                    SizedBox(width: context.w(5)),
                                    Text(
                                      'MEMBER PRIVILEGE',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.gold,
                                        fontSize: context.sp(9.5),
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.w(8),
                                  vertical: context.h(3),
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  borderRadius:
                                      BorderRadius.circular(context.r(10)),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  'Unlimited',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textMuted,
                                    fontSize: context.sp(10.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: context.h(16)),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: context.r(52),
                                height: context.r(52),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        AppColors.gold.withValues(alpha: 0.5),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          AppColors.gold.withValues(alpha: 0.25),
                                      blurRadius: 14,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.card_giftcard_rounded,
                                    color: AppColors.gold,
                                    size: context.r(26),
                                  ),
                                ),
                              ),
                              SizedBox(width: context.w(16)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Give £50 · Earn £50',
                                      style: AppTextStyles.headlineSmall
                                          .copyWith(
                                        fontSize: context.sp(17),
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: context.h(3)),
                                    Text(
                                      'Every referral saves your friend £50 on booking and credits £50 to your concierge wallet upon completion.',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: context.sp(11.5),
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: context.h(18)),

                  // 2. Metrics Performance Row (Earned, Pending, Invited)
                  AppFadeAnimation(
                    delay: const Duration(milliseconds: 100),
                    child: Row(
                      children: [
                        _buildStatCard(
                          icon: Icons.account_balance_wallet_rounded,
                          value: '£350',
                          label: 'EARNED',
                          accentColor: AppColors.gold,
                        ),
                        SizedBox(width: context.w(9)),
                        _buildStatCard(
                          icon: Icons.hourglass_top_rounded,
                          value: '£100',
                          label: 'PENDING',
                          accentColor: const Color(0xFFE5A93C),
                        ),
                        SizedBox(width: context.w(9)),
                        _buildStatCard(
                          icon: Icons.group_add_rounded,
                          value: '7',
                          label: 'INVITED',
                          accentColor: AppColors.success,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.h(22)),

                  // 3. Unique VIP Referral Code Vault
                  AppFadeAnimation(
                    delay: const Duration(milliseconds: 140),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(context.r(18)),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(context.r(22)),
                        border: Border.all(color: AppColors.border, width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'YOUR EXCLUSIVE CODE',
                                style: AppTextStyles.overline.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: context.sp(10),
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Text(
                                'Tap to copy',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.gold.withValues(alpha: 0.8),
                                  fontSize: context.sp(10.5),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: context.h(10)),
                          InkWell(
                            onTap: _copyCode,
                            borderRadius:
                                BorderRadius.circular(context.r(16)),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.w(18),
                                vertical: context.h(13),
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius:
                                    BorderRadius.circular(context.r(16)),
                                border: Border.all(
                                  color: _isCopied
                                      ? AppColors.success
                                      : AppColors.gold.withValues(alpha: 0.65),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _isCopied
                                        ? AppColors.success
                                            .withValues(alpha: 0.15)
                                        : AppColors.gold.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.vpn_key_rounded,
                                        size: context.r(16),
                                        color: AppColors.gold,
                                      ),
                                      SizedBox(width: context.w(10)),
                                      Text(
                                        'ELEANOR50',
                                        style: AppTextStyles.headlineLarge
                                            .copyWith(
                                          color: AppColors.gold,
                                          fontSize: context.sp(19),
                                          letterSpacing: 3.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: context.w(10),
                                      vertical: context.h(6),
                                    ),
                                    decoration: BoxDecoration(
                                      color: _isCopied
                                          ? AppColors.success
                                              .withValues(alpha: 0.2)
                                          : AppColors.gold
                                              .withValues(alpha: 0.15),
                                      borderRadius:
                                          BorderRadius.circular(context.r(10)),
                                      border: Border.all(
                                        color: _isCopied
                                            ? AppColors.success
                                            : AppColors.gold
                                                .withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _isCopied
                                              ? Icons.check_circle_rounded
                                              : Icons.copy_rounded,
                                          color: _isCopied
                                              ? AppColors.success
                                              : AppColors.gold,
                                          size: context.r(14),
                                        ),
                                        SizedBox(width: context.w(4)),
                                        Text(
                                          _isCopied ? 'Copied' : 'Copy',
                                          style: AppTextStyles.labelSmall
                                              .copyWith(
                                            color: _isCopied
                                                ? AppColors.success
                                                : AppColors.gold,
                                            fontSize: context.sp(10.5),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: context.h(14)),
                          CustomButton(
                            text: 'Share Invitation Link',
                            icon: Icons.share_rounded,
                            height: context.h(48),
                            onPressed: _shareInvite,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: context.h(22)),

                  // 4. How It Works Milestone Journey
                  AppFadeAnimation(
                    delay: const Duration(milliseconds: 180),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(context.r(20)),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(context.r(22)),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                color: AppColors.gold,
                                size: context.r(18),
                              ),
                              SizedBox(width: context.w(8)),
                              Text(
                                'How It Works',
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontSize: context.sp(15),
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: context.h(16)),
                          _buildMilestoneStep(
                            stepNumber: '1',
                            title: 'Share your exclusive link',
                            subtitle:
                                'Send code ELEANOR50 to your circle via WhatsApp, message, or email.',
                            isLast: false,
                          ),
                          _buildMilestoneStep(
                            stepNumber: '2',
                            title: 'They book their premier move',
                            subtitle:
                                'Your invite gives them an instant £50 discount at reservation checkout.',
                            isLast: false,
                          ),
                          _buildMilestoneStep(
                            stepNumber: '3',
                            title: 'Receive your £50 credit reward',
                            subtitle:
                                'As soon as their move concludes, £50 auto-credits to your next relocation.',
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: context.h(22)),

                  // 5. Activity Ledger / Referral History
                  AppFadeAnimation(
                    delay: const Duration(milliseconds: 220),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.history_rounded,
                                  color: AppColors.gold,
                                  size: context.r(18),
                                ),
                                SizedBox(width: context.w(8)),
                                Text(
                                  'Referral Ledger',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    fontSize: context.sp(15),
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.w(8),
                                vertical: context.h(3),
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius:
                                    BorderRadius.circular(context.r(10)),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                '${_store.referrals.length} Total',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.gold,
                                  fontSize: context.sp(10.5),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: context.h(12)),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(context.r(22)),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: _store.referrals.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              final isLast = index == _store.referrals.length - 1;

                              Color statusColor;
                              Color statusBg;
                              String statusText = item.status;

                              if (item.status.toLowerCase() == 'moved') {
                                statusColor = AppColors.success;
                                statusBg =
                                    AppColors.success.withValues(alpha: 0.15);
                                statusText = 'Completed';
                              } else if (item.status.toLowerCase() == 'booked') {
                                statusColor = const Color(0xFFE5A93C);
                                statusBg = const Color(0xFFE5A93C)
                                    .withValues(alpha: 0.15);
                                statusText = 'Booked';
                              } else {
                                statusColor = AppColors.textMuted;
                                statusBg = AppColors.surfaceElevated;
                                statusText = 'Pending';
                              }

                              return Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.w(16),
                                  vertical: context.h(14),
                                ),
                                decoration: BoxDecoration(
                                  border: isLast
                                      ? null
                                      : Border(
                                          bottom: BorderSide(
                                            color: AppColors.divider
                                                .withValues(alpha: 0.5),
                                            width: 0.8,
                                          ),
                                        ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: context.r(38),
                                      height: context.r(38),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceElevated,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.gold
                                              .withValues(alpha: 0.35),
                                          width: 1,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          item.initials,
                                          style: AppTextStyles.labelSmall
                                              .copyWith(
                                            color: AppColors.gold,
                                            fontWeight: FontWeight.w700,
                                            fontSize: context.sp(11.5),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: context.w(12)),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: context.sp(13),
                                            ),
                                          ),
                                          SizedBox(height: context.h(2)),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: context.w(6),
                                              vertical: context.h(2),
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusBg,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                context.r(8),
                                              ),
                                            ),
                                            child: Text(
                                              statusText,
                                              style: AppTextStyles.labelSmall
                                                  .copyWith(
                                                color: statusColor,
                                                fontSize: context.sp(9.5),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      item.amount,
                                      style:
                                          AppTextStyles.titleMedium.copyWith(
                                        color: item.amount.startsWith('+')
                                            ? AppColors.gold
                                            : AppColors.textMuted,
                                        fontWeight: FontWeight.w800,
                                        fontSize: context.sp(14),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
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

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color accentColor,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: context.h(14),
          horizontal: context.w(10),
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(context.r(18)),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(context.r(6)),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: accentColor,
                size: context.r(15),
              ),
            ),
            SizedBox(height: context.h(8)),
            Text(
              value,
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.textPrimary,
                fontSize: context.sp(17),
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: context.h(3)),
            Text(
              label,
              style: AppTextStyles.overline.copyWith(
                fontSize: context.sp(9),
                letterSpacing: 1.2,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneStep({
    required String stepNumber,
    required String title,
    required String subtitle,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: context.r(28),
              height: context.r(28),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.5),
                  width: 1.2,
                ),
              ),
              child: Center(
                child: Text(
                  stepNumber,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w800,
                    fontSize: context.sp(11),
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 1.5,
                height: context.h(28),
                margin: EdgeInsets.symmetric(vertical: context.h(2)),
                color: AppColors.border.withValues(alpha: 0.8),
              ),
          ],
        ),
        SizedBox(width: context.w(12)),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : context.h(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: context.sp(13),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: context.h(2)),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: context.sp(11),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

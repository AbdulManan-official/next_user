import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme_styles.dart';
import '../utils/responsive_helper.dart';
import '../widgets/animation_helper.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/glass_kit.dart'; // <- fix path to your glass kit file
import '../controllers/move_store.dart';

/// Luxury concierge Refer & Earn screen, glass kit edition.
class ReferEarnScreen extends StatefulWidget {
  const ReferEarnScreen({super.key});

  @override
  State<ReferEarnScreen> createState() => _ReferEarnScreenState();
}

class _ReferEarnScreenState extends State<ReferEarnScreen> {
  static const _referralCode = 'ELEANOR50';
  static const _amber = Color(0xFFE5A93C);

  final MoveStore _store = MoveStore.instance;
  bool _isCopied = false;

  // ─── Actions ─────────────────────────────────────────────────────────────

  void _copyCode() {
    HapticFeedback.lightImpact();
    Clipboard.setData(const ClipboardData(text: _referralCode));
    setState(() => _isCopied = true);
    AppSnackBar.showSuccess(
      context,
      'Referral code $_referralCode copied to clipboard!',
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  void _shareInvite() {
    HapticFeedback.mediumImpact();
    showNxSheet<void>(
      context,
      builder: (ctx) => NxSheet(
        title: 'Share Platinum Benefit',
        subtitle: 'Gift £50 moving credit, earn £50 back.',
        child: Column(
          children: [
            const StatusPill(
              label: 'VIP INVITATION',
              icon: Icons.workspace_premium_rounded,
              color: AppColors.gold,
              fontSize: 9.5,
            ),
            SizedBox(height: context.h(12)),
            Text(
              'Gift £50 moving credit to colleagues & friends. When they complete their relocation, you receive £50 credit.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontSize: context.sp(12.5),
                height: 1.4,
              ),
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
            SizedBox(height: context.h(8)),
          ],
        ),
      ),
    );
  }

  Widget _shareOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GlassCircleButton(
          icon: icon,
          size: 58,
          iconSize: 24,
          iconColor: AppColors.gold,
          semanticLabel: label,
          onTap: onTap,
        ),
        SizedBox(height: context.h(6)),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textPrimary,
            fontSize: context.sp(11),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            const Positioned.fill(child: GlassAmbientBackground()),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: r.maxContentWidth),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            r.pagePadding,
                            context.h(10),
                            r.pagePadding,
                            context.h(36) + MediaQuery.paddingOf(context).bottom,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppFadeAnimation(
                                delay: const Duration(milliseconds: 60),
                                child: _buildHeroBanner(),
                              ),
                              SizedBox(height: context.h(16)),
                              AppFadeAnimation(
                                delay: const Duration(milliseconds: 100),
                                child: _buildStatsRow(),
                              ),
                              SizedBox(height: context.h(20)),
                              AppFadeAnimation(
                                delay: const Duration(milliseconds: 140),
                                child: _buildCodeVault(),
                              ),
                              SizedBox(height: context.h(20)),
                              AppFadeAnimation(
                                delay: const Duration(milliseconds: 180),
                                child: _buildHowItWorks(),
                              ),
                              SizedBox(height: context.h(20)),
                              AppFadeAnimation(
                                delay: const Duration(milliseconds: 220),
                                child: _buildLedger(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header (replaces AppBar) ────────────────────────────────────────────

  Widget _buildHeader() {
    final r = context.responsive;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        r.pagePadding,
        context.h(8),
        r.pagePadding,
        context.h(4),
      ),
      child: Row(
        children: [
          GlassCircleButton(
            icon: Icons.arrow_back_ios_new_rounded,
            iconSize: 18,
            iconColor: AppColors.gold,
            semanticLabel: 'Back',
            onTap: () => Navigator.of(context).pop(),
          ),
          SizedBox(width: context.w(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REFERRAL PROGRAMME',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.gold,
                    fontSize: context.sp(10),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.4,
                  ),
                ),
                SizedBox(height: context.h(2)),
                Text(
                  'Refer & Earn',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: context.sp(26),
                    letterSpacing: -0.8,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 1. Hero ─────────────────────────────────────────────────────────────

  Widget _buildHeroBanner() {
    return GlassCard(
      radius: 30,
      blur: 0,
      fillAlpha: 0.10,
      tintGold: true,
      highlight: true,
      padding: EdgeInsets.all(context.r(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const StatusPill(
                label: 'MEMBER PRIVILEGE',
                icon: Icons.stars_rounded,
                color: AppColors.gold,
                fontSize: 9.5,
              ),
              Text(
                'Unlimited',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontSize: context.sp(11),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(18)),
          Row(
            children: [
              const NxGoldIconTile(
                icon: Icons.card_giftcard_rounded,
                size: 58,
                iconSize: 28,
                radius: 20,
              ),
              SizedBox(width: context.w(16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (rect) => const LinearGradient(
                        colors: AppColors.goldGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(rect),
                      child: Text(
                        'Give £50 · Earn £50',
                        style: AppTextStyles.headlineSmall.copyWith(
                          fontSize: context.sp(22),
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: context.h(4)),
                    Text(
                      'Every referral saves your friend £50 on booking and credits £50 to your concierge wallet upon completion.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: context.sp(11.5),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 2. Stats ────────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard(
          icon: Icons.account_balance_wallet_rounded,
          value: '£350',
          label: 'EARNED',
          accent: AppColors.gold,
        ),
        SizedBox(width: context.w(10)),
        _buildStatCard(
          icon: Icons.hourglass_top_rounded,
          value: '£100',
          label: 'PENDING',
          accent: _amber,
        ),
        SizedBox(width: context.w(10)),
        _buildStatCard(
          icon: Icons.group_add_rounded,
          value: '7',
          label: 'INVITED',
          accent: AppColors.success,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color accent,
  }) {
    return Expanded(
      child: GlassCard(
        radius: 22,
        blur: 0,
        fillAlpha: 0.08,
        edgeTint: accent,
        padding: EdgeInsets.symmetric(
          vertical: context.h(14),
          horizontal: context.w(8),
        ),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.14),
                  border: Border.all(color: accent.withValues(alpha: 0.40)),
                ),
                child: Icon(icon, color: accent, size: 16),
              ),
              SizedBox(height: context.h(10)),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: context.sp(20),
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              SizedBox(height: context.h(3)),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: context.sp(9),
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 3. Code vault ───────────────────────────────────────────────────────

  Widget _buildCodeVault() {
    final accent = _isCopied ? AppColors.success : AppColors.gold;

    return GlassCard(
      radius: 28,
      blur: 0,
      fillAlpha: 0.09,
      padding: EdgeInsets.all(context.r(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const NxSectionTitle('YOUR EXCLUSIVE CODE'),
              Text(
                'Tap to copy',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.gold.withValues(alpha: 0.85),
                  fontSize: context.sp(10.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(12)),
          Pressable(
            onTap: _copyCode,
            scale: 0.98,
            semanticLabel: 'Copy referral code',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: context.w(16),
                vertical: context.h(13),
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: accent.withValues(alpha: 0.65),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.18),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.vpn_key_rounded, size: 16, color: accent),
                  SizedBox(width: context.w(10)),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _referralCode,
                        style: AppTextStyles.headlineLarge.copyWith(
                          color: AppColors.gold,
                          fontSize: context.sp(20),
                          letterSpacing: 3.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: context.w(8)),
                  StatusPill(
                    label: _isCopied ? 'COPIED' : 'COPY',
                    icon: _isCopied
                        ? Icons.check_circle_rounded
                        : Icons.copy_rounded,
                    color: accent,
                    fontSize: 9.5,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: context.h(16)),
          GoldButton(
            label: 'Share Invitation Link',
            icon: Icons.share_rounded,
            height: 52,
            shine: true,
            onTap: _shareInvite,
          ),
        ],
      ),
    );
  }

  // ─── 4. How it works ─────────────────────────────────────────────────────

  Widget _buildHowItWorks() {
    return GlassCard(
      radius: 28,
      blur: 0,
      fillAlpha: 0.08,
      padding: EdgeInsets.all(context.r(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.auto_awesome_rounded, 'How It Works'),
          SizedBox(height: context.h(18)),
          _buildMilestoneStep(
            stepNumber: '1',
            title: 'Share your exclusive link',
            subtitle:
                'Send code $_referralCode to your circle via WhatsApp, message, or email.',
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
    );
  }

  Widget _cardTitle(IconData icon, String text) {
    return Row(
      children: [
        NxGoldIconTile(icon: icon, size: 32, iconSize: 16, radius: 10),
        SizedBox(width: context.w(10)),
        Text(
          text,
          style: AppTextStyles.titleMedium.copyWith(
            fontSize: context.sp(16),
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildMilestoneStep({
    required String stepNumber,
    required String title,
    required String subtitle,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: AppColors.goldGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    stepNumber,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textOnGold,
                      fontWeight: FontWeight.w900,
                      fontSize: context.sp(12),
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.gold.withValues(alpha: 0.6),
                          AppColors.gold.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: context.w(14)),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : context.h(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: context.sp(13.5),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: context.h(3)),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: context.sp(11.5),
                      height: 1.4,
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

  // ─── 5. Ledger ───────────────────────────────────────────────────────────

  Widget _buildLedger() {
    final referrals = _store.referrals;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _cardTitle(Icons.history_rounded, 'Referral Ledger'),
            StatusPill(
              label: '${referrals.length} TOTAL',
              icon: Icons.groups_rounded,
              color: AppColors.gold,
              fontSize: 9.5,
            ),
          ],
        ),
        SizedBox(height: context.h(14)),
        GlassCard(
          radius: 28,
          blur: 0,
          fillAlpha: 0.08,
          child: Column(
            children: [
              for (var i = 0; i < referrals.length; i++) ...[
                _buildLedgerRow(referrals[i]),
                if (i != referrals.length - 1)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: context.w(16)),
                    child: const GlassHairline(),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  ({Color color, String label, IconData icon}) _statusMeta(String status) {
    switch (status.toLowerCase()) {
      case 'moved':
        return (
          color: AppColors.success,
          label: 'COMPLETED',
          icon: Icons.check_circle_rounded,
        );
      case 'booked':
        return (
          color: _amber,
          label: 'BOOKED',
          icon: Icons.event_available_rounded,
        );
      default:
        return (
          color: AppColors.textMuted,
          label: 'PENDING',
          icon: Icons.hourglass_empty_rounded,
        );
    }
  }

  Widget _buildLedgerRow(dynamic item) {
    final meta = _statusMeta(item.status as String);
    final amount = item.amount as String;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(16),
        vertical: context.h(14),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withValues(alpha: 0.12),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
            ),
            child: Center(
              child: Text(
                item.initials as String,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w800,
                  fontSize: context.sp(12),
                ),
              ),
            ),
          ),
          SizedBox(width: context.w(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: context.sp(13.5),
                  ),
                ),
                SizedBox(height: context.h(5)),
                StatusPill(
                  label: meta.label,
                  icon: meta.icon,
                  color: meta.color,
                  fontSize: 9,
                ),
              ],
            ),
          ),
          SizedBox(width: context.w(8)),
          Text(
            amount,
            style: AppTextStyles.titleMedium.copyWith(
              color: amount.startsWith('+')
                  ? AppColors.gold
                  : AppColors.textMuted,
              fontWeight: FontWeight.w900,
              fontSize: context.sp(15),
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}
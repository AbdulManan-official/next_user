import 'package:flutter/material.dart';
import '../auth/views/login_view.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';
import '../utils/app_theme_styles.dart';
import '../utils/map_launcher_helper.dart';
import '../utils/responsive_helper.dart';
import '../widgets/animation_helper.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/logout_dialog.dart';
import '../controllers/move_store.dart';
import 'chat_screen.dart';
import 'live_tracking_screen.dart';
import 'refer_earn_screen.dart';

/// Responsive Home Screen for Luxury Moving Concierge App.
/// Matches Next Gen design standards with ambient golden glows and balanced card previews.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onSwitchToTab,
  });

  final ValueChanged<int> onSwitchToTab;

  void _onSignOut(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to log out of your account?',
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

  @override
  Widget build(BuildContext context) {
    final store = MoveStore.instance;
    final r = context.responsive;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: r.maxContentWidth),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            r.pagePadding,
            context.h(10),
            r.pagePadding,
            16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -----------------------------------------------------------------
              // 1. Top Header (Gold Avatar, Welcome Title & Red Action Button)
              // -----------------------------------------------------------------
              AppFadeAnimation(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          // Circular glowing gold user avatar
                          Container(
                            width: context.r(46),
                            height: context.r(46),
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.gold.withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.person_rounded,
                              color: AppColors.textOnGold,
                              size: context.r(24),
                            ),
                          ),
                          SizedBox(width: context.w(12)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Builder(
                                  builder: (context) {
                                    final userData = SessionService.instance.userData;
                                    final fullName = userData?['name']?.toString() ?? '';
                                    final tier = userData?['tier']?.toString().toUpperCase() ?? 'MEMBER';
                                    final displayName = fullName.trim().isEmpty
                                        ? 'there'
                                        : fullName.trim().split(' ').first;

                                    final h = DateTime.now().hour;
                                    final greeting = h < 12
                                        ? 'Good morning'
                                        : h < 17
                                            ? 'Good afternoon'
                                            : 'Good evening';

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tier,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.overline.copyWith(
                                            fontSize: context.sp(10),
                                            letterSpacing: 1.8,
                                          ),
                                        ),
                                        SizedBox(height: context.h(2)),
                                        Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(
                                                text: '$greeting, ',
                                                style: AppTextStyles.titleLarge.copyWith(
                                                  fontSize: context.sp(17),
                                                  color: AppColors.textPrimary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              TextSpan(
                                                text: displayName,
                                                style: AppTextStyles.titleLarge.copyWith(
                                                  color: AppColors.gold,
                                                  fontSize: context.sp(17),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: context.w(10)),
                    // Red-accented circular exit/logout button matching screenshot
                    InkWell(
                      onTap: () => _onSignOut(context),
                      borderRadius: BorderRadius.circular(context.r(24)),
                      child: Container(
                        width: context.r(42),
                        height: context.r(42),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.45),
                            width: 1.2,
                          ),
                        ),
                        child: Icon(
                          Icons.logout_rounded,
                          color: const Color(0xFFEF4444),
                          size: context.r(19),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.h(14)),

              // -----------------------------------------------------------------
              // 2. Active Transit / Move Overview Section (Well-proportioned)
              // -----------------------------------------------------------------
              ListenableBuilder(
                listenable: store,
                builder: (context, _) {
                  final activeMove = store.activeMove;

                  if (activeMove == null) {
                    return _buildAltHeroCard(context);
                  }

                  return AppFadeAnimation(
                    delay: const Duration(milliseconds: 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Active Move Overview',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontSize: context.sp(15),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            SizedBox(width: context.w(8)),
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  AnimationHelper.smoothRoute(
                                    page: const LiveTrackingScreen(),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(context.r(14)),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.w(10),
                                  vertical: context.h(4),
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  borderRadius:
                                      BorderRadius.circular(context.r(14)),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: context.r(11),
                                      color: AppColors.gold,
                                    ),
                                    SizedBox(width: context.w(4)),
                                    Text(
                                      'Live >',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.gold,
                                        fontSize: context.sp(10.5),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: context.h(8)),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              AnimationHelper.smoothRoute(
                                page: const LiveTrackingScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(context.r(22)),
                          child: Container(
                            padding: EdgeInsets.all(context.r(15)),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius:
                                  BorderRadius.circular(context.r(22)),
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.28),
                                width: 1.2,
                              ),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF261D15),
                                  Color(0xFF1B140E),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.gold.withValues(alpha: 0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top row: In Transit badge & Ref
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: context.w(8),
                                        vertical: context.h(3),
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.success
                                            .withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(
                                                context.r(12)),
                                        border: Border.all(
                                          color: AppColors.success
                                              .withValues(alpha: 0.45),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: context.r(6),
                                            height: context.r(6),
                                            decoration:
                                                const BoxDecoration(
                                              color: AppColors.success,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          SizedBox(width: context.w(5)),
                                          Text(
                                            'In Transit',
                                            style: AppTextStyles.labelSmall
                                                .copyWith(
                                              color: AppColors.success,
                                              fontSize: context.sp(10.5),
                                              fontWeight: FontWeight.w700,
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
                                            BorderRadius.circular(
                                                context.r(10)),
                                        border: Border.all(
                                          color: AppColors.gold
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Text(
                                        activeMove.ref,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.gold,
                                          fontSize: context.sp(11),
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: context.h(10)),
                                // Title
                                Text(
                                  activeMove.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.headlineSmall.copyWith(
                                    fontSize: context.sp(16.5),
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: context.h(8)),
                                // Route container matching reference screenshot (Clickable to Map)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: context.w(12),
                                    vertical: context.h(10),
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceElevated
                                        .withValues(alpha: 0.75),
                                    borderRadius:
                                        BorderRadius.circular(context.r(14)),
                                    border: Border.all(
                                      color: AppColors.border
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // From Row (Clickable to Map)
                                      InkWell(
                                        onTap: () {
                                          MapLauncherHelper.openMap(
                                            address: activeMove.fromAddress,
                                          );
                                        },
                                        borderRadius:
                                            BorderRadius.circular(context.r(8)),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: context.h(2),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: context.r(7.5),
                                                height: context.r(7.5),
                                                decoration:
                                                    const BoxDecoration(
                                                  color: AppColors.gold,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              SizedBox(width: context.w(10)),
                                              Expanded(
                                                child: Text(
                                                  activeMove.fromAddress,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: AppTextStyles
                                                      .bodyMedium
                                                      .copyWith(
                                                    color: AppColors
                                                        .textPrimary,
                                                    fontSize:
                                                        context.sp(12.5),
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: context.w(8)),
                                              Icon(
                                                Icons.open_in_new_rounded,
                                                size: context.r(15),
                                                color: AppColors.textMuted,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Connecting vertical line
                                      Container(
                                        margin: EdgeInsets.only(
                                          left: context.r(3),
                                          top: context.h(2),
                                          bottom: context.h(2),
                                        ),
                                        width: 1.5,
                                        height: context.h(12),
                                        color: AppColors.border
                                            .withValues(alpha: 0.8),
                                      ),
                                      // To Row (Clickable to Map)
                                      InkWell(
                                        onTap: () {
                                          MapLauncherHelper.openMap(
                                            address: activeMove.toAddress,
                                          );
                                        },
                                        borderRadius:
                                            BorderRadius.circular(context.r(8)),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: context.h(2),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.location_on_rounded,
                                                size: context.r(14),
                                                color:
                                                    const Color(0xFFEF4444),
                                              ),
                                              SizedBox(width: context.w(8)),
                                              Expanded(
                                                child: Text(
                                                  activeMove.toAddress,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: AppTextStyles
                                                      .bodyMedium
                                                      .copyWith(
                                                    color: AppColors
                                                        .textPrimary,
                                                    fontSize:
                                                        context.sp(12.5),
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: context.w(8)),
                                              Icon(
                                                Icons.open_in_new_rounded,
                                                size: context.r(15),
                                                color: AppColors.textMuted,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: context.h(10)),
                                // Date & Action button (Responsive & Overflow-safe)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.calendar_today_outlined,
                                            size: context.r(12),
                                            color: AppColors.textMuted,
                                          ),
                                          SizedBox(width: context.w(5)),
                                          Expanded(
                                            child: Text(
                                              activeMove.dateString,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                color: AppColors.textMuted,
                                                fontSize: context.sp(11),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: context.w(8)),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: context.w(10),
                                        vertical: context.h(6),
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: AppColors.goldLinearGradient,
                                        borderRadius: BorderRadius.circular(
                                            context.r(10)),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.gold
                                                .withValues(alpha: 0.35),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.near_me_rounded,
                                            size: context.r(12),
                                            color: AppColors.textOnGold,
                                          ),
                                          SizedBox(width: context.w(4)),
                                          Text(
                                            'Track Live',
                                            style: AppTextStyles.labelMedium
                                                .copyWith(
                                              color: AppColors.textOnGold,
                                              fontSize: context.sp(11),
                                              fontWeight: FontWeight.w800,
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
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: context.h(14)),

              // -----------------------------------------------------------------
              // 3. Quick Actions Grid (With Golden Amber Glow)
              // -----------------------------------------------------------------
              AppFadeAnimation(
                delay: const Duration(milliseconds: 150),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: context.w(3.5),
                          height: context.h(16),
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(context.r(2)),
                          ),
                        ),
                        SizedBox(width: context.w(8)),
                        Text(
                          'Member Tools & Services',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontSize: context.sp(15),
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.h(10)),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: r.gridColumns(
                        mobile: 2,
                        tablet: 4,
                        desktop: 4,
                      ),
                      mainAxisSpacing: context.h(10),
                      crossAxisSpacing: context.w(11),
                      childAspectRatio: 1.02,
                      children: [
                        _buildQuickActionTile(
                          context,
                          title: 'Book a move',
                          subtitle: 'Instant quote & booking',
                          icon: Icons.local_shipping_rounded, // Truck icon from screenshot
                          onTap: () => onSwitchToTab(1),
                        ),
                        _buildQuickActionTile(
                          context,
                          title: 'Contact',
                          subtitle: 'Direct call & support',
                          icon: Icons.badge_rounded, // Contact Staff icon from screenshot
                          onTap: () {
                            Navigator.push(
                              context,
                              AnimationHelper.smoothRoute(
                                page: const ChatScreen(
                                  chatType: ChatType.concierge,
                                ),
                              ),
                            );
                          },
                        ),
                        _buildQuickActionTile(
                          context,
                          title: 'My moves',
                          subtitle: 'Active & past jobs',
                          icon: Icons.insert_chart_rounded, // Job Reports icon from screenshot
                          onTap: () => onSwitchToTab(2),
                        ),
                        _buildQuickActionTile(
                          context,
                          title: 'Refer & earn',
                          subtitle: 'Invite & earn',
                          icon: Icons.people_alt_rounded, // Clients icon from screenshot
                          onTap: () {
                            Navigator.push(
                              context,
                              AnimationHelper.smoothRoute(
                                page: const ReferEarnScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(context.r(22)),
      child: Container(
        padding: EdgeInsets.all(context.r(14)),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(context.r(22)),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.28),
            width: 1.2,
          ),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF271E16),
              Color(0xFF1B140E),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.13),
              blurRadius: 18,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Glowing Icon Box matching reference screenshot
                Container(
                  padding: EdgeInsets.all(context.r(9)),
                  decoration: BoxDecoration(
                    color: const Color(0xFF352618),
                    borderRadius: BorderRadius.circular(context.r(14)),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.45),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.26),
                        blurRadius: 12,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: isDisabled ? AppColors.textMuted : AppColors.goldLight,
                    size: context.r(22),
                  ),
                ),
                // Circular chevron arrow button matching reference screenshot
                Container(
                  padding: EdgeInsets.all(context.r(5)),
                  decoration: BoxDecoration(
                    color: const Color(0xFF261D15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.7),
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.textMuted,
                    size: context.r(10),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: isDisabled
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                    fontSize: context.sp(13.5),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: context.h(3)),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    fontSize: context.sp(11),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAltHeroCard(BuildContext context) {
    return InkWell(
      onTap: () => onSwitchToTab(1),
      borderRadius: BorderRadius.circular(context.r(20)),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(15),
          vertical: context.h(13),
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(context.r(20)),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.28),
            width: 1.2,
          ),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF261D15),
              Color(0xFF1B140E),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(context.r(9)),
              decoration: BoxDecoration(
                color: const Color(0xFF352618),
                borderRadius: BorderRadius.circular(context.r(13)),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.45),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                Icons.add_circle_outline_rounded,
                color: AppColors.goldLight,
                size: context.r(20),
              ),
            ),
            SizedBox(width: context.w(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plan your next move',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontSize: context.sp(14),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: context.h(2)),
                  Text(
                    'White-glove luxury relocation service',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      fontSize: context.sp(11),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: context.r(12),
              color: AppColors.gold,
            ),
          ],
        ),
      ),
    );
  }
}

/// Scroll only when content truly overflows the viewport by more than
/// [minScrollExtent] pixels. This prevents ghost-scrolling / blank-space on
/// phones where the content almost fills the screen but bottom padding tips it over.
class TolerantClampingPhysics extends ClampingScrollPhysics {
  const TolerantClampingPhysics({this.minScrollExtent = 56, super.parent});

  /// Minimum px of overflow required before user scroll is accepted.
  final double minScrollExtent;

  @override
  TolerantClampingPhysics applyTo(ScrollPhysics? ancestor) =>
      TolerantClampingPhysics(
        minScrollExtent: minScrollExtent,
        parent: buildParent(ancestor),
      );

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) =>
      position.maxScrollExtent > minScrollExtent;
}

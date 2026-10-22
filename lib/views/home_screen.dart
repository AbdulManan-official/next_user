import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../auth/views/login_view.dart';
import '../controllers/move_store.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';
import '../utils/app_theme_styles.dart';
import '../utils/map_launcher_helper.dart';
import '../utils/responsive_helper.dart';
import '../widgets/animation_helper.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/glass_kit.dart';
import '../widgets/logout_dialog.dart';
import 'chat_screen.dart';
import 'live_tracking_screen.dart';
import 'refer_earn_screen.dart';

/// Customer home — luxury dark, gold & frosted glass.
///
/// Structure:
///  • One CustomScrollView (slivers) → header scrolls away like an Apple
///    large title. Grid is lazy (SliverGrid).
///  • Only [_ActiveMoveSection] listens to MoveStore → nothing else rebuilds.
///  • Only the hero card uses backdrop blur. Grid tiles use blur: 0.
///  • Everything generic comes from glass_kit.dart.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onSwitchToTab});

  final ValueChanged<int> onSwitchToTab;

  // ── Actions (logic unchanged) ──────────────────────────────────────────────

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to log out of your account?',
      confirmText: 'Sign Out',
      isDanger: true,
    );
    if (confirmed != true || !context.mounted) return;

    await AuthService.instance.signOut();
    if (!context.mounted) return;

    AppSnackBar.showSuccess(context, 'Signed out successfully.');
    Navigator.of(context).pushAndRemoveUntil(
      AnimationHelper.smoothRoute(page: const LoginView()),
      (route) => false,
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(AnimationHelper.smoothRoute(page: page));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final width = MediaQuery.sizeOf(context).width;
    // Centers content on tablets, plain page padding on phones.
    final side = math.max(r.pagePadding, (width - r.maxContentWidth) / 2);

    return Stack(
      children: [
        const Positioned.fill(child: GlassAmbientBackground()),
        CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              // Host Scaffold uses extendBody: true → body runs under the
              // floating bar. paddingOf.bottom = bar height + safe area, so
              // the last row always scrolls clear of the bar.
              padding: EdgeInsets.fromLTRB(
                side,
                context.h(10),
                side,
                16 + MediaQuery.paddingOf(context).bottom,
              ),
              sliver: SliverMainAxisGroup(
                slivers: [
                  SliverToBoxAdapter(
                    child: AppFadeAnimation(
                      child: _Header(onSignOut: () => _signOut(context)),
                    ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: context.h(18))),
                  SliverToBoxAdapter(
                    child: AppFadeAnimation(
                      delay: const Duration(milliseconds: 100),
                      child: _ActiveMoveSection(
                        onPlanMove: () => onSwitchToTab(1),
                        onOpenLive: () =>
                            _open(context, const LiveTrackingScreen()),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: context.h(20))),
                  const SliverToBoxAdapter(
                    child: _SectionHeader(title: 'Quick Services'),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: context.h(12))),
                  SliverGrid.count(
                    crossAxisCount:
                        r.gridColumns(mobile: 2, tablet: 4, desktop: 4),
                    mainAxisSpacing: context.h(12),
                    crossAxisSpacing: context.w(12),
                    childAspectRatio: 1.02,
                    children: [
                      _fade(
                        0,
                        _ServiceTile(
                          title: 'Book Move',
                          subtitle: 'Instant quote',
                          icon: Icons.local_shipping_rounded,
                          onTap: () => onSwitchToTab(1),
                        ),
                      ),
                      _fade(
                        1,
                        _ServiceTile(
                          title: 'My Moves',
                          subtitle: 'Jobs & history',
                          icon: Icons.insert_chart_rounded,
                          onTap: () => onSwitchToTab(2),
                        ),
                      ),
                      _fade(
                        2,
                        _ServiceTile(
                          title: 'Support',
                          subtitle: '24/7 Live chat',
                          icon: Icons.support_agent_rounded,
                          onTap: () => _open(
                            context,
                            const ChatScreen(chatType: ChatType.concierge),
                          ),
                        ),
                      ),
                      _fade(
                        3,
                        _ServiceTile(
                          title: 'Refer & Earn',
                          subtitle: 'Invite friends',
                          icon: Icons.people_alt_rounded,
                          onTap: () =>
                              _open(context, const ReferEarnScreen()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _fade(int i, Widget child) => AppFadeAnimation(
        delay: Duration(milliseconds: 160 + i * 60),
        child: child,
      );
}

// ════════════════════════════════════════════════════════════════════════════
//  HEADER
// ════════════════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  const _Header({required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final fullName =
        SessionService.instance.userData?['name']?.toString().trim() ?? '';
    final name = fullName.isEmpty ? 'there' : fullName.split(' ').first;

    return Row(
      children: [
        _Avatar(size: context.r(50)),
        SizedBox(width: context.w(14)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Same header text style as the My Moves screen.
              Text(
                'PLATINUM RELOCATIONS',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.gold,
                  fontSize: context.sp(10),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.4,
                ),
              ),
              SizedBox(height: context.h(3)),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleLarge.copyWith(
                  color: Colors.white,
                  fontSize: context.sp(26),
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: context.w(10)),
        GlassCircleButton(
          icon: Icons.logout_rounded,
          iconColor: AppColors.error,
          iconSize: 20,
          semanticLabel: 'Sign out',
          onTap: onSignOut,
        ),
      ],
    );
  }
}

/// Gold avatar with glass ring + soft glow.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: AppColors.goldGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.38),
            blurRadius: 22,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        Icons.person_rounded,
        color: AppColors.textOnGold,
        size: size * 0.5,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  ACTIVE MOVE  (only this subtree listens to MoveStore)
// ════════════════════════════════════════════════════════════════════════════

/// Plain view data → card never touches the store model directly.
typedef _MoveView = ({
  String ref,
  String title,
  String from,
  String to,
  String date,
});

class _ActiveMoveSection extends StatelessWidget {
  const _ActiveMoveSection({
    required this.onPlanMove,
    required this.onOpenLive,
  });

  final VoidCallback onPlanMove;
  final VoidCallback onOpenLive;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MoveStore.instance,
      builder: (context, _) {
        final m = MoveStore.instance.activeMove;
        if (m == null) return _PlanMoveCard(onTap: onPlanMove);

        final view = (
          ref: '${m.ref}',
          title: '${m.title}',
          from: '${m.fromAddress}',
          to: '${m.toAddress}',
          date: '${m.dateString}',
        );

        return _ActiveMoveCard(move: view, onOpenLive: onOpenLive);
      },
    );
  }
}

class _ActiveMoveCard extends StatelessWidget {
  const _ActiveMoveCard({required this.move, required this.onOpenLive});

  final _MoveView move;
  final VoidCallback onOpenLive;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.985,
      onTap: onOpenLive,
      semanticLabel: 'Open live tracking for ${move.title}',
      // The one blurred surface on this screen.
      child: GlassCard(
        radius: 30,
        blur: 18,
        fillAlpha: 0.06,
        tintGold: true,
        highlight: true,
        padding: EdgeInsets.all(context.r(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 0. card header: title + live badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Active Move',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                      fontSize: context.sp(16),
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const StatusPill(
                  label: 'LIVE',
                  icon: Icons.sensors_rounded,
                  color: AppColors.gold,
                  fontSize: 10,
                ),
              ],
            ),
            SizedBox(height: context.h(10)),
            const GlassHairline(),
            SizedBox(height: context.h(12)),

            // 1. status + ref
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _TransitPill(),
                Flexible(child: NxBadge(text: move.ref, letterSpacing: 0.8)),
              ],
            ),
            SizedBox(height: context.h(12)),

            // 2. title + date (date never truncated, full width)
            Text(
              move.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textPrimary,
                fontSize: context.sp(16),
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                height: 1.15,
              ),
            ),
            SizedBox(height: context.h(5)),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: context.r(12),
                  color: AppColors.gold,
                ),
                SizedBox(width: context.w(6)),
                Expanded(
                  child: Text(
                    move.date,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: context.sp(12),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.h(12)),

            // 3. route
            _RouteWell(from: move.from, to: move.to),
            SizedBox(height: context.h(12)),

            // 4. action, full width
            GoldButton(
              label: 'Track Live',
              icon: Icons.near_me_rounded,
              height: 44,
              radius: 16,
              shine: true,
              onTap: onOpenLive,
            ),
          ],
        ),
      ),
    );
  }
}

/// "IN TRANSIT" pill with a pulsing halo dot.
class _TransitPill extends StatelessWidget {
  const _TransitPill();

  @override
  Widget build(BuildContext context) {
    const color = AppColors.success;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 12, 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _PulseDot(color: color),
          const SizedBox(width: 7),
          Text(
            'IN TRANSIT',
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontSize: context.sp(10),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

/// Core dot + expanding fading halo. Transform/opacity only → GPU cheap,
/// no layout. Stops when the user enabled "reduce motion".
class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});

  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _scale = Tween<double>(begin: 1, end: 2.4)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
    _fade = Tween<double>(begin: 0.55, end: 0)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = DecoratedBox(
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    );
    return RepaintBoundary(
      child: SizedBox(
        width: 14,
        height: 14,
        child: Stack(
          alignment: Alignment.center,
          children: [
            FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: SizedBox(width: 7, height: 7, child: dot),
              ),
            ),
            SizedBox(width: 7, height: 7, child: dot),
          ],
        ),
      ),
    );
  }
}

/// Origin → destination well. Tap a row to open maps.
class _RouteWell extends StatelessWidget {
  const _RouteWell({required this.from, required this.to});

  final String from;
  final String to;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.r(12)),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RouteRow(
            text: from,
            semanticLabel: 'Open pickup in maps',
            marker: const Icon(Icons.circle, color: AppColors.gold, size: 9),
            onTap: () => MapLauncherHelper.openMap(address: from),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 6.25, top: 5, bottom: 5),
            child: Container(
              width: 1.5,
              height: 16,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.gold.withValues(alpha: 0.7),
                    AppColors.error.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ),
          _RouteRow(
            text: to,
            semanticLabel: 'Open drop-off in maps',
            marker: const Icon(
              Icons.location_on_rounded,
              color: AppColors.error,
              size: 15,
            ),
            onTap: () => MapLauncherHelper.openMap(address: to),
          ),
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({
    required this.text,
    required this.marker,
    required this.onTap,
    required this.semanticLabel,
  });

  final String text;
  final Widget marker;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.98,
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: Row(
        children: [
          SizedBox(width: 14, child: Center(child: marker)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontSize: context.sp(12.5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.arrow_outward_rounded,
            color: AppColors.textMuted,
            size: 16,
          ),
        ],
      ),
    );
  }
}

// ── No active move ──────────────────────────────────────────────────────────

class _PlanMoveCard extends StatelessWidget {
  const _PlanMoveCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.985,
      onTap: onTap,
      semanticLabel: 'Plan a new move',
      child: GlassCard(
        radius: 26,
        blur: 18,
        fillAlpha: 0.07,
        tintGold: true,
        highlight: true,
        padding: EdgeInsets.all(context.r(16)),
        child: Row(
          children: [
            _GoldTile(
              icon: Icons.add_rounded,
              size: context.r(48),
              iconSize: context.r(24),
            ),
            SizedBox(width: context.w(14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plan New Move',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: context.sp(16),
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: context.h(3)),
                  Text(
                    'White-glove luxury relocation',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: context.sp(11.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_outward_rounded,
              size: context.r(18),
              color: AppColors.gold,
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  SECTION HEADER + SERVICES
// ════════════════════════════════════════════════════════════════════════════

/// Title + fading gold line.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontSize: context.sp(17),
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ),
        SizedBox(width: context.w(12)),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.gold.withValues(alpha: 0.45),
                  AppColors.gold.withValues(alpha: 0.0),
                ],
              ),
            ),
            child: const SizedBox(height: 1),
          ),
        ),
      ],
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: '$title. $subtitle',
      child: GlassCard(
        radius: 26,
        blur: 0, // grid tile: no blur → cheap, still reads as glass
        fillAlpha: 0.09,
        padding: EdgeInsets.all(context.r(15)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GoldTile(
                  icon: icon,
                  size: context.r(44),
                  iconSize: context.r(22),
                ),
                Icon(
                  Icons.arrow_outward_rounded,
                  color: AppColors.textMuted,
                  size: context.r(18),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: context.sp(15),
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                SizedBox(height: context.h(3)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: context.sp(11),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Gold gradient squircle tile. Candidate to move into glass_kit.dart
/// (driver + surveyor homes build the same tile inline).
class _GoldTile extends StatelessWidget {
  const _GoldTile({
    required this.icon,
    required this.size,
    required this.iconSize,
  });

  final IconData icon;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.32),
        gradient: const LinearGradient(
          colors: AppColors.goldGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.32)),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.30),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Icon(icon, color: AppColors.textOnGold, size: iconSize),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  SCROLL PHYSICS (kept here so existing imports of this file keep working)
// ════════════════════════════════════════════════════════════════════════════

/// Not used by this screen anymore (kept so other imports don't break).
/// Scroll only when content overflows by more than [minScrollExtent] px.
/// Stops ghost-scrolling when content almost fills the screen.
class TolerantClampingPhysics extends ClampingScrollPhysics {
  const TolerantClampingPhysics({this.minScrollExtent = 56, super.parent});

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
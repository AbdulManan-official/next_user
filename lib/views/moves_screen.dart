import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../controllers/move_store.dart';
import '../models/move_model.dart';
import '../utils/app_theme_styles.dart';
import '../utils/responsive_helper.dart';
import '../widgets/animation_helper.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/glass_kit.dart';
import 'live_tracking_screen.dart';
import 'move_detail_screen.dart';

enum MoveFilterTab { all, scheduled, inProgress, completed }

typedef _StatusMeta = ({Color color, String label, IconData icon});

const Color _skyBlue = Color(0xFF38BDF8);

const _StatusMeta _scheduledMeta = (
  color: AppColors.gold,
  label: 'SCHEDULED',
  icon: Icons.event_available_rounded,
);
const _StatusMeta _transitMeta = (
  color: _skyBlue,
  label: 'IN TRANSIT',
  icon: Icons.local_shipping_rounded,
);
const _StatusMeta _completedMeta = (
  color: AppColors.success,
  label: 'COMPLETED',
  icon: Icons.check_circle_rounded,
);

/// Moves list — luxury dark, gold & frosted glass.
///
/// Layout (one CustomScrollView):
///  1. Title header        → scrolls away (Apple large-title behaviour)
///  2. Search + chips      → PINNED. Stay on top while the list scrolls,
///                           get a blurred glass backing once content slides
///                           under them.
///  3. Sections + cards    → lazy SliverList.
class MovesScreen extends StatefulWidget {
  const MovesScreen({super.key, this.ownBackground = true});

  /// Set false if parent shell already paints [GlassAmbientBackground].
  final bool ownBackground;

  @override
  State<MovesScreen> createState() => _MovesScreenState();
}

class _MovesScreenState extends State<MovesScreen> {
  final TextEditingController _search = TextEditingController();
  MoveFilterTab _filter = MoveFilterTab.all;

  // Glow sync: the pinned bar paints the SAME gold orb as the screen
  // background, positioned from its live on-screen position → seamless.
  final ScrollController _scroll = ScrollController();
  final GlobalKey _rootKey = GlobalKey();
  final GlobalKey _glowKey = GlobalKey();

  /// Pinned bar height is MEASURED from its real content → no extra space,
  /// no overflow, whatever the search bar / text scale is.
  final GlobalKey _barKey = GlobalKey();
  double? _barHeight;

  void _measureBar() {
    if (!mounted) return;
    final box = _barKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final h = box.size.height;
    if (_barHeight == null || (_barHeight! - h).abs() > 0.5) {
      setState(() => _barHeight = h);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _unfocus() => FocusManager.instance.primaryFocus?.unfocus();

  void _openDetail(MoveModel move) {
    Navigator.of(context).push(
      AnimationHelper.smoothRoute(page: MoveDetailScreen(move: move)),
    );
  }

  void _openTracking() {
    Navigator.of(context).push(
      AnimationHelper.smoothRoute(page: const LiveTrackingScreen()),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final width = MediaQuery.sizeOf(context).width;
    final side = math.max(r.pagePadding, (width - r.maxContentWidth) / 2);

    final body = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _unfocus,
      // Rebuilds only on store change or search text change.
      child: ListenableBuilder(
        listenable: Listenable.merge([MoveStore.instance, _search]),
        builder: (context, _) => _buildScroll(context, side),
      ),
    );

    final root = widget.ownBackground
        ? Stack(
            children: [
              const Positioned.fill(child: GlassAmbientBackground()),
              body,
            ],
          )
        : body;
    return KeyedSubtree(key: _rootKey, child: root);
  }

  Widget _buildScroll(BuildContext context, double side) {
    final store = MoveStore.instance;
    final active = store.activeMove;

    final inProgress = (active != null && active.status == MoveStatus.inTransit)
        ? <MoveModel>[active]
        : const <MoveModel>[];
    final scheduled = store.scheduledMoves;
    final past = store.pastMoves;

    final total = inProgress.length + scheduled.length + past.length;

    final query = _search.text.trim().toLowerCase();
    bool matches(MoveModel m) =>
        query.isEmpty ||
        m.title.toLowerCase().contains(query) ||
        m.ref.toLowerCase().contains(query) ||
        m.fromAddress.toLowerCase().contains(query) ||
        m.toAddress.toLowerCase().contains(query);

    final items = _buildItems(
      context,
      inProgress: inProgress.where(matches).toList(),
      scheduled: scheduled.where(matches).toList(),
      past: past.where(matches).toList(),
    );

    final bottomPad = context.h(24) + MediaQuery.paddingOf(context).bottom;
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureBar());

    return CustomScrollView(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        // 1. Title (scrolls away)
        SliverPadding(
          padding: EdgeInsets.fromLTRB(side, context.h(12), side, 0),
          sliver: SliverToBoxAdapter(
            child: AppFadeAnimation(child: _Header(total: total)),
          ),
        ),

        // 2. Search + chips (pinned, height = measured content)
        SliverPersistentHeader(
          pinned: true,
          delegate: _PinnedBarDelegate(
            height: _barHeight ?? context.r(104),
            side: side,
            repaint: _scroll,
            rootKey: _rootKey,
            glowKey: _glowKey,
            child: KeyedSubtree(
              key: _barKey,
              child: Padding(
                // small top gap under the title, small bottom gap above list
                padding: EdgeInsets.only(top: context.h(8), bottom: context.h(10)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomSearchBar(
                      controller: _search,
                      hintText: 'Search moves, reference, locations...',
                      // Rebuild is driven by the controller listener above.
                      onChanged: (_) {},
                      onClear: () {},
                    ),
                    SizedBox(height: context.h(10)),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'All ($total)',
                            selected: _filter == MoveFilterTab.all,
                            onTap: () => _setFilter(MoveFilterTab.all),
                          ),
                          _FilterChip(
                            label: 'Scheduled (${scheduled.length})',
                            selected: _filter == MoveFilterTab.scheduled,
                            onTap: () => _setFilter(MoveFilterTab.scheduled),
                          ),
                          _FilterChip(
                            label: 'Progress (${inProgress.length})',
                            selected: _filter == MoveFilterTab.inProgress,
                            onTap: () => _setFilter(MoveFilterTab.inProgress),
                          ),
                          _FilterChip(
                            label: 'Completed (${past.length})',
                            selected: _filter == MoveFilterTab.completed,
                            onTap: () => _setFilter(MoveFilterTab.completed),
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

        // 3. Sections + cards (lazy)
        SliverPadding(
          padding: EdgeInsets.fromLTRB(side, context.h(2), side, bottomPad),
          sliver: SliverList.builder(
            itemCount: items.length,
            itemBuilder: (_, i) => items[i],
          ),
        ),
      ],
    );
  }

  void _setFilter(MoveFilterTab tab) {
    if (_filter == tab) return;
    setState(() => _filter = tab);
  }

  // ── List items ─────────────────────────────────────────────────────────────

  List<Widget> _buildItems(
    BuildContext context, {
    required List<MoveModel> inProgress,
    required List<MoveModel> scheduled,
    required List<MoveModel> past,
  }) {
    bool allows(MoveFilterTab t) =>
        _filter == MoveFilterTab.all || _filter == t;

    final showScheduled = allows(MoveFilterTab.scheduled) && scheduled.isNotEmpty;
    final showInProgress =
        allows(MoveFilterTab.inProgress) && inProgress.isNotEmpty;
    final showPast = allows(MoveFilterTab.completed) && past.isNotEmpty;

    final gap = SizedBox(height: context.h(8));
    final items = <Widget>[];

    // Scheduled
    if (showScheduled) {
      items
        ..add(
          _SectionHeader(
            title: 'Upcoming scheduled',
            trailing: StatusPill(
              label: '${scheduled.length} SCHEDULED',
              icon: Icons.event_available_rounded,
              color: AppColors.gold,
              fontSize: 9.5,
            ),
          ),
        )
        ..addAll(
          scheduled.map(
            (m) => _MoveCard(
              key: ValueKey('s-${m.ref}'),
              move: m,
              meta: _scheduledMeta,
              onOpen: () => _openDetail(m),
              action: _MiniAction(
                label: 'Details',
                icon: Icons.arrow_forward_rounded,
                onTap: () => _openDetail(m),
              ),
            ),
          ),
        )
        ..add(gap);
    } else if (_filter == MoveFilterTab.scheduled) {
      items.add(const _EmptyState(
        icon: Icons.event_available_rounded,
        title: 'No scheduled moves',
        subtitle: 'Bookings scheduled for future dates will appear here.',
      ));
    }

    // In progress
    if (showInProgress) {
      items
        ..add(
          const _SectionHeader(
            title: 'Active transit',
            trailing: StatusPill(
              label: 'LIVE',
              icon: Icons.sensors_rounded,
              color: _skyBlue,
              fontSize: 9.5,
            ),
          ),
        )
        ..addAll(
          inProgress.map(
            (m) => _MoveCard(
              key: ValueKey('p-${m.ref}'),
              move: m,
              meta: _transitMeta,
              onOpen: () => _openDetail(m),
              action: _MiniAction(
                label: 'Track',
                icon: Icons.my_location_rounded,
                onTap: _openTracking,
              ),
            ),
          ),
        )
        ..add(gap);
    } else if (_filter == MoveFilterTab.inProgress) {
      items.add(const _EmptyState(
        icon: Icons.local_shipping_outlined,
        title: 'No active moves in progress',
        subtitle:
            'Active relocations currently in transit will appear here.',
      ));
    }

    // Completed
    if (showPast) {
      items
        ..add(
          _SectionHeader(
            title: 'Completed moves',
            trailing: Text(
              '${past.length} records',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: context.sp(11.5),
                color: AppColors.textMuted,
              ),
            ),
          ),
        )
        ..addAll(
          past.map(
            (m) => _MoveCard(
              key: ValueKey('c-${m.ref}'),
              move: m,
              meta: _completedMeta,
              completed: true,
              onOpen: () => _openDetail(m),
              action: _MiniAction(
                label: 'Invoice',
                icon: Icons.receipt_long_rounded,
                onTap: () => AppSnackBar.showSuccess(
                  context,
                  'Invoice for ${m.ref} downloaded.',
                ),
              ),
            ),
          ),
        );
    } else if (_filter == MoveFilterTab.completed) {
      items.add(const _EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'No completed moves',
        subtitle: 'Your completed relocation history will appear here.',
      ));
    }

    // "All" tab, nothing matched the search
    if (!showScheduled &&
        !showInProgress &&
        !showPast &&
        _filter == MoveFilterTab.all) {
      items.add(const _EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No moves matched',
        subtitle: 'Try searching with a different keyword.',
      ));
    }

    return items;
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  PINNED SEARCH + CHIPS
// ════════════════════════════════════════════════════════════════════════════

/// Pinned bar with a solid dark backing (AppColors.background, 100% opaque)
/// so nothing behind it shows while scrolling. The background's gold glow is
/// re-painted on top ([_BarGlowPainter]) so the header still looks like one
/// continuous glowing surface.
class _PinnedBarDelegate extends SliverPersistentHeaderDelegate {
  const _PinnedBarDelegate({
    required this.height,
    required this.side,
    required this.child,
    required this.repaint,
    required this.rootKey,
    required this.glowKey,
  });

  final double height;
  final double side;
  final Widget child;
  final Listenable repaint;
  final GlobalKey rootKey;
  final GlobalKey glowKey;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ColoredBox(
      color: AppColors.background,
      child: CustomPaint(
        key: glowKey,
        painter: _BarGlowPainter(
          repaint: repaint,
          rootKey: rootKey,
          selfKey: glowKey,
        ),
        child: SizedBox(
          height: height,
          child: OverflowBox(
            alignment: Alignment.topCenter,
            minHeight: 0,
            maxHeight: double.infinity,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: side),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedBarDelegate old) => true;
}

/// Paints the top-right gold orb of [GlassAmbientBackground]
/// (340px, right -100, top -130, gold @ 0.26) clipped to the bar, using the
/// bar's live position → glow lines up exactly with the background, at rest
/// and while pinned. If you change that orb in glass_kit, change it here.
class _BarGlowPainter extends CustomPainter {
  _BarGlowPainter({
    required Listenable repaint,
    required this.rootKey,
    required this.selfKey,
  }) : super(repaint: repaint);

  final GlobalKey rootKey;
  final GlobalKey selfKey;

  static const double _radius = 170; // 340 / 2
  static const double _centerFromRight = 70; // right -100 → 170 - 100
  static const double _centerY = 40; // top -130 → 170 - 130

  @override
  void paint(Canvas canvas, Size size) {
    final self = selfKey.currentContext?.findRenderObject();
    final root = rootKey.currentContext?.findRenderObject();
    if (self is! RenderBox || root is! RenderBox) return;
    if (!self.attached || !root.attached || !root.hasSize) return;

    final origin = self.localToGlobal(Offset.zero, ancestor: root);
    final center = Offset(
      root.size.width - _centerFromRight - origin.dx,
      _centerY - origin.dy,
    );

    // Glow fully below the bar → nothing to paint.
    if (center.dy - _radius > size.height) return;

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.gold.withValues(alpha: 0.26),
            AppColors.gold.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: _radius)),
    );
  }

  @override
  bool shouldRepaint(covariant _BarGlowPainter old) =>
      old.rootKey != rootKey || old.selfKey != selfKey;
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Pressable(
        scale: 0.94,
        onTap: onTap,
        semanticLabel: label,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: AppColors.goldGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: selected ? null : Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? Colors.white.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.14),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: selected ? AppColors.textOnGold : AppColors.textPrimary,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              fontSize: context.sp(12),
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  HEADER + SECTION TITLE
// ════════════════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  const _Header({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PLATINUM RELOCATIONS',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.gold,
            fontSize: context.sp(10),
            fontWeight: FontWeight.w700,
            letterSpacing: 2.4,
          ),
        ),
        SizedBox(height: context.h(3)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Moves',
              style: AppTextStyles.titleLarge.copyWith(
                fontSize: context.sp(26),
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                height: 1.1,
                color: AppColors.textPrimary,
              ),
            ),
            StatusPill(
              label: '$total TOTAL',
              icon: Icons.layers_rounded,
              color: AppColors.gold,
              fontSize: 10,
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.trailing});

  final String title;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleMedium.copyWith(
                fontSize: context.sp(16),
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  MOVE CARD (one card for scheduled / in transit / completed)
// ════════════════════════════════════════════════════════════════════════════

class _MoveCard extends StatelessWidget {
  const _MoveCard({
    super.key,
    required this.move,
    required this.meta,
    required this.action,
    required this.onOpen,
    this.completed = false,
  });

  final MoveModel move;
  final _StatusMeta meta;
  final Widget action;
  final VoidCallback onOpen;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(14)),
      child: Pressable(
        scale: 0.98,
        onTap: onOpen,
        semanticLabel: '${move.title}, ${meta.label}',
        child: GlassCard(
          radius: 28,
          blur: 0, // lists: no backdrop blur
          fillAlpha: 0.09,
          edgeTint: meta.color,
          padding: EdgeInsets.all(context.r(18)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StatusPill(
                    label: meta.label,
                    icon: meta.icon,
                    color: meta.color,
                    fontSize: 9.5,
                  ),
                  Flexible(
                    child: Text(
                      move.ref,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color:
                            completed ? AppColors.textMuted : AppColors.gold,
                        fontSize: context.sp(11.5),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.h(14)),
              Text(
                move.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleMedium.copyWith(
                  fontSize: context.sp(18),
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: context.h(12)),
              _RouteWell(from: move.fromAddress, to: move.toAddress),
              SizedBox(height: context.h(14)),
              const GlassHairline(),
              SizedBox(height: context.h(12)),
              Row(
                children: [
                  Expanded(
                    child: completed
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _DateRow(date: move.dateString),
                              SizedBox(height: context.h(4)),
                              const _Stars(),
                            ],
                          )
                        : _DateRow(date: move.dateString),
                  ),
                  SizedBox(width: context.w(8)),
                  Text(
                    '£${move.totalAmount}',
                    style: AppTextStyles.titleMedium.copyWith(
                      color:
                          completed ? AppColors.textPrimary : AppColors.gold,
                      fontSize: context.sp(16),
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(width: context.w(10)),
                  action,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.star_rounded, color: AppColors.gold, size: 13),
        Icon(Icons.star_rounded, color: AppColors.gold, size: 13),
        Icon(Icons.star_rounded, color: AppColors.gold, size: 13),
        Icon(Icons.star_rounded, color: AppColors.gold, size: 13),
        Icon(Icons.star_rounded, color: AppColors.gold, size: 13),
      ],
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.date});

  final String date;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.calendar_today_outlined,
          color: AppColors.textMuted,
          size: 13,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            date,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: context.sp(11),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

/// From → To timeline well.
class _RouteWell extends StatelessWidget {
  const _RouteWell({required this.from, required this.to});

  final String from;
  final String to;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          _RouteLine(
            text: from,
            marker: const Icon(Icons.circle, color: AppColors.gold, size: 9),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 6.25, top: 5, bottom: 5),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 1.5,
                height: 14,
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
          ),
          _RouteLine(
            text: to,
            marker: const Icon(
              Icons.location_on,
              color: AppColors.error,
              size: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  const _RouteLine({required this.text, required this.marker});

  final String text;
  final Widget marker;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 14, child: Center(child: marker)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontSize: context.sp(11.5),
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact gold-hairline action pill used in card footers.
class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.94,
      semanticLabel: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.40)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.gold,
                fontSize: context.sp(11.5),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 5),
            Icon(icon, size: 13, color: AppColors.gold),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  EMPTY STATE
// ════════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 30,
      blur: 0,
      fillAlpha: 0.09,
      padding: EdgeInsets.symmetric(
        vertical: context.r(36),
        horizontal: context.r(24),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.10),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.18),
                    blurRadius: 26,
                  ),
                ],
              ),
              child: Icon(icon, color: AppColors.gold, size: 32),
            ),
            SizedBox(height: context.h(16)),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium.copyWith(
                fontSize: context.sp(16),
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: context.h(6)),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: context.sp(12.5),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
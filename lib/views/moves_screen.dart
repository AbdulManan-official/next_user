import 'package:flutter/material.dart';
import '../utils/app_theme_styles.dart';
import '../utils/responsive_helper.dart';
import '../widgets/animation_helper.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/custom_search_bar.dart';
import '../models/move_model.dart';
import '../controllers/move_store.dart';
import 'live_tracking_screen.dart';
import 'move_detail_screen.dart';

enum MoveFilterTab { all, scheduled, inProgress, completed }

/// Responsive Moves Screen with screenshot-matched filter pills and search bar.
class MovesScreen extends StatefulWidget {
  const MovesScreen({super.key});

  @override
  State<MovesScreen> createState() => _MovesScreenState();
}

class _MovesScreenState extends State<MovesScreen> {
  final TextEditingController _searchController = TextEditingController();
  MoveFilterTab _selectedFilter = MoveFilterTab.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = MoveStore.instance;
    final r = context.responsive;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: r.maxContentWidth),
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final activeMove = store.activeMove;
            final scheduledMoves = store.scheduledMoves;
            final pastMoves = store.pastMoves;

            // In-transit moves: active move if status is inTransit
            final inProgressMoves = (activeMove != null &&
                    activeMove.status == MoveStatus.inTransit)
                ? [activeMove]
                : <MoveModel>[];

            final inProgressCount = inProgressMoves.length;
            final scheduledCount = scheduledMoves.length;
            final completedCount = pastMoves.length;
            final totalCount =
                inProgressCount + scheduledCount + completedCount;

            final query = _searchController.text.trim().toLowerCase();

            bool matchesQuery(MoveModel m) {
              if (query.isEmpty) return true;
              return m.title.toLowerCase().contains(query) ||
                  m.ref.toLowerCase().contains(query) ||
                  m.fromAddress.toLowerCase().contains(query) ||
                  m.toAddress.toLowerCase().contains(query);
            }

            final filteredInProgressMoves =
                inProgressMoves.where(matchesQuery).toList();
            final filteredScheduledMoves =
                scheduledMoves.where(matchesQuery).toList();
            final filteredPastMoves = pastMoves.where(matchesQuery).toList();

            final showInProgress = (_selectedFilter == MoveFilterTab.all ||
                    _selectedFilter == MoveFilterTab.inProgress) &&
                filteredInProgressMoves.isNotEmpty;

            final showScheduled = (_selectedFilter == MoveFilterTab.all ||
                    _selectedFilter == MoveFilterTab.scheduled) &&
                filteredScheduledMoves.isNotEmpty;

            final showPast = (_selectedFilter == MoveFilterTab.all ||
                    _selectedFilter == MoveFilterTab.completed) &&
                filteredPastMoves.isNotEmpty;

            return NotificationListener<ScrollNotification>(
              onNotification: (scrollInfo) {
                if (scrollInfo is UserScrollNotification ||
                    scrollInfo is ScrollUpdateNotification) {
                  FocusManager.instance.primaryFocus?.unfocus();
                }
                return false;
              },
              child: GestureDetector(
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                behavior: HitTestBehavior.translucent,
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  r.pagePadding,
                  context.h(12),
                  r.pagePadding,
                  context.h(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Screen Eyebrow & Title
                    AppFadeAnimation(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PLATINUM RELOCATIONS',
                            style: AppTextStyles.overline.copyWith(
                              fontSize: context.sp(10),
                              letterSpacing: 1.8,
                            ),
                          ),
                          SizedBox(height: context.h(3)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'My Moves',
                                style: AppTextStyles.titleLarge.copyWith(
                                  fontSize: context.sp(20),
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.w(10),
                                  vertical: context.h(4),
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  borderRadius:
                                      BorderRadius.circular(context.r(20)),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  '$totalCount Total',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.gold,
                                    fontSize: context.sp(10.5),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: context.h(14)),

                    // Interactive Professional Search Bar
                    AppFadeAnimation(
                      delay: const Duration(milliseconds: 40),
                      child: CustomSearchBar(
                        controller: _searchController,
                        hintText: 'Search moves, reference, locations...',
                        onChanged: (_) => setState(() {}),
                        onClear: () => setState(() {}),
                      ),
                    ),
                    SizedBox(height: context.h(12)),

                  // 4 Filter Pills (All, Scheduled, Progress, Completed)
                  AppFadeAnimation(
                    delay: const Duration(milliseconds: 70),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterPill(
                            tab: MoveFilterTab.all,
                            label: 'All ($totalCount)',
                          ),
                          SizedBox(width: context.w(8)),
                          _buildFilterPill(
                            tab: MoveFilterTab.scheduled,
                            label: 'Scheduled ($scheduledCount)',
                          ),
                          SizedBox(width: context.w(8)),
                          _buildFilterPill(
                            tab: MoveFilterTab.inProgress,
                            label: 'Progress ($inProgressCount)',
                          ),
                          SizedBox(width: context.w(8)),
                          _buildFilterPill(
                            tab: MoveFilterTab.completed,
                            label: 'Completed ($completedCount)',
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: context.h(18)),

                  // 1. Upcoming Scheduled Moves Section
                  if (showScheduled) ...[
                    AppFadeAnimation(
                      delay: const Duration(milliseconds: 100),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Upcoming scheduled',
                            style: AppTextStyles.titleMedium.copyWith(
                              fontSize: context.sp(14.5),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.w(8),
                              vertical: context.h(2),
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(context.r(12)),
                            ),
                            child: Text(
                              '${filteredScheduledMoves.length} Scheduled',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.gold,
                                fontSize: context.sp(10.5),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: context.h(10)),
                    ...filteredScheduledMoves.map(
                      (move) => Padding(
                        padding: EdgeInsets.only(bottom: context.h(12)),
                        child: _buildScheduledCard(context, move),
                      ),
                    ),
                    SizedBox(height: context.h(8)),
                  ] else if (_selectedFilter == MoveFilterTab.scheduled &&
                      filteredScheduledMoves.isEmpty) ...[
                    _buildEmptyState(
                      context,
                      icon: Icons.event_available_rounded,
                      title: 'No scheduled moves',
                      subtitle: 'Bookings scheduled for future dates will appear here.',
                    ),
                  ],

                  // 2. In-Progress / Active Transit Section
                  if (showInProgress) ...[
                    AppFadeAnimation(
                      delay: const Duration(milliseconds: 120),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Active transit',
                            style: AppTextStyles.titleMedium.copyWith(
                              fontSize: context.sp(14.5),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.w(8),
                              vertical: context.h(2),
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(context.r(12)),
                            ),
                            child: Text(
                              'Live',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.success,
                                fontSize: context.sp(10.5),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: context.h(10)),
                    ...filteredInProgressMoves.map(
                      (move) => Padding(
                        padding: EdgeInsets.only(bottom: context.h(12)),
                        child: _buildInProgressCard(context, move),
                      ),
                    ),
                    SizedBox(height: context.h(8)),
                  ] else if (_selectedFilter == MoveFilterTab.inProgress &&
                      filteredInProgressMoves.isEmpty) ...[
                    _buildEmptyState(
                      context,
                      icon: Icons.local_shipping_outlined,
                      title: 'No active moves in progress',
                      subtitle: 'Active relocations currently in transit will appear here.',
                    ),
                  ],

                  // 3. Completed Moves Section
                  if (showPast) ...[
                    AppFadeAnimation(
                      delay: const Duration(milliseconds: 140),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Completed moves',
                            style: AppTextStyles.titleMedium.copyWith(
                              fontSize: context.sp(14.5),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${filteredPastMoves.length} records',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: context.sp(11.5),
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: context.h(10)),
                    ...filteredPastMoves.map(
                      (move) => Padding(
                        padding: EdgeInsets.only(bottom: context.h(12)),
                        child: _buildPastMoveCard(context, move),
                      ),
                    ),
                  ] else if (_selectedFilter == MoveFilterTab.completed &&
                      filteredPastMoves.isEmpty) ...[
                    _buildEmptyState(
                      context,
                      icon: Icons.inventory_2_outlined,
                      title: 'No completed moves',
                      subtitle: 'Your completed relocation history will appear here.',
                    ),
                  ],

                  // All tab empty state (when search matches nothing across all categories)
                  if (!showInProgress &&
                      !showScheduled &&
                      !showPast &&
                      _selectedFilter == MoveFilterTab.all)
                    _buildEmptyState(
                      context,
                      icon: Icons.search_off_rounded,
                      title: 'No moves matched',
                      subtitle: 'Try searching with a different keyword.',
                    ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  ),
);
}

  Widget _buildFilterPill({
    required MoveFilterTab tab,
    required String label,
  }) {
    final isSelected = _selectedFilter == tab;

    return InkWell(
      onTap: () => setState(() => _selectedFilter = tab),
      borderRadius: BorderRadius.circular(context.r(20)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: context.w(14),
          vertical: context.h(7),
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(context.r(20)),
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.border,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? AppColors.textOnGold : AppColors.textSecondary,
            fontSize: context.sp(11.5),
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildInProgressCard(BuildContext context, MoveModel move) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          AnimationHelper.smoothRoute(
            page: MoveDetailScreen(move: move),
          ),
        );
      },
      borderRadius: BorderRadius.circular(context.r(22)),
      child: Container(
        padding: EdgeInsets.all(context.r(16)),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(context.r(22)),
          border: Border.all(color: AppColors.border, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status & Ref
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(9),
                    vertical: context.h(3.5),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(context.r(20)),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: context.r(6),
                        height: context.r(6),
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: context.w(5)),
                      Text(
                        'In Transit',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.success,
                          fontSize: context.sp(10.5),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  move.ref,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.gold,
                    fontSize: context.sp(11.5),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            SizedBox(height: context.h(10)),

            Text(
              move.title,
              style: AppTextStyles.headlineSmall.copyWith(
                fontSize: context.sp(15.5),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: context.h(5)),

            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: AppColors.gold,
                  size: context.r(14),
                ),
                SizedBox(width: context.w(5)),
                Expanded(
                  child: Text(
                    '${move.fromAddress} → ${move.toAddress}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: context.sp(11.5),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.h(12)),
            const Divider(height: 1),
            SizedBox(height: context.h(10)),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.textMuted,
                        size: context.r(13),
                      ),
                      SizedBox(width: context.w(5)),
                      Expanded(
                        child: Text(
                          move.dateString,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textMuted,
                            fontSize: context.sp(10.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: context.w(8)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '£${move.totalAmount}',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.gold,
                        fontSize: context.sp(15),
                        fontWeight: FontWeight.w800,
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
                      borderRadius: BorderRadius.circular(context.r(10)),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.w(8),
                          vertical: context.h(4),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(context.r(10)),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Track',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.gold,
                                fontSize: context.sp(11),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: context.w(3)),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: context.r(12),
                              color: AppColors.gold,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduledCard(BuildContext context, MoveModel move) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          AnimationHelper.smoothRoute(
            page: MoveDetailScreen(move: move),
          ),
        );
      },
      borderRadius: BorderRadius.circular(context.r(20)),
      child: Container(
        padding: EdgeInsets.all(context.r(16)),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(context.r(20)),
          border: Border.all(color: AppColors.border, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status & Ref
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(9),
                    vertical: context.h(3.5),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(context.r(20)),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.event_available_rounded,
                        color: AppColors.gold,
                        size: context.r(12),
                      ),
                      SizedBox(width: context.w(5)),
                      Text(
                        'Scheduled',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.gold,
                          fontSize: context.sp(10.5),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  move.ref,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.gold,
                    fontSize: context.sp(11.5),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            SizedBox(height: context.h(10)),

            Text(
              move.title,
              style: AppTextStyles.headlineSmall.copyWith(
                fontSize: context.sp(15.5),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: context.h(5)),

            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: AppColors.gold,
                  size: context.r(14),
                ),
                SizedBox(width: context.w(5)),
                Expanded(
                  child: Text(
                    '${move.fromAddress} → ${move.toAddress}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: context.sp(11.5),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.h(12)),
            const Divider(height: 1),
            SizedBox(height: context.h(10)),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.textMuted,
                        size: context.r(13),
                      ),
                      SizedBox(width: context.w(5)),
                      Expanded(
                        child: Text(
                          move.dateString,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textMuted,
                            fontSize: context.sp(10.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: context.w(8)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '£${move.totalAmount}',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.gold,
                        fontSize: context.sp(15),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: context.w(8)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(8),
                        vertical: context.h(4),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(context.r(10)),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Details',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.gold,
                              fontSize: context.sp(11),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: context.w(3)),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: context.r(12),
                            color: AppColors.gold,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPastMoveCard(BuildContext context, MoveModel move) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          AnimationHelper.smoothRoute(
            page: MoveDetailScreen(move: move),
          ),
        );
      },
      borderRadius: BorderRadius.circular(context.r(20)),
      child: Container(
        padding: EdgeInsets.all(context.r(15)),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(context.r(20)),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(8),
                    vertical: context.h(3),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(context.r(16)),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'Completed',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textMuted,
                      fontSize: context.sp(10),
                    ),
                  ),
                ),
                Text(
                  move.ref,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    fontSize: context.sp(11),
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            SizedBox(height: context.h(8)),

            Text(
              move.title,
              style: AppTextStyles.titleMedium.copyWith(
                fontSize: context.sp(14),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: context.h(3)),
            Text(
              '${move.fromAddress} → ${move.toAddress}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: context.sp(11.5),
              ),
            ),
            SizedBox(height: context.h(10)),
            const Divider(height: 1),
            SizedBox(height: context.h(10)),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        move.dateString,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMuted,
                          fontSize: context.sp(10.5),
                        ),
                      ),
                      SizedBox(height: context.h(2)),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            Icons.star_rounded,
                            color: AppColors.gold,
                            size: context.r(12),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: context.w(8)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '£${move.totalAmount}',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: context.sp(13.5),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: context.w(8)),
                    TextButton.icon(
                      onPressed: () {
                        AppSnackBar.showSuccess(
                          context,
                          'Invoice for ${move.ref} downloaded.',
                        );
                      },
                      icon: Icon(
                        Icons.receipt_long_rounded,
                        size: context.r(13),
                      ),
                      label: Text(
                        'Invoice',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.gold,
                          fontSize: context.sp(10.5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.gold,
                        padding: EdgeInsets.symmetric(
                          horizontal: context.w(8),
                          vertical: context.h(4),
                        ),
                        backgroundColor: AppColors.surfaceElevated,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(context.r(10)),
                          side: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.r(24)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(context.r(20)),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textMuted, size: context.r(36)),
          SizedBox(height: context.h(8)),
          Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              fontSize: context.sp(14),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: context.h(3)),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontSize: context.sp(11.5),
            ),
          ),
        ],
      ),
    );
  }
}

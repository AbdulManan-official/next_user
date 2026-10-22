import 'package:flutter/material.dart';
import '../models/move_model.dart';
import '../utils/app_theme_styles.dart';
import '../utils/responsive_helper.dart';
import '../widgets/animation_helper.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/concierge_call_sheet.dart';
import '../widgets/glass_kit.dart';
import '../widgets/rating_sheet.dart';
import 'chat_screen.dart';
import 'live_tracking_screen.dart';

/// Luxury Move Detail Screen matching the Next Gen gold & frosted glass design system.
class MoveDetailScreen extends StatelessWidget {
  const MoveDetailScreen({
    super.key,
    required this.move,
  });

  final MoveModel move;

  @override
  Widget build(BuildContext context) {
    final isCompleted = move.status == MoveStatus.completed;
    final isInTransit = move.status == MoveStatus.inTransit;
    final r = context.responsive;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const NxAmbientBackground(),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: r.maxContentWidth),
                child: Column(
                  children: [
                    // Luxury Frosted App Bar
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        context.w(16),
                        context.h(10),
                        context.w(16),
                        context.h(12),
                      ),
                      child: Row(
                        children: [
                          GlassCircleButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            iconColor: AppColors.gold,
                            iconSize: context.r(16),
                            size: context.r(40),
                            semanticLabel: 'Back',
                            onTap: () => Navigator.of(context).pop(),
                          ),
                          SizedBox(width: context.w(12)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'MOVE DOSSIER',
                                  style: AppTextStyles.overline.copyWith(
                                    color: AppColors.gold,
                                    fontSize: context.sp(9.5),
                                    letterSpacing: 1.8,
                                  ),
                                ),
                                SizedBox(height: context.h(2)),
                                Text(
                                  move.ref,
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: context.sp(15),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StatusPill(
                            label: isCompleted
                                ? 'COMPLETED'
                                : (isInTransit ? 'IN TRANSIT' : 'SCHEDULED'),
                            icon: isCompleted
                                ? Icons.check_circle_rounded
                                : (isInTransit
                                    ? Icons.local_shipping_rounded
                                    : Icons.event_available_rounded),
                            color: isCompleted
                                ? AppColors.textMuted
                                : (isInTransit
                                    ? AppColors.gold
                                    : AppColors.success),
                            fontSize: context.sp(9.5),
                          ),
                        ],
                      ),
                    ),

                    // Scrollable Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: r.pagePadding,
                          vertical: context.h(6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title & Date Header Card
                            AppFadeAnimation(
                              child: NxGlassPanel(
                                radius: 24,
                                fillAlpha: 0.09,
                                padding: EdgeInsets.all(context.r(18)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            move.title,
                                            style: AppTextStyles.headlineMedium
                                                .copyWith(
                                              fontSize: context.sp(19),
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                        ),
                                        NxBadge(
                                          text: 'PLATINUM',
                                          fontSize: context.sp(9),
                                          letterSpacing: 1.0,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: context.h(8)),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today_rounded,
                                          color: AppColors.gold,
                                          size: context.r(13),
                                        ),
                                        SizedBox(width: context.w(6)),
                                        Text(
                                          move.dateString,
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(
                                            color: AppColors.textSecondary,
                                            fontSize: context.sp(12.5),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const Spacer(),
                                        Icon(
                                          Icons.security_rounded,
                                          color: AppColors.gold,
                                          size: context.r(13),
                                        ),
                                        SizedBox(width: context.w(4)),
                                        Text(
                                          '£100k Insured',
                                          style: AppTextStyles.labelSmall
                                              .copyWith(
                                            color: AppColors.gold,
                                            fontSize: context.sp(10),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: context.h(14)),

                            // Route Block Card
                            AppFadeAnimation(
                              delay: const Duration(milliseconds: 70),
                              child: NxGlassPanel(
                                radius: 24,
                                fillAlpha: 0.08,
                                padding: EdgeInsets.all(context.r(18)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const NxSectionTitle('RELOCATION ROUTE'),
                                    SizedBox(height: context.h(12)),
                                    _buildRouteRow(
                                      context: context,
                                      isPickup: true,
                                      label: 'FROM (ORIGIN)',
                                      address: move.fromAddress,
                                      color: AppColors.gold,
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(
                                        left: context.r(18),
                                      ),
                                      child: Container(
                                        height: context.h(24),
                                        width: 1.5,
                                        color: Colors.white
                                            .withValues(alpha: 0.15),
                                      ),
                                    ),
                                    _buildRouteRow(
                                      context: context,
                                      isPickup: false,
                                      label: 'TO (DESTINATION RESIDENCE)',
                                      address: move.toAddress,
                                      color: AppColors.success,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: context.h(14)),

                            // Crew Specialist Lead Card
                            AppFadeAnimation(
                              delay: const Duration(milliseconds: 130),
                              child: NxGlassPanel(
                                radius: 24,
                                fillAlpha: 0.08,
                                padding: EdgeInsets.all(context.r(16)),
                                child: Row(
                                  children: [
                                    NxGoldIconTile(
                                      icon: Icons.badge_outlined,
                                      size: context.r(46),
                                      iconSize: context.r(22),
                                      radius: 15,
                                    ),
                                    SizedBox(width: context.w(13)),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            move.crewLeadName,
                                            style: AppTextStyles.titleMedium
                                                .copyWith(
                                              fontSize: context.sp(14.5),
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          SizedBox(height: context.h(2)),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.star_rounded,
                                                color: AppColors.gold,
                                                size: context.r(14),
                                              ),
                                              SizedBox(width: context.w(4)),
                                              Text(
                                                '${move.crewRating} · Lead Specialist',
                                                style: AppTextStyles.bodySmall
                                                    .copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: context.sp(11.5),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    GlassCircleButton(
                                      icon: Icons.chat_bubble_outline_rounded,
                                      iconColor: AppColors.gold,
                                      iconSize: context.r(17),
                                      size: context.r(38),
                                      semanticLabel: 'Chat with Specialist',
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          AnimationHelper.smoothRoute(
                                            page: const ChatScreen(
                                              chatType: ChatType.crew,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    SizedBox(width: context.w(8)),
                                    GlassCircleButton(
                                      icon: Icons.phone_rounded,
                                      iconColor: AppColors.gold,
                                      iconSize: context.r(17),
                                      size: context.r(38),
                                      semanticLabel: 'Call Specialist',
                                      onTap: () {
                                        ConciergeCallSheet.show(
                                          context,
                                          name: move.crewLeadName,
                                          role: 'Lead Specialist · On your move',
                                          avatarInitials: move.crewLeadInitials,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: context.h(14)),

                            // Price Breakdown Glass Card
                            AppFadeAnimation(
                              delay: const Duration(milliseconds: 180),
                              child: NxGlassPanel(
                                radius: 24,
                                fillAlpha: 0.08,
                                padding: EdgeInsets.all(context.r(18)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const NxSectionTitle('FINANCIAL BREAKDOWN'),
                                    SizedBox(height: context.h(14)),
                                    _buildPriceRow(
                                      context: context,
                                      label: 'Base white-glove relocation',
                                      value: '£${move.propertyType.basePrice}',
                                    ),
                                    if (move.services.isNotEmpty)
                                      ...move.services.map(
                                        (s) => _buildPriceRow(
                                          context: context,
                                          label: s.title,
                                          value: '+£${s.price}',
                                        ),
                                      )
                                    else ...[
                                      _buildPriceRow(
                                        context: context,
                                        label: 'Fine Art & Antique Packing',
                                        value: 'Included',
                                      ),
                                      _buildPriceRow(
                                        context: context,
                                        label: 'Platinum Transit Insurance',
                                        value: 'Included (£100k)',
                                      ),
                                    ],
                                    SizedBox(height: context.h(10)),
                                    const NxHairline(),
                                    SizedBox(height: context.h(12)),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Total Investment',
                                          style:
                                              AppTextStyles.titleLarge.copyWith(
                                            fontSize: context.sp(15),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          '£${move.totalAmount}',
                                          style: AppTextStyles.headlineSmall
                                              .copyWith(
                                            color: AppColors.gold,
                                            fontSize: context.sp(20),
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: context.h(18)),

                            // Live Tracking CTA if active
                            if (isInTransit) ...[
                              GoldButton(
                                label: 'Track Live Transit Vehicle',
                                icon: Icons.navigation_rounded,
                                height: context.h(48),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    AnimationHelper.smoothRoute(
                                      page: const LiveTrackingScreen(),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: context.h(10)),
                            ],

                            // Secondary Actions
                            GlassButton(
                              label: 'Download Tax Invoice',
                              icon: Icons.receipt_long_rounded,
                              height: context.h(48),
                              onTap: () {
                                AppSnackBar.showSuccess(
                                  context,
                                  'Tax invoice for ${move.ref} downloaded successfully.',
                                );
                              },
                            ),

                            if (isCompleted) ...[
                              SizedBox(height: context.h(10)),
                              GoldButton(
                                label: 'Review White-Glove Experience',
                                icon: Icons.star_rounded,
                                height: context.h(48),
                                onTap: () {
                                  RatingSheet.show(
                                    context,
                                    moveRef: move.ref,
                                    moveTitle: move.title,
                                  );
                                },
                              ),
                            ],
                            SizedBox(height: context.h(28)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteRow({
    required BuildContext context,
    required bool isPickup,
    required String label,
    required String address,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(top: context.h(2)),
          width: context.r(36),
          height: context.r(36),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: 0.45),
              width: 1.0,
            ),
          ),
          child: Icon(
            isPickup
                ? Icons.arrow_outward_rounded
                : Icons.arrow_downward_rounded,
            color: color,
            size: context.r(18),
          ),
        ),
        SizedBox(width: context.w(12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.overline.copyWith(
                  fontSize: context.sp(9),
                  color: AppColors.textMuted,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: context.h(3)),
              Text(
                address,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: context.sp(13),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(9)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontSize: context.sp(12.5),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontSize: context.sp(12.5),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

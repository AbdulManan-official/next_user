import 'package:flutter/material.dart';
import '../utils/app_theme_styles.dart';
import '../utils/responsive_helper.dart';
import '../widgets/animation_helper.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/custom_button.dart';
import '../models/move_model.dart';
import '../widgets/concierge_call_sheet.dart';
import '../widgets/rating_sheet.dart';
import 'chat_screen.dart';

/// Fully responsive Move Detail Screen.
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
              size: context.r(16),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'MOVE DETAILS',
              style: AppTextStyles.overline.copyWith(
                fontSize: context.sp(9.5),
                letterSpacing: 1.6,
              ),
            ),
            SizedBox(height: context.h(2)),
            Text(
              move.ref,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.gold,
                fontWeight: FontWeight.w700,
                fontSize: context.sp(14.5),
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: r.maxContentWidth),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: r.pagePadding,
                vertical: context.h(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header & Status Chip
                  AppFadeAnimation(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.w(10),
                            vertical: context.h(4),
                          ),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? AppColors.surfaceElevated
                                : AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(context.r(20)),
                            border: Border.all(
                              color: isCompleted
                                  ? AppColors.border
                                  : AppColors.success.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isCompleted) ...[
                                Container(
                                  width: context.r(6),
                                  height: context.r(6),
                                  decoration: const BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: context.w(5)),
                              ],
                              Text(
                                isCompleted
                                    ? 'Completed'
                                    : (isInTransit ? 'In Transit' : 'Scheduled'),
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: isCompleted
                                      ? AppColors.textMuted
                                      : AppColors.success,
                                  fontSize: context.sp(11),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          move.ref,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.gold,
                            fontSize: context.sp(12),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.h(12)),

                  // Title & Date
                  AppFadeAnimation(
                    delay: const Duration(milliseconds: 50),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          move.title,
                          style: AppTextStyles.headlineMedium.copyWith(
                            fontSize: context.sp(20),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: context.h(4)),
                        Text(
                          move.dateString,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: context.sp(13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.h(16)),

                  // Route Block Card
                  AppFadeAnimation(
                    delay: const Duration(milliseconds: 100),
                    child: Container(
                      padding: EdgeInsets.all(context.r(18)),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(context.r(22)),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          _buildRouteRow(
                            context: context,
                            isPickup: true,
                            label: 'FROM (PICKUP)',
                            address: move.fromAddress,
                            color: AppColors.gold,
                          ),
                          Container(
                            margin: EdgeInsets.only(left: context.r(5)),
                            height: context.h(20),
                            child: CustomPaint(
                              painter: _DottedLinePainter(),
                            ),
                          ),
                          _buildRouteRow(
                            context: context,
                            isPickup: false,
                            label: 'TO (DESTINATION)',
                            address: move.toAddress,
                            color: AppColors.success,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: context.h(16)),

                  // Crew Card
                  AppFadeAnimation(
                    delay: const Duration(milliseconds: 150),
                    child: Container(
                      padding: EdgeInsets.all(context.r(16)),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(context.r(22)),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: context.r(22),
                            backgroundColor: AppColors.surfaceElevated,
                            child: Text(
                              move.crewLeadInitials,
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w800,
                                fontSize: context.sp(14),
                              ),
                            ),
                          ),
                          SizedBox(width: context.w(12)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  move.crewLeadName,
                                  style: AppTextStyles.titleMedium.copyWith(
                                    fontSize: context.sp(14.5),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
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
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: context.sp(11.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.surfaceElevated,
                              padding: EdgeInsets.all(context.r(8)),
                            ),
                            icon: Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: AppColors.gold,
                              size: context.r(18),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                AnimationHelper.smoothRoute(
                                  page: const ChatScreen(chatType: ChatType.crew),
                                ),
                              );
                            },
                          ),
                          SizedBox(width: context.w(6)),
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.surfaceElevated,
                              padding: EdgeInsets.all(context.r(8)),
                            ),
                            icon: Icon(
                              Icons.phone_rounded,
                              color: AppColors.gold,
                              size: context.r(18),
                            ),
                            onPressed: () {
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
                  SizedBox(height: context.h(16)),

                  // Price Breakdown Card
                  AppFadeAnimation(
                    delay: const Duration(milliseconds: 200),
                    child: Container(
                      padding: EdgeInsets.all(context.r(18)),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(context.r(22)),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Price breakdown',
                            style: AppTextStyles.titleMedium.copyWith(
                              fontSize: context.sp(15),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: context.h(14)),
                          _buildPriceRow(
                            context: context,
                            label: 'Base relocation',
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
                              label: 'White-Glove Handling',
                              value: 'Included',
                            ),
                            _buildPriceRow(
                              context: context,
                              label: 'Standard Insurance',
                              value: 'Included',
                            ),
                          ],
                          Divider(height: context.h(20)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total',
                                style: AppTextStyles.titleLarge.copyWith(
                                  fontSize: context.sp(15.5),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '£${move.totalAmount}',
                                style: AppTextStyles.headlineSmall.copyWith(
                                  color: AppColors.gold,
                                  fontSize: context.sp(18),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: context.h(20)),

                  // Action Buttons
                  AppFadeAnimation(
                    delay: const Duration(milliseconds: 250),
                    child: Column(
                      children: [
                        CustomButton(
                          text: 'Download invoice',
                          icon: Icons.receipt_long_rounded,
                          variant: ButtonVariant.outlined,
                          height: context.h(52),
                          onPressed: () {
                            AppSnackBar.showSuccess(
                              context,
                              'Invoice for ${move.ref} downloaded successfully.',
                            );
                          },
                        ),
                        if (isCompleted) ...[
                          SizedBox(height: context.h(10)),
                          CustomButton(
                            text: 'Rate this move',
                            icon: Icons.star_rounded,
                            height: context.h(52),
                            onPressed: () {
                              RatingSheet.show(
                                context,
                                moveRef: move.ref,
                                moveTitle: move.title,
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: context.h(28)),
                ],
              ),
            ),
          ),
        ),
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
          margin: EdgeInsets.only(top: context.h(3)),
          width: context.r(10),
          height: context.r(10),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: context.w(12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.overline.copyWith(
                  fontSize: context.sp(9.5),
                  color: AppColors.textMuted,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: context.h(2)),
              Text(
                address,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: context.sp(12.5),
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
      padding: EdgeInsets.only(bottom: context.h(8)),
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
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (double y = 0; y < 20; y += 5) {
      canvas.drawCircle(Offset(0, y), 1.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

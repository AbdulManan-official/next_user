import 'package:flutter/material.dart';
import '../utils/app_theme_styles.dart';
import '../utils/responsive_helper.dart';
import '../widgets/animation_helper.dart';
import '../widgets/custom_button.dart';
import '../widgets/concierge_call_sheet.dart';
import 'chat_screen.dart';

/// Live Tracking screen with animated curved route, crew card, vehicle card, and live timeline.
class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _truckController;

  @override
  void initState() {
    super.initState();
    _truckController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _truckController.dispose();
    super.dispose();
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
              size: context.r(16),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'LIVE TRACKING',
              style: AppTextStyles.overline.copyWith(
                fontSize: context.sp(9.5),
                letterSpacing: 1.6,
              ),
            ),
            SizedBox(height: context.h(2)),
            Text(
              'In Motion',
              style: AppTextStyles.headlineSmall.copyWith(
                fontSize: context.sp(15),
                fontWeight: FontWeight.w700,
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
                context.h(32),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

              // Animated Map Card
              AppFadeAnimation(
                delay: const Duration(milliseconds: 100),
                child: Container(
                  height: 230,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        // Map grid background
                        CustomPaint(
                          size: const Size(double.infinity, 230),
                          painter: _MapGridPainter(),
                        ),

                        // Animated Truck path
                        AnimatedBuilder(
                          animation: _truckController,
                          builder: (context, child) {
                            return CustomPaint(
                              size: const Size(double.infinity, 230),
                              painter: _RoutePainter(progress: _truckController.value),
                            );
                          },
                        ),

                        // Bottom-Left Chip: In Transit · ETA 13:00
                        Positioned(
                          bottom: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.5),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'In Transit · ETA 13:00',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Crew Card
              AppFadeAnimation(
                delay: const Duration(milliseconds: 150),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.surfaceElevated,
                            child: Text(
                              'TK',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tomasz Kowalski',
                                  style: AppTextStyles.titleLarge,
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: AppColors.gold,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '4.98 · Lead Specialist',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: 'Call',
                              icon: Icons.phone_rounded,
                              height: 46,
                              onPressed: () {
                                ConciergeCallSheet.show(
                                  context,
                                  name: 'Tomasz Kowalski',
                                  role: 'Lead Specialist · On your move',
                                  avatarInitials: 'TK',
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomButton(
                              text: 'Message',
                              icon: Icons.chat_bubble_outline_rounded,
                              variant: ButtonVariant.outlined,
                              height: 46,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  AnimationHelper.smoothRoute(
                                    page: const ChatScreen(chatType: ChatType.crew),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Vehicle Card
              AppFadeAnimation(
                delay: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(
                          Icons.near_me_rounded,
                          color: AppColors.gold,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Luton 7.5t · NG21',
                              style: AppTextStyles.titleMedium,
                            ),
                            Text(
                              '4 specialists on board',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.success, width: 1.2),
                          color: AppColors.success.withValues(alpha: 0.1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.security_rounded,
                              color: AppColors.success,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Insured',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.success,
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
              const SizedBox(height: 28),

              // Progress Timeline Section
              AppFadeAnimation(
                delay: const Duration(milliseconds: 250),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          color: AppColors.gold,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text('Progress', style: AppTextStyles.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          _buildTimelineStep(
                            title: 'Crew dispatched',
                            time: '07:42',
                            isCompleted: true,
                          ),
                          _buildTimelineStep(
                            title: 'Arrived at pickup',
                            time: '08:05',
                            isCompleted: true,
                          ),
                          _buildTimelineStep(
                            title: 'Loading complete',
                            time: '10:18',
                            isCompleted: true,
                          ),
                          _buildTimelineStep(
                            title: 'In transit to destination',
                            time: '10:30',
                            isCurrent: true,
                          ),
                          _buildTimelineStep(
                            title: 'Unloading & setup',
                            time: 'Est. 11:45',
                            isDim: true,
                          ),
                          _buildTimelineStep(
                            title: 'Move complete',
                            time: 'Est. 13:00',
                            isDim: true,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }

  Widget _buildTimelineStep({
    required String title,
    required String time,
    bool isCompleted = false,
    bool isCurrent = false,
    bool isDim = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              if (isCompleted)
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: AppColors.textOnGold,
                    size: 14,
                  ),
                )
              else if (isCurrent)
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold, width: 2.5),
                    color: AppColors.gold.withValues(alpha: 0.2),
                  ),
                  child: Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 2),
                    color: Colors.transparent,
                  ),
                ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? AppColors.gold : AppColors.border,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isCurrent
                          ? AppColors.gold
                          : (isDim ? AppColors.textMuted : AppColors.textPrimary),
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  Text(
                    time,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isCurrent
                          ? AppColors.goldLight
                          : (isDim ? AppColors.textMuted : AppColors.textSecondary),
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
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
}

/// Stylized Map grid custom painter
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Stylized Route and Moving Truck Custom Painter
class _RoutePainter extends CustomPainter {
  final double progress;

  _RoutePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final start = Offset(size.width * 0.15, size.height * 0.78);
    final end = Offset(size.width * 0.85, size.height * 0.22);
    final controlPoint1 = Offset(size.width * 0.35, size.height * 0.25);
    final controlPoint2 = Offset(size.width * 0.65, size.height * 0.85);

    path.moveTo(start.dx, start.dy);
    path.cubicTo(
      controlPoint1.dx,
      controlPoint1.dy,
      controlPoint2.dx,
      controlPoint2.dy,
      end.dx,
      end.dy,
    );

    // Draw route shadow and line
    final routePaint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, routePaint);

    // Draw Start Dot (Accent Gold)
    final startPaint = Paint()..color = AppColors.gold;
    canvas.drawCircle(start, 7, startPaint);

    // Draw End Dot (Glowing Green)
    final endGlow = Paint()
      ..color = AppColors.success.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(end, 12, endGlow);
    final endPaint = Paint()..color = AppColors.success;
    canvas.drawCircle(end, 8, endPaint);

    // Calculate position of truck along cubic bezier path
    final metric = path.computeMetrics().first;
    final truckDistance = metric.length * progress;
    final tangent = metric.getTangentForOffset(truckDistance);

    if (tangent != null) {
      final truckCenter = tangent.position;

      // Glow behind truck
      final truckGlow = Paint()
        ..color = AppColors.gold.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(truckCenter, 18, truckGlow);

      // Truck circle badge
      final badgePaint = Paint()..color = AppColors.gold;
      canvas.drawCircle(truckCenter, 14, badgePaint);

      final iconPaint = Paint()..color = AppColors.textOnGold;
      canvas.drawCircle(truckCenter, 6, iconPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

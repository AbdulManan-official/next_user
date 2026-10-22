import 'package:flutter/material.dart';
import '../utils/app_theme_styles.dart';
import '../utils/responsive_helper.dart';
import '../widgets/animation_helper.dart';
import '../widgets/concierge_call_sheet.dart';
import '../widgets/glass_kit.dart';
import 'chat_screen.dart';

/// Luxury Live Tracking screen matching Next Gen gold & frosted glass design system.
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          const NxAmbientBackground(),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: r.maxContentWidth),
                child: Column(
                  children: [
                    // Frosted App Bar
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
                                  'RADAR & TELEMETRY',
                                  style: AppTextStyles.overline.copyWith(
                                    color: AppColors.gold,
                                    fontSize: context.sp(9.5),
                                    letterSpacing: 1.8,
                                  ),
                                ),
                                SizedBox(height: context.h(2)),
                                Text(
                                  'Live Transit Tracking',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: context.sp(15),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const StatusPill(
                            label: 'IN MOTION',
                            icon: Icons.navigation_rounded,
                            color: AppColors.gold,
                            fontSize: 9.5,
                          ),
                        ],
                      ),
                    ),

                    // Scrollable telemetry cards
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          r.pagePadding,
                          context.h(6),
                          r.pagePadding,
                          context.h(28),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Animated Map Radar Card
                            AppFadeAnimation(
                              delay: const Duration(milliseconds: 60),
                              child: NxGlassPanel(
                                radius: 26,
                                fillAlpha: 0.08,
                                padding: EdgeInsets.zero,
                                child: Container(
                                  height: 240,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(26),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(26),
                                    child: Stack(
                                      children: [
                                        // Map grid background
                                        CustomPaint(
                                          size: const Size(double.infinity, 240),
                                          painter: _MapGridPainter(),
                                        ),

                                        // Animated Truck path
                                        AnimatedBuilder(
                                          animation: _truckController,
                                          builder: (context, child) {
                                            return CustomPaint(
                                              size: const Size(double.infinity, 240),
                                              painter: _RoutePainter(
                                                progress: _truckController.value,
                                              ),
                                            );
                                          },
                                        ),

                                        // Top status pill
                                        Positioned(
                                          top: 14,
                                          left: 14,
                                          child: NxBadge(
                                            text: 'SATELLITE TELEMETRY · 5G',
                                            fontSize: context.sp(9),
                                            letterSpacing: 0.8,
                                          ),
                                        ),

                                        // Bottom-Left Status Pill
                                        Positioned(
                                          bottom: 14,
                                          left: 14,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 7,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceElevated
                                                  .withValues(alpha: 0.92),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: AppColors.gold
                                                    .withValues(alpha: 0.4),
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.5),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 7,
                                                  height: 7,
                                                  decoration: const BoxDecoration(
                                                    color: AppColors.success,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'On Route · ETA 13:00 (18 mins)',
                                                  style: AppTextStyles.labelSmall
                                                      .copyWith(
                                                    color: AppColors.textPrimary,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: context.sp(11),
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
                            ),
                            SizedBox(height: context.h(16)),

                            // Crew Specialist Card
                            AppFadeAnimation(
                              delay: const Duration(milliseconds: 120),
                              child: NxGlassPanel(
                                radius: 24,
                                fillAlpha: 0.08,
                                padding: EdgeInsets.all(context.r(18)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const NxSectionTitle('ASSIGNED CREW LEAD'),
                                    SizedBox(height: context.h(12)),
                                    Row(
                                      children: [
                                        NxGoldIconTile(
                                          icon: Icons.person_pin_rounded,
                                          size: context.r(46),
                                          iconSize: context.r(24),
                                          radius: 15,
                                        ),
                                        SizedBox(width: context.w(14)),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Tomasz Kowalski',
                                                style: AppTextStyles.titleMedium
                                                    .copyWith(
                                                  fontSize: context.sp(15),
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              SizedBox(height: context.h(2)),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.star_rounded,
                                                    color: AppColors.gold,
                                                    size: 15,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '4.98 · Lead Relocation Specialist',
                                                    style: AppTextStyles.bodySmall
                                                        .copyWith(
                                                      color: AppColors.textSecondary,
                                                      fontSize: context.sp(11.5),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: context.h(16)),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: GoldButton(
                                            label: 'Call Crew Lead',
                                            icon: Icons.phone_rounded,
                                            height: context.h(44),
                                            onTap: () {
                                              ConciergeCallSheet.show(
                                                context,
                                                name: 'Tomasz Kowalski',
                                                role:
                                                    'Lead Specialist · In Transit',
                                                avatarInitials: 'TK',
                                              );
                                            },
                                          ),
                                        ),
                                        SizedBox(width: context.w(10)),
                                        Expanded(
                                          child: GlassButton(
                                            label: 'Message',
                                            icon:
                                                Icons.chat_bubble_outline_rounded,
                                            height: context.h(44),
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
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: context.h(16)),

                            // Luxury Vehicle Card
                            AppFadeAnimation(
                              delay: const Duration(milliseconds: 170),
                              child: NxGlassPanel(
                                radius: 24,
                                fillAlpha: 0.08,
                                padding: EdgeInsets.all(context.r(16)),
                                child: Row(
                                  children: [
                                    NxGoldIconTile(
                                      icon: Icons.local_shipping_rounded,
                                      size: context.r(46),
                                      iconSize: context.r(22),
                                      radius: 15,
                                    ),
                                    SizedBox(width: context.w(14)),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Luton 7.5t Luxury Van · NG21',
                                            style: AppTextStyles.titleMedium
                                                .copyWith(
                                              fontSize: context.sp(14),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          SizedBox(height: context.h(2)),
                                          Text(
                                            'Air suspension · 4 specialists on board',
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                              color: AppColors.textMuted,
                                              fontSize: context.sp(11.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    NxBadge(
                                      text: 'INSURED',
                                      fontSize: context.sp(9),
                                      color: AppColors.success,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: context.h(18)),

                            // Progress Timeline Section
                            AppFadeAnimation(
                              delay: const Duration(milliseconds: 220),
                              child: NxGlassPanel(
                                radius: 24,
                                fillAlpha: 0.08,
                                padding: EdgeInsets.all(context.r(18)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const NxSectionTitle(
                                        'MISSION FLIGHT LOG & TIMELINE'),
                                    SizedBox(height: context.h(16)),
                                    _buildTimelineStep(
                                      title: 'Crew dispatched from depot',
                                      time: '07:42',
                                      isCompleted: true,
                                    ),
                                    _buildTimelineStep(
                                      title: 'Arrived at origin residence',
                                      time: '08:05',
                                      isCompleted: true,
                                    ),
                                    _buildTimelineStep(
                                      title: 'White-glove loading complete',
                                      time: '10:18',
                                      isCompleted: true,
                                    ),
                                    _buildTimelineStep(
                                      title: 'In transit to destination',
                                      time: '10:30',
                                      isCurrent: true,
                                    ),
                                    _buildTimelineStep(
                                      title: 'Unloading & fine art placement',
                                      time: 'Est. 11:45',
                                      isDim: true,
                                    ),
                                    _buildTimelineStep(
                                      title: 'Handover & move sign-off',
                                      time: 'Est. 13:00',
                                      isDim: true,
                                      isLast: true,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: context.h(24)),
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
                    size: 13,
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
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 1),
                      ),
                    ],
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
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 1.5,
                    ),
                    color: Colors.transparent,
                  ),
                ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: isCompleted
                        ? AppColors.gold
                        : Colors.white.withValues(alpha: 0.12),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isCurrent
                            ? AppColors.gold
                            : (isDim
                                ? AppColors.textMuted
                                : AppColors.textPrimary),
                        fontWeight:
                            isCurrent ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    time,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isCurrent
                          ? AppColors.goldLight
                          : (isDim
                              ? AppColors.textMuted
                              : AppColors.textSecondary),
                      fontWeight:
                          isCurrent ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 11,
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
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 28) {
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

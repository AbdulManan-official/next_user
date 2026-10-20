import 'package:flutter/material.dart';
import '../utils/app_theme_styles.dart';
import '../utils/responsive_helper.dart';

/// Ultra-smooth, high-performance Shimmer Animation Loading Widget.
/// Creates a luxury glowing skeleton loader effect matching the app theme.
class AppShimmer extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  const AppShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.baseColor ?? const Color(0xFF1E1A17);
    final highlight = widget.highlightColor ?? const Color(0xFF332921);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                base,
                highlight,
                base,
              ],
              stops: const [0.1, 0.5, 0.9],
              transform: _SlidingGradientTransform(slidePercent: _controller.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent * 2 - 1), 0, 0);
  }
}

/// Shimmer Skeleton Container Block
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 12,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1A17),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton Duty Card matching duty item layout in Clients and Surveys views
class DutyCardSkeleton extends StatelessWidget {
  final EdgeInsetsGeometry? margin;

  const DutyCardSkeleton({
    super.key,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Time Badge & Status Badge
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBox(width: 140, height: 26, borderRadius: 8),
              ShimmerBox(width: 80, height: 26, borderRadius: 8),
            ],
          ),
          const SizedBox(height: 14),

          // Client Name & Move Type
          const ShimmerBox(width: 220, height: 20, borderRadius: 6),
          const SizedBox(height: 8),

          // Lead ID
          const ShimmerBox(width: 90, height: 16, borderRadius: 6),
          const SizedBox(height: 14),

          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),

          // Route Location
          const ShimmerBox(width: double.infinity, height: 16, borderRadius: 6),
          const SizedBox(height: 16),

          // Actions: Call & Report Buttons
          const Row(
            children: [
              Expanded(child: ShimmerBox(height: 40, borderRadius: 12)),
              SizedBox(width: 10),
              Expanded(child: ShimmerBox(height: 40, borderRadius: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shimmer Skeleton Duty List (renders 3 duty card skeletons)
class DutyListSkeleton extends StatelessWidget {
  final int count;
  final EdgeInsetsGeometry? itemMargin;

  const DutyListSkeleton({
    super.key,
    this.count = 3,
    this.itemMargin,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        itemBuilder: (context, index) => DutyCardSkeleton(margin: itemMargin),
      ),
    );
  }
}

/// Shimmer Skeleton Calendar View Placeholder
class CalendarSkeleton extends StatelessWidget {
  const CalendarSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        height: 320,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        padding: const EdgeInsets.all(16),
        child: const Column(
          children: [
            // Calendar Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(width: 32, height: 32, borderRadius: 8),
                ShimmerBox(width: 150, height: 22, borderRadius: 6),
                ShimmerBox(width: 32, height: 32, borderRadius: 8),
              ],
            ),
            SizedBox(height: 20),
            // Days of week header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ShimmerBox(width: 24, height: 14, borderRadius: 4),
                ShimmerBox(width: 24, height: 14, borderRadius: 4),
                ShimmerBox(width: 24, height: 14, borderRadius: 4),
                ShimmerBox(width: 24, height: 14, borderRadius: 4),
                ShimmerBox(width: 24, height: 14, borderRadius: 4),
                ShimmerBox(width: 24, height: 14, borderRadius: 4),
                ShimmerBox(width: 24, height: 14, borderRadius: 4),
              ],
            ),
            SizedBox(height: 20),
            // Days Grid placeholder
            Expanded(
              child: ShimmerBox(width: double.infinity, height: double.infinity, borderRadius: 14),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer Skeleton for Submit Report Form
class SubmitReportSkeleton extends StatelessWidget {
  const SubmitReportSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        children: [
          const ShimmerBox(height: 100, borderRadius: 20),
          const SizedBox(height: 16),
          const ShimmerBox(height: 220, borderRadius: 20),
          const SizedBox(height: 16),
          const ShimmerBox(height: 160, borderRadius: 20),
          const SizedBox(height: 16),
          const ShimmerBox(height: 120, borderRadius: 20),
        ],
      ),
    );
  }
}

/// 100% Pixel-Perfect WhatsApp-Style Chat Row Skeleton Item matching the screenshot
class ContactStaffSkeleton extends StatelessWidget {
  final double nameWidth;
  final double messageWidth;
  final bool showShimmer;

  const ContactStaffSkeleton({
    super.key,
    this.nameWidth = 140,
    this.messageWidth = 200,
    this.showShimmer = false,
  });

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Circular Avatar (50x50 with border)
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1E1A17),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.25), width: 1),
            ),
          ),
          const SizedBox(width: 14),

          // 2. Title, Timestamp & Subtitle Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top Line: Contact Name & Date / Timestamp
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ShimmerBox(width: nameWidth, height: 15, borderRadius: 4),
                    const ShimmerBox(width: 58, height: 11, borderRadius: 3),
                  ],
                ),
                const SizedBox(height: 6),

                // Bottom Line: Double checkmark tick + Last Message preview
                Row(
                  children: [
                    const Icon(
                      Icons.done_all_rounded,
                      size: 13,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: ShimmerBox(width: messageWidth, height: 12, borderRadius: 3),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (showShimmer) {
      return AppShimmer(child: row);
    }
    return row;
  }
}

/// Shimmer Skeleton Contact Staff & Chats List (100% matches WhatsApp Chats screen UI in screenshot)
class ContactStaffListSkeleton extends StatelessWidget {
  final int count;

  const ContactStaffListSkeleton({
    super.key,
    this.count = 14,
  });

  @override
  Widget build(BuildContext context) {
    // Varied name and message widths for ultra-realistic shimmer effect
    final variations = [
      (nameWidth: 150.0, messageWidth: 220.0),
      (nameWidth: 110.0, messageWidth: 250.0),
      (nameWidth: 80.0, messageWidth: 230.0),
      (nameWidth: 90.0, messageWidth: 180.0),
      (nameWidth: 130.0, messageWidth: 190.0),
      (nameWidth: 100.0, messageWidth: 170.0),
      (nameWidth: 120.0, messageWidth: 200.0),
      (nameWidth: 70.0, messageWidth: 180.0),
    ];

    return AppShimmer(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 0.6,
          indent: 76,
          endIndent: 0,
          color: AppColors.border.withValues(alpha: 0.6),
        ),
        itemBuilder: (context, index) {
          final variation = variations[index % variations.length];
          return ContactStaffSkeleton(
            nameWidth: variation.nameWidth,
            messageWidth: variation.messageWidth,
            showShimmer: false,
          );
        },
      ),
    );
  }
}

/// Shimmer Skeleton for Home Grid Tiles
class HomeGridSkeleton extends StatelessWidget {
  final int? crossAxisCount;
  final double? childAspectRatio;
  final double? crossAxisSpacing;
  final double? mainAxisSpacing;
  final int itemCount;

  const HomeGridSkeleton({
    super.key,
    this.crossAxisCount,
    this.childAspectRatio,
    this.crossAxisSpacing,
    this.mainAxisSpacing,
    this.itemCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: crossAxisCount ?? 2,
        crossAxisSpacing: crossAxisSpacing ?? 14,
        mainAxisSpacing: mainAxisSpacing ?? 14,
        childAspectRatio: childAspectRatio ?? 1.05,
        children: List.generate(
          itemCount,
          (index) => Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            padding: const EdgeInsets.all(16),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(width: 44, height: 44, borderRadius: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 100, height: 16, borderRadius: 4),
                    SizedBox(height: 6),
                    ShimmerBox(width: 70, height: 12, borderRadius: 4),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton Client Card matching item layout in SurveyorClientsView
class ClientCardSkeleton extends StatelessWidget {
  final EdgeInsetsGeometry? margin;

  const ClientCardSkeleton({
    super.key,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Avatar & Name/ID Column & Status Chip
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const ShimmerBox(width: 44, height: 44, borderRadius: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const ShimmerBox(width: 120, height: 18, borderRadius: 4),
                        const ShimmerBox(width: 60, height: 20, borderRadius: 8),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const ShimmerBox(width: 150, height: 14, borderRadius: 4),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppColors.gold, size: 28),
            ],
          ),
          const Divider(height: 20, color: AppColors.border),

          // Route row placeholder
          Row(
            children: [
              const ShimmerBox(width: 16, height: 16, borderRadius: 4),
              const SizedBox(width: 8),
              Expanded(child: const ShimmerBox(height: 14, borderRadius: 4)),
            ],
          ),
          const SizedBox(height: 8),

          // Survey Date & Time row placeholder
          Row(
            children: [
              const ShimmerBox(width: 16, height: 16, borderRadius: 4),
              const SizedBox(width: 8),
              const ShimmerBox(width: 180, height: 14, borderRadius: 4),
            ],
          ),
          const SizedBox(height: 14),

          // Full-Width Call Client Action Button
          const ShimmerBox(width: double.infinity, height: 40, borderRadius: 12),
        ],
      ),
    );
  }
}

/// Shimmer Skeleton Client List (wrapped in a single AppShimmer for better performance)
class ClientListSkeleton extends StatelessWidget {
  final int count;
  final EdgeInsetsGeometry? itemMargin;

  const ClientListSkeleton({
    super.key,
    this.count = 3,
    this.itemMargin,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        itemBuilder: (context, index) => ClientCardSkeleton(margin: itemMargin),
      ),
    );
  }
}

/// Luxury Chat Messages Skeleton Loader for Support/Staff Chat.
/// Pixel-perfect mirror of the active chat UI with sender names, avatars, message bubbles,
/// media attachments, timestamps, and gold theme accents.
class ChatMessagesSkeleton extends StatelessWidget {
  final int count;
  final EdgeInsetsGeometry? padding;

  const ChatMessagesSkeleton({
    super.key,
    this.count = 6,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // 1. Center Date Separator Pill ('Today')
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 4, bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.5), width: 1),
              ),
              child: const ShimmerBox(width: 48, height: 11, borderRadius: 4),
            ),
          ),

          // 2. Incoming Support/Staff Message (Left with Avatar & Name)
          _buildMessageItem(
            isMe: false,
            senderNameWidth: 85,
            bubbleWidth: 240,
            content: [
              const ShimmerBox(width: 210, height: 13, borderRadius: 4),
              const SizedBox(height: 6),
              const ShimmerBox(width: 150, height: 13, borderRadius: 4),
            ],
          ),
          const SizedBox(height: 10),

          // 3. Outgoing User Message (Right with Gold Accent)
          _buildMessageItem(
            isMe: true,
            senderNameWidth: 60,
            bubbleWidth: 200,
            content: [
              const ShimmerBox(width: 170, height: 13, borderRadius: 4),
            ],
          ),
          const SizedBox(height: 10),

          // 4. Outgoing Photo Proof / Media Attachment (Right)
          _buildMediaMessageItem(
            isMe: true,
            senderNameWidth: 60,
            bubbleWidth: 215,
          ),
          const SizedBox(height: 10),

          // 5. Incoming Support Detailed Guidance (Left)
          _buildMessageItem(
            isMe: false,
            senderNameWidth: 95,
            bubbleWidth: 265,
            content: [
              const ShimmerBox(width: 235, height: 13, borderRadius: 4),
              const SizedBox(height: 6),
              const ShimmerBox(width: 195, height: 13, borderRadius: 4),
              const SizedBox(height: 6),
              const ShimmerBox(width: 130, height: 13, borderRadius: 4),
            ],
          ),
          const SizedBox(height: 10),

          // 6. Outgoing Acknowledgment (Right)
          _buildMessageItem(
            isMe: true,
            senderNameWidth: 60,
            bubbleWidth: 160,
            content: [
              const ShimmerBox(width: 130, height: 13, borderRadius: 4),
            ],
          ),
          const SizedBox(height: 10),

          // 7. Incoming Support Final Confirmation (Left)
          _buildMessageItem(
            isMe: false,
            senderNameWidth: 80,
            bubbleWidth: 200,
            content: [
              const ShimmerBox(width: 170, height: 13, borderRadius: 4),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem({
    required bool isMe,
    required double senderNameWidth,
    required double bubbleWidth,
    required List<Widget> content,
  }) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            const ShimmerBox(width: 28, height: 28, borderRadius: 14),
            const SizedBox(width: 8),
          ],
          Container(
            constraints: BoxConstraints(maxWidth: bubbleWidth),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? AppColors.gold.withValues(alpha: 0.18) : AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
              border: Border.all(
                color: isMe ? AppColors.gold.withValues(alpha: 0.45) : AppColors.border,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sender name tag (gold on incoming)
                ShimmerBox(
                  width: senderNameWidth,
                  height: 10,
                  borderRadius: 3,
                ),
                const SizedBox(height: 6),

                // Message text lines
                ...content,
                const SizedBox(height: 6),

                // Timestamp & read ticks row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ShimmerBox(width: 32, height: 8.5, borderRadius: 2),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.done_all_rounded, size: 13, color: AppColors.gold),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaMessageItem({
    required bool isMe,
    required double senderNameWidth,
    required double bubbleWidth,
  }) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            const ShimmerBox(width: 28, height: 28, borderRadius: 14),
            const SizedBox(width: 8),
          ],
          Container(
            width: bubbleWidth,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isMe ? AppColors.gold.withValues(alpha: 0.18) : AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
              border: Border.all(
                color: isMe ? AppColors.gold.withValues(alpha: 0.45) : AppColors.border,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: ShimmerBox(
                    width: senderNameWidth,
                    height: 10,
                    borderRadius: 3,
                  ),
                ),
                const SizedBox(height: 4),

                // Photo/Video rectangular placeholder (matches 150px media preview in chat)
                const ShimmerBox(
                  width: double.infinity,
                  height: 130,
                  borderRadius: 10,
                ),
                const SizedBox(height: 6),

                // Timestamp & read ticks
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const ShimmerBox(width: 32, height: 8.5, borderRadius: 2),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.done_all_rounded, size: 13, color: AppColors.gold),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Luxury Glass Home Screen Shimmer Skeleton
/// Single shared source of truth used across both Surveyor and Driver home screens.
class HomeShimmerSkeleton extends StatelessWidget {
  final ResponsiveHelper? responsive;
  const HomeShimmerSkeleton({super.key, this.responsive});

  BoxDecoration _glassSkeleton(double radius) => BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 1,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final r = responsive ?? context.responsive;

    return AppShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview card skeleton
          Container(
            padding: EdgeInsets.all(r.r(22)),
            decoration: _glassSkeleton(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    ShimmerBox(width: 150, height: 20, borderRadius: 6),
                    Spacer(),
                    ShimmerBox(width: 90, height: 28, borderRadius: 14),
                  ],
                ),
                SizedBox(height: r.r(22)),
                Row(
                  children: [
                    ShimmerBox(
                      width: r.r(128),
                      height: r.r(128),
                      borderRadius: r.r(64),
                    ),
                    SizedBox(width: r.r(22)),
                    Expanded(
                      child: SizedBox(
                        height: r.r(128),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _legendSkeleton(),
                            _legendSkeleton(),
                            _legendSkeleton(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: r.r(28)),

          // Section header skeleton
          const ShimmerBox(width: 200, height: 20, borderRadius: 6),
          SizedBox(height: r.r(16)),

          // Service grid skeleton (2x2)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:
                  r.gridColumns(mobile: 2, tablet: 3, desktop: 4),
              crossAxisSpacing: r.r(14),
              mainAxisSpacing: r.r(14),
              childAspectRatio:
                  r.value(mobile: 1.0, tablet: 1.2, desktop: 1.35),
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              return Container(
                decoration: _glassSkeleton(28),
                padding: EdgeInsets.all(r.r(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBox(
                      width: r.r(46),
                      height: r.r(46),
                      borderRadius: 15,
                    ),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 90, height: 14, borderRadius: 5),
                        SizedBox(height: 6),
                        ShimmerBox(width: 110, height: 11, borderRadius: 4),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _legendSkeleton() {
    return const Row(
      children: [
        ShimmerBox(width: 9, height: 9, borderRadius: 5),
        SizedBox(width: 10),
        Expanded(child: ShimmerBox(height: 13, borderRadius: 4)),
        SizedBox(width: 10),
        ShimmerBox(width: 22, height: 16, borderRadius: 4),
      ],
    );
  }
}


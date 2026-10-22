import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme_styles.dart';
import '../utils/responsive_helper.dart';
import 'glass_kit.dart';

/// Full-fidelity luxury in-call screen matching Next Gen native gold & frosted glass UI.
class ConciergeCallSheet extends StatefulWidget {
  const ConciergeCallSheet({
    super.key,
    required this.name,
    required this.role,
    this.avatarInitials = 'NC',
  });

  final String name;
  final String role;
  final String avatarInitials;

  static void show(
    BuildContext context, {
    required String name,
    required String role,
    String avatarInitials = 'NC',
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) => ConciergeCallSheet(
        name: name,
        role: role,
        avatarInitials: avatarInitials,
      ),
    );
  }

  @override
  State<ConciergeCallSheet> createState() => _ConciergeCallSheetState();
}

class _ConciergeCallSheetState extends State<ConciergeCallSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  Timer? _callTimer;
  int _secondsElapsed = 24;

  bool _isMuted = false;
  bool _isSpeaker = true;
  bool _isVideo = false;
  bool _isBluetooth = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _secondsElapsed++);
      }
    });
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String get _formattedDuration {
    final minutes = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsElapsed % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _onEndCall() {
    HapticFeedback.heavyImpact();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const NxAmbientBackground(),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 20),
                child: Column(
                  children: [
                    // Top drag pill
                    Center(
                      child: Container(
                        width: 42,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                    SizedBox(height: context.h(14)),

                    // Top navigation bar & encryption badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GlassCircleButton(
                          icon: Icons.keyboard_arrow_down_rounded,
                          iconColor: AppColors.gold,
                          iconSize: context.r(24),
                          size: context.r(40),
                          semanticLabel: 'Minimize Call',
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        NxBadge(
                          text: 'END-TO-END ENCRYPTED · HD VOICE',
                          fontSize: context.sp(9),
                          letterSpacing: 0.8,
                        ),
                        SizedBox(width: context.r(40)), // balance spacer
                      ],
                    ),

                    const Spacer(flex: 1),

                    // Animated Concentric Radar Rings around Avatar
                    Center(
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final v = _pulseController.value;
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer ripple ring
                              Container(
                                width: 180 + (v * 45),
                                height: 180 + (v * 45),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.gold
                                        .withValues(alpha: (1.0 - v) * 0.22),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              // Inner ripple ring
                              Container(
                                width: 140 + (v * 30),
                                height: 140 + (v * 30),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.gold
                                        .withValues(alpha: (1.0 - v) * 0.35),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              // Center Avatar with Luxury Gold Aura
                              Container(
                                width: 106,
                                height: 106,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: AppColors.goldGradient,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    width: 2.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          AppColors.gold.withValues(alpha: 0.45),
                                      blurRadius: 30,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    widget.avatarInitials,
                                    style: AppTextStyles.headlineLarge.copyWith(
                                      color: AppColors.textOnGold,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    SizedBox(height: context.h(24)),

                    // Caller Details
                    Text(
                      widget.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: context.sp(22),
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: context.h(4)),
                    Text(
                      widget.role,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.gold,
                        fontSize: context.sp(13),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: context.h(10)),

                    // Active Connection & Elapsed Timer Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.3),
                        ),
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
                            'Connected · $_formattedDuration',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: context.sp(11.5),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 2),

                    // Native Luxury Glass Call Controls
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: r.maxContentWidth),
                      child: Column(
                        children: [
                          // Row 1: Mute, Keypad, Speaker
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildControlItem(
                                icon: _isMuted
                                    ? Icons.mic_off_rounded
                                    : Icons.mic_rounded,
                                label: _isMuted ? 'Muted' : 'Mute',
                                isActive: _isMuted,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setState(() => _isMuted = !_isMuted);
                                },
                              ),
                              _buildControlItem(
                                icon: Icons.dialpad_rounded,
                                label: 'Keypad',
                                isActive: false,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                },
                              ),
                              _buildControlItem(
                                icon: _isSpeaker
                                    ? Icons.volume_up_rounded
                                    : Icons.volume_down_rounded,
                                label: 'Speaker',
                                isActive: _isSpeaker,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setState(() => _isSpeaker = !_isSpeaker);
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: context.h(20)),

                          // Row 2: Video, Bluetooth, Chat
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildControlItem(
                                icon: _isVideo
                                    ? Icons.videocam_rounded
                                    : Icons.videocam_off_rounded,
                                label: 'Camera',
                                isActive: _isVideo,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setState(() => _isVideo = !_isVideo);
                                },
                              ),
                              _buildControlItem(
                                icon: Icons.bluetooth_audio_rounded,
                                label: 'Bluetooth',
                                isActive: _isBluetooth,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setState(() => _isBluetooth = !_isBluetooth);
                                },
                              ),
                              _buildControlItem(
                                icon: Icons.chat_bubble_outline_rounded,
                                label: 'Message',
                                isActive: false,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: context.h(30)),

                          // Large Circular End Call Button
                          NxPressable(
                            scale: 0.92,
                            onTap: _onEndCall,
                            child: Container(
                              width: context.r(68),
                              height: context.r(68),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFEF4444),
                                    Color(0xFFDC2626),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFEF4444)
                                        .withValues(alpha: 0.45),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.call_end_rounded,
                                  color: Colors.white,
                                  size: context.r(32),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: context.h(12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NxPressable(
          scale: 0.92,
          onTap: onTap,
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? AppColors.gold
                  : Colors.white.withValues(alpha: 0.08),
              border: Border.all(
                color: isActive
                    ? AppColors.gold
                    : Colors.white.withValues(alpha: 0.18),
                width: 1.2,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: isActive ? AppColors.textOnGold : Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isActive ? AppColors.gold : AppColors.textMuted,
            fontSize: 11.5,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../utils/app_theme_styles.dart';
import 'app_snack_bar.dart';

/// Interactive Notification Preferences Modal.
class NotificationSheet extends StatefulWidget {
  const NotificationSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const NotificationSheet(),
    );
  }

  @override
  State<NotificationSheet> createState() => _NotificationSheetState();
}

class _NotificationSheetState extends State<NotificationSheet> {
  bool _liveTrackingUpdates = true;
  bool _crewMessages = true;
  bool _quoteAlerts = true;
  bool _promotions = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1.2),
          left: BorderSide(color: AppColors.border, width: 1.2),
          right: BorderSide(color: AppColors.border, width: 1.2),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'NOTIFICATIONS',
            style: AppTextStyles.overline,
          ),
          const SizedBox(height: 4),
          Text('Preferences', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 20),

          _buildToggle(
            title: 'Live Tracking Updates',
            subtitle: 'Real-time GPS vehicle location & ETA milestones',
            value: _liveTrackingUpdates,
            onChanged: (val) => setState(() => _liveTrackingUpdates = val),
          ),
          const Divider(height: 24),
          _buildToggle(
            title: 'Crew Messages',
            subtitle: 'Direct dispatch messages from lead specialist',
            value: _crewMessages,
            onChanged: (val) => setState(() => _crewMessages = val),
          ),
          const Divider(height: 24),
          _buildToggle(
            title: 'Quote & Booking Alerts',
            subtitle: 'Confirmations, invoices, and scheduling updates',
            value: _quoteAlerts,
            onChanged: (val) => setState(() => _quoteAlerts = val),
          ),
          const Divider(height: 24),
          _buildToggle(
            title: 'Platinum Perks & Rewards',
            subtitle: 'Exclusive member discounts and referral rewards',
            value: _promotions,
            onChanged: (val) => setState(() => _promotions = val),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: AppColors.gold,
          activeTrackColor: AppColors.gold.withValues(alpha: 0.3),
          inactiveThumbColor: AppColors.textMuted,
          inactiveTrackColor: AppColors.surfaceElevated,
          onChanged: (val) {
            onChanged(val);
            AppSnackBar.showInfo(context, 'Notification settings updated.');
          },
        ),
      ],
    );
  }
}

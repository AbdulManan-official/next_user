import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme_styles.dart';
import '../utils/responsive_helper.dart';
import '../widgets/animation_helper.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../models/move_model.dart';
import '../controllers/move_store.dart';
import 'move_detail_screen.dart';

/// Ultra-Luxury 4-Step Concierge Booking Flow & Instant Quote Experience.
class BookingFlowScreen extends StatefulWidget {
  const BookingFlowScreen({super.key, this.onBackToHome});

  final VoidCallback? onBackToHome;

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  final MoveStore _store = MoveStore.instance;
  int _currentStep = 0; // 0: Property, 1: Route, 2: Services, 3: Quote, 4: Success

  static const _stepTitles = [
    'Select Residence',
    'Route & Schedule',
    'Bespoke Services',
    'Review & Confirm',
  ];

  late TextEditingController _fromController;
  late TextEditingController _toController;
  late TextEditingController _dateController;
  late TextEditingController _notesController;
  late String _selectedTimeSlot;

  @override
  void initState() {
    super.initState();
    _fromController = TextEditingController(text: _store.fromAddress);
    _toController = TextEditingController(text: _store.toAddress);
    _dateController = TextEditingController(
      text: _store.preferredDate.isEmpty ? '24 Oct 2026' : _store.preferredDate,
    );
    _notesController = TextEditingController(text: _store.notes);
    _selectedTimeSlot = _store.selectedTimeSlot.isEmpty
        ? 'Morning (08:00 – 12:00)'
        : _store.selectedTimeSlot;
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showExitSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(24),
          vertical: context.h(24),
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(context.r(28)),
          ),
          border: Border.all(color: AppColors.border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: context.w(40),
              height: context.h(4),
              decoration: BoxDecoration(
                color: AppColors.border.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(context.r(2)),
              ),
            ),
            SizedBox(height: context.h(18)),
            Text(
              'Save your booking draft?',
              style: AppTextStyles.headlineSmall.copyWith(
                fontSize: context.sp(18),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: context.h(6)),
            Text(
              'Your selections will be kept safely so you can resume your luxury move anytime.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontSize: context.sp(12.5),
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.h(22)),
            CustomButton(
              text: 'Save draft & exit',
              icon: Icons.bookmark_added_rounded,
              height: context.h(50),
              onPressed: () {
                Navigator.pop(ctx);
                if (widget.onBackToHome != null) {
                  widget.onBackToHome!();
                } else if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                AppSnackBar.showSuccess(context, 'Booking draft saved.');
              },
            ),
            SizedBox(height: context.h(10)),
            CustomButton(
              text: 'Discard booking',
              icon: Icons.delete_outline_rounded,
              variant: ButtonVariant.danger,
              height: context.h(50),
              onPressed: () {
                Navigator.pop(ctx);
                if (widget.onBackToHome != null) {
                  widget.onBackToHome!();
                } else if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
            SizedBox(height: context.h(6)),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Keep editing',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.gold,
                  fontSize: context.sp(13.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _nextStep() {
    HapticFeedback.selectionClick();
    FocusManager.instance.primaryFocus?.unfocus();

    if (_currentStep == 1) {
      if (_fromController.text.trim().isEmpty ||
          _toController.text.trim().isEmpty ||
          _dateController.text.trim().isEmpty) {
        AppSnackBar.showWarning(
          context,
          'Please complete pickup address, destination, and move date.',
        );
        return;
      }
      _store.setRoute(
        from: _fromController.text.trim(),
        to: _toController.text.trim(),
        date: _dateController.text.trim(),
        timeSlot: _selectedTimeSlot,
        additionalNotes: _notesController.text.trim(),
      );
    }
    setState(() => _currentStep++);
  }

  void _prevStep() {
    HapticFeedback.selectionClick();
    FocusManager.instance.primaryFocus?.unfocus();
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _confirmBooking() {
    HapticFeedback.heavyImpact();
    _store.confirmNewBooking();
    setState(() => _currentStep = 4);
  }

  IconData _iconForService(String serviceId) {
    switch (serviceId) {
      case 'pack':
        return Icons.inventory_2_rounded;
      case 'store':
        return Icons.warehouse_rounded;
      case 'dismantle':
        return Icons.handyman_rounded;
      case 'ins':
        return Icons.verified_user_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStep == 4) {
      return _buildSuccessScreen();
    }

    final r = context.responsive;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: r.maxContentWidth),
        child: Column(
          children: [
            // ── Custom Header (replaces AppBar — avoids double-Scaffold) ──
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(8),
                vertical: context.h(6),
              ),
              child: Row(
                children: [
                  // Back / Close button
                  IconButton(
                    icon: Container(
                      padding: EdgeInsets.all(context.r(6)),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Icon(
                        _currentStep > 0
                            ? Icons.arrow_back_ios_new_rounded
                            : Icons.close_rounded,
                        color: AppColors.gold,
                        size: context.r(16),
                      ),
                    ),
                    onPressed: _currentStep > 0 ? _prevStep : _showExitSheet,
                  ),
                  // Centered title
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'CONCIERGE BOOKING',
                          style: AppTextStyles.overline.copyWith(
                            fontSize: context.sp(9.5),
                            letterSpacing: 1.8,
                          ),
                        ),
                        SizedBox(height: context.h(2)),
                        Text(
                          'Step ${_currentStep + 1} of 4 • ${_stepTitles[_currentStep]}',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: context.sp(14.5),
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  // Spacer to balance the left icon button width
                  SizedBox(width: context.w(48)),
                ],
              ),
            ),

            // 4-Step Animated Progress Indicator
            _buildProgressBar(),

            // Step Body with smooth fade transition
            Expanded(
              child: ClipRect(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.topCenter,
                    fit: StackFit.expand,
                    children: [...previous, ?current],
                  ),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                  child: _buildCurrentStepView(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final steps = ['Residence', 'Route', 'Services', 'Invoice'];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.w(18),
        context.h(6),
        context.w(18),
        context.h(10),
      ),
      child: Row(
        children: List.generate(4, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.w(3)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    height: context.h(4.5),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.gold
                          : (isCurrent
                              ? AppColors.gold.withValues(alpha: 0.75)
                              : AppColors.surfaceElevated),
                      borderRadius: BorderRadius.circular(context.r(4)),
                      border: isCurrent
                          ? Border.all(color: AppColors.gold, width: 1.0)
                          : null,
                      boxShadow: isCompleted || isCurrent
                          ? [
                              BoxShadow(
                                color: AppColors.gold.withValues(
                                  alpha: isCompleted ? 0.35 : 0.22,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                  ),
                  SizedBox(height: context.h(5)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isCompleted) ...[
                        Icon(
                          Icons.check_circle_rounded,
                          size: context.r(11),
                          color: AppColors.gold,
                        ),
                        SizedBox(width: context.w(2.5)),
                      ],
                      Flexible(
                        child: Text(
                          steps[index],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelSmall.copyWith(
                            fontSize: context.sp(10),
                            color: isCompleted
                                ? AppColors.goldLight
                                : (isCurrent
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted),
                            fontWeight: isCompleted || isCurrent
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Property();
      case 1:
        return _buildStep2Route();
      case 2:
        return _buildStep3Services();
      case 3:
        return _buildStep4Quote();
      default:
        return _buildStep1Property();
    }
  }

  // ===========================================================================
  // STEP 1: RESIDENCE / PROPERTY SELECTION
  // ===========================================================================
  Widget _buildStep1Property() {
    final properties = PropertyType.values;
    final r = context.responsive;

    return SingleChildScrollView(
      key: const ValueKey('step1'),
      padding: EdgeInsets.symmetric(
        horizontal: r.pagePadding,
        vertical: context.h(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Residence',
                      style: AppTextStyles.headlineSmall.copyWith(
                        fontSize: context.sp(18),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: context.h(2)),
                    Text(
                      'Choose footprint for tailored equipment & crew size',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: context.sp(12),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.w(10)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(9),
                  vertical: context.h(4),
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(context.r(12)),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  'White Glove',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.gold,
                    fontSize: context.sp(10),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(16)),

          // 2-Column Responsive Luxury Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: properties.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: r.gridColumns(mobile: 2, tablet: 3, desktop: 4),
              crossAxisSpacing: context.w(12),
              mainAxisSpacing: context.h(12),
              childAspectRatio: 1.18,
            ),
            itemBuilder: (context, index) {
              final prop = properties[index];
              final isSelected = _store.selectedProperty == prop;

              return InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _store.setProperty(prop));
                },
                borderRadius: BorderRadius.circular(context.r(22)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(context.r(14)),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.gold.withValues(alpha: 0.16)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(context.r(22)),
                    border: Border.all(
                      color: isSelected ? AppColors.gold : AppColors.border,
                      width: isSelected ? 1.6 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.gold.withValues(alpha: 0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Stack(
                    children: [
                      if (isSelected)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.gold,
                            size: context.r(18),
                          ),
                        ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(context.r(8)),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF352618)
                                  : const Color(0xFF241A12),
                              borderRadius:
                                  BorderRadius.circular(context.r(12)),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.gold.withValues(alpha: 0.65)
                                    : AppColors.gold.withValues(alpha: 0.22),
                                width: isSelected ? 1.2 : 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? AppColors.gold.withValues(alpha: 0.35)
                                      : AppColors.gold.withValues(alpha: 0.12),
                                  blurRadius: isSelected ? 12 : 8,
                                  spreadRadius: isSelected ? 1 : 0,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              prop.icon,
                              color: isSelected
                                  ? AppColors.goldLight
                                  : AppColors.gold.withValues(alpha: 0.85),
                              size: context.r(20),
                            ),
                          ),
                          SizedBox(height: context.h(8)),
                          Text(
                            prop.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: isSelected
                                  ? AppColors.goldLight
                                  : AppColors.textPrimary,
                              fontSize: context.sp(13),
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: context.h(2)),
                          Text(
                            'From £${prop.basePrice}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isSelected
                                  ? AppColors.gold
                                  : AppColors.textMuted,
                              fontSize: context.sp(11),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          SizedBox(height: context.h(24)),

          CustomButton(
            text: 'Continue to Route Details',
            icon: Icons.arrow_forward_rounded,
            height: context.h(50),
            onPressed: _nextStep,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ===========================================================================
  // STEP 2: ROUTE & SCHEDULE
  // ===========================================================================
  Widget _buildStep2Route() {
    final r = context.responsive;
    final timeSlots = [
      {
        'id': 'Morning (08:00 – 12:00)',
        'title': 'Morning',
        'hours': '08:00 – 12:00',
        'icon': Icons.wb_twilight_rounded,
      },
      {
        'id': 'Afternoon (12:00 – 16:00)',
        'title': 'Afternoon',
        'hours': '12:00 – 16:00',
        'icon': Icons.wb_sunny_rounded,
      },
      {
        'id': 'Evening (16:00 – 20:00)',
        'title': 'Evening',
        'hours': '16:00 – 20:00',
        'icon': Icons.nightlight_round_rounded,
      },
    ];

    return SingleChildScrollView(
      key: const ValueKey('step2'),
      padding: EdgeInsets.symmetric(
        horizontal: r.pagePadding,
        vertical: context.h(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Route & Schedule',
            style: AppTextStyles.headlineSmall.copyWith(
              fontSize: context.sp(18),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: context.h(2)),
          Text(
            'Configure starting point, destination & preferred moving window.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: context.sp(12),
            ),
          ),
          SizedBox(height: context.h(18)),

          // Visual Connected Route Panel
          Container(
            padding: EdgeInsets.all(context.r(16)),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(context.r(22)),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                CustomTextField(
                  label: 'PICKUP ADDRESS (ORIGIN)',
                  hintText: 'e.g. 12 Kingsway, Slough SL1 1XN',
                  controller: _fromController,
                  prefixIcon: Icons.radio_button_checked_rounded,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: context.h(8)),
                  child: Row(
                    children: [
                      SizedBox(width: context.w(16)),
                      Container(
                        width: 1.5,
                        height: context.h(16),
                        color: AppColors.gold.withValues(alpha: 0.6),
                      ),
                      SizedBox(width: context.w(12)),
                      Text(
                        'Direct white-glove transport',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textMuted,
                          fontSize: context.sp(10.5),
                        ),
                      ),
                    ],
                  ),
                ),
                CustomTextField(
                  label: 'DESTINATION ADDRESS',
                  hintText: 'e.g. Rosewood Manor, Windsor SL4 2HJ',
                  controller: _toController,
                  prefixIcon: Icons.location_on_rounded,
                ),
              ],
            ),
          ),
          SizedBox(height: context.h(16)),

          // Date Picker Card
          CustomTextField(
            label: 'RELOCATION DATE',
            hintText: 'Select preferred moving date',
            controller: _dateController,
            readOnly: true,
            canRequestFocus: false,
            prefixIcon: Icons.calendar_today_rounded,
            suffixIcon: Icons.event_available_rounded,
            onTap: () async {
              HapticFeedback.lightImpact();
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: now.add(const Duration(days: 7)),
                firstDate: now,
                lastDate: now.add(const Duration(days: 365)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppColors.gold,
                        onPrimary: AppColors.textOnGold,
                        surface: AppColors.surfaceElevated,
                        onSurface: AppColors.textPrimary,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                final months = [
                  'Jan',
                  'Feb',
                  'Mar',
                  'Apr',
                  'May',
                  'Jun',
                  'Jul',
                  'Aug',
                  'Sep',
                  'Oct',
                  'Nov',
                  'Dec'
                ];
                setState(() {
                  _dateController.text =
                      '${picked.day} ${months[picked.month - 1]} ${picked.year}';
                });
              }
            },
          ),
          SizedBox(height: context.h(18)),

          Text(
            'PREFERRED ARRIVAL WINDOW',
            style: AppTextStyles.overline.copyWith(
              fontSize: context.sp(10),
              letterSpacing: 1.5,
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: context.h(10)),

          // 3-Card Time Slots Selector
          Row(
            children: timeSlots.map((slot) {
              final isSelected = _selectedTimeSlot == slot['id'] ||
                  _selectedTimeSlot.startsWith(slot['title'] as String);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.w(3.5)),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(
                        () => _selectedTimeSlot = slot['id'] as String,
                      );
                    },
                    borderRadius: BorderRadius.circular(context.r(18)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        vertical: context.h(12),
                        horizontal: context.w(8),
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.gold.withValues(alpha: 0.16)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(context.r(18)),
                        border: Border.all(
                          color: isSelected ? AppColors.gold : AppColors.border,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(context.r(7)),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF352618)
                                  : const Color(0xFF241A12),
                              borderRadius:
                                  BorderRadius.circular(context.r(10)),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.gold.withValues(alpha: 0.55)
                                    : AppColors.gold.withValues(alpha: 0.18),
                                width: 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? AppColors.gold.withValues(alpha: 0.28)
                                      : AppColors.gold.withValues(alpha: 0.10),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              slot['icon'] as IconData,
                              color: isSelected
                                  ? AppColors.goldLight
                                  : AppColors.gold.withValues(alpha: 0.75),
                              size: context.r(18),
                            ),
                          ),
                          SizedBox(height: context.h(6)),
                          Text(
                            slot['title'] as String,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: isSelected
                                  ? AppColors.goldLight
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: context.sp(11.5),
                            ),
                          ),
                          SizedBox(height: context.h(2)),
                          Text(
                            slot['hours'] as String,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isSelected
                                  ? AppColors.gold
                                  : AppColors.textMuted,
                              fontSize: context.sp(9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: context.h(16)),

          CustomTextField(
            label: 'SPECIAL INSTRUCTIONS (OPTIONAL)',
            hintText: 'e.g. Antique grandfather clock, narrow stairs, access code',
            controller: _notesController,
            prefixIcon: Icons.notes_rounded,
          ),
          SizedBox(height: context.h(24)),

          Row(
            children: [
              Expanded(
                flex: 1,
                child: CustomButton(
                  text: 'Back',
                  variant: ButtonVariant.outlined,
                  height: context.h(50),
                  onPressed: _prevStep,
                ),
              ),
              SizedBox(width: context.w(12)),
              Expanded(
                flex: 2,
                child: CustomButton(
                  text: 'Continue to Services',
                  icon: Icons.arrow_forward_rounded,
                  height: context.h(50),
                  onPressed: _nextStep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ===========================================================================
  // STEP 3: ENHANCE SERVICES (ADD-ONS)
  // ===========================================================================
  Widget _buildStep3Services() {
    final r = context.responsive;
    final totalServicesPrice = _store.quoteServicesTotal;

    return SingleChildScrollView(
      key: const ValueKey('step3'),
      padding: EdgeInsets.symmetric(
        horizontal: r.pagePadding,
        vertical: context.h(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bespoke Services',
                      style: AppTextStyles.headlineSmall.copyWith(
                        fontSize: context.sp(18),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: context.h(2)),
                    Text(
                      'Elevate your moving experience with white-glove add-ons',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: context.sp(12),
                      ),
                    ),
                  ],
                ),
              ),
              if (totalServicesPrice > 0) ...[
                SizedBox(width: context.w(10)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(10),
                    vertical: context.h(4),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(context.r(14)),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    '+£$totalServicesPrice',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.gold,
                      fontSize: context.sp(11),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: context.h(16)),

          ..._store.availableServices.map((service) {
            final isSelected = service.isSelected;
            return Container(
              margin: EdgeInsets.only(bottom: context.h(12)),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.gold.withValues(alpha: 0.14)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(context.r(22)),
                border: Border.all(
                  color: isSelected ? AppColors.gold : AppColors.border,
                  width: isSelected ? 1.5 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _store.toggleService(service.id));
                  },
                  borderRadius: BorderRadius.circular(context.r(22)),
                  child: Padding(
                    padding: EdgeInsets.all(context.r(16)),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(context.r(10)),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF352618)
                                : const Color(0xFF241A12),
                            borderRadius:
                                BorderRadius.circular(context.r(14)),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.gold.withValues(alpha: 0.55)
                                  : AppColors.gold.withValues(alpha: 0.22),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? AppColors.gold.withValues(alpha: 0.32)
                                    : AppColors.gold.withValues(alpha: 0.14),
                                blurRadius: isSelected ? 12 : 8,
                                spreadRadius: isSelected ? 1 : 0,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            _iconForService(service.id),
                            color: isSelected
                                ? AppColors.goldLight
                                : AppColors.gold.withValues(alpha: 0.85),
                            size: context.r(20),
                          ),
                        ),
                        SizedBox(width: context.w(14)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.title,
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontSize: context.sp(14),
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? AppColors.goldLight
                                      : AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: context.h(3)),
                              Text(
                                service.description,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: context.sp(11.5),
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: context.w(8)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '+£${service.price}',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.gold,
                                fontSize: context.sp(15),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: context.h(4)),
                            Container(
                              width: context.r(18),
                              height: context.r(18),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? AppColors.gold
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.gold
                                      : AppColors.border,
                                  width: 1.5,
                                ),
                              ),
                              child: isSelected
                                  ? Icon(
                                      Icons.check,
                                      color: AppColors.textOnGold,
                                      size: context.r(12),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          SizedBox(height: context.h(22)),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: CustomButton(
                  text: 'Back',
                  variant: ButtonVariant.outlined,
                  height: context.h(50),
                  onPressed: _prevStep,
                ),
              ),
              SizedBox(width: context.w(12)),
              Expanded(
                flex: 2,
                child: CustomButton(
                  text: 'Review Quote',
                  icon: Icons.arrow_forward_rounded,
                  height: context.h(50),
                  onPressed: _nextStep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ===========================================================================
  // STEP 4: REVIEW & INSTANT QUOTE
  // ===========================================================================
  Widget _buildStep4Quote() {
    final selectedServices =
        _store.availableServices.where((s) => s.isSelected).toList();
    final r = context.responsive;

    return SingleChildScrollView(
      key: const ValueKey('step4'),
      padding: EdgeInsets.symmetric(
        horizontal: r.pagePadding,
        vertical: context.h(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Grand Clean Quote Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.r(22)),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(context.r(22)),
              border: Border.all(
                color: AppColors.border,
                width: 1.0,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(context.r(12)),
                  decoration: BoxDecoration(
                    color: const Color(0xFF352618),
                    borderRadius: BorderRadius.circular(context.r(16)),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.5),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.goldLight,
                    size: context.r(26),
                  ),
                ),
                SizedBox(height: context.h(10)),
                Text(
                  'ALL-INCLUSIVE BESPOKE QUOTE',
                  style: AppTextStyles.overline.copyWith(
                    fontSize: context.sp(10),
                    letterSpacing: 1.8,
                    color: AppColors.gold,
                  ),
                ),
                SizedBox(height: context.h(4)),
                Text(
                  '£${_store.quoteGrandTotal}',
                  style: AppTextStyles.displayLarge.copyWith(
                    color: AppColors.gold,
                    fontSize: context.sp(36),
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: context.h(4)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(10),
                    vertical: context.h(4),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(context.r(12)),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '${_store.selectedProperty.label} · Guaranteed Fixed Rate',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: context.sp(11.5),
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.h(16)),

          // Transparent Invoice Breakdown Card
          Container(
            padding: EdgeInsets.all(context.r(18)),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(context.r(22)),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      color: AppColors.gold,
                      size: context.r(16),
                    ),
                    SizedBox(width: context.w(8)),
                    Text(
                      'Bespoke Breakdown',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontSize: context.sp(14),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.h(14)),
                _buildQuoteRow(
                  'Base ${_store.selectedProperty.label} relocation',
                  '£${_store.quoteBasePrice}',
                ),
                ...selectedServices.map(
                  (s) => _buildQuoteRow(s.title, '£${s.price}'),
                ),
                SizedBox(height: context.h(8)),
                const Divider(height: 1),
                SizedBox(height: context.h(12)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Payable',
                      style: AppTextStyles.titleLarge.copyWith(
                        fontSize: context.sp(16),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '£${_store.quoteGrandTotal}',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.gold,
                        fontSize: context.sp(20),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: context.h(16)),

          // 3 Trust Guarantees
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.w(14),
              vertical: context.h(12),
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(context.r(16)),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTrustItem(Icons.verified_user_rounded, 'Fully Insured'),
                _buildTrustItem(Icons.star_rounded, 'White-Glove'),
                _buildTrustItem(Icons.gps_fixed_rounded, 'Live Tracking'),
              ],
            ),
          ),
          SizedBox(height: context.h(24)),

          Row(
            children: [
              Expanded(
                flex: 1,
                child: CustomButton(
                  text: 'Back',
                  variant: ButtonVariant.outlined,
                  height: context.h(50),
                  onPressed: _prevStep,
                ),
              ),
              SizedBox(width: context.w(12)),
              Expanded(
                flex: 2,
                child: CustomButton(
                  text: 'Confirm & Schedule',
                  icon: Icons.check_circle_rounded,
                  height: context.h(50),
                  onPressed: _confirmBooking,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTrustItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.gold, size: context.r(14)),
        SizedBox(width: context.w(5)),
        Text(
          text,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: context.sp(10.5),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuoteRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: context.sp(12.5),
                color: AppColors.textMuted,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: context.sp(13),
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // STEP 5: SUCCESS / BOOKING CONFIRMATION
  // ===========================================================================
  Widget _buildSuccessScreen() {
    final active = _store.activeMove!;
    final r = context.responsive;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: r.maxContentWidth),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            r.pagePadding,
            context.h(24),
            r.pagePadding,
            16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: context.h(16)),

              // Animated Green Checkmark with Path-Drawn White Tick
              _AnimatedSuccessCheckmark(size: context.r(82)),

              SizedBox(height: context.h(20)),
              Text(
                'Relocation Scheduled!',
                style: AppTextStyles.displayMedium.copyWith(
                  fontSize: context.sp(22),
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.h(6)),
              Text(
                'Your move has been reserved with white-glove assurance.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: context.sp(12.5),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.h(14)),

              // Clean Reference Pill
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(14),
                  vertical: context.h(5),
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(context.r(16)),
                  border: Border.all(
                    color: AppColors.border,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ref: ',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: context.sp(11.5),
                      ),
                    ),
                    Text(
                      active.ref,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.gold,
                        fontSize: context.sp(12.5),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.h(24)),

              // Clean Aligned Summary Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(context.r(20)),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(context.r(22)),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildCleanDetailRow(
                      icon: Icons.apartment_rounded,
                      label: 'Residence',
                      value: active.title,
                    ),
                    Divider(
                      color: AppColors.border.withValues(alpha: 0.6),
                      height: context.h(22),
                    ),
                    _buildCleanDetailRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Date & Window',
                      value: '${active.dateString} · ${active.timeSlot}',
                    ),
                    Divider(
                      color: AppColors.border.withValues(alpha: 0.6),
                      height: context.h(22),
                    ),
                    // Clean Route Visual Alignment
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: context.h(2)),
                          child: Icon(
                            Icons.route_rounded,
                            size: context.r(16),
                            color: AppColors.gold,
                          ),
                        ),
                        SizedBox(width: context.w(10)),
                        Text(
                          'Route',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textMuted,
                            fontSize: context.sp(12),
                          ),
                        ),
                        SizedBox(width: context.w(14)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                active.fromAddress,
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontSize: context.sp(12.5),
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: context.h(4)),
                              Icon(
                                Icons.arrow_downward_rounded,
                                size: context.r(12),
                                color: AppColors.gold.withValues(alpha: 0.6),
                              ),
                              SizedBox(height: context.h(4)),
                              Text(
                                active.toAddress,
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontSize: context.sp(12.5),
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Divider(
                      color: AppColors.border.withValues(alpha: 0.6),
                      height: context.h(22),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Investment',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: context.sp(13),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '£${active.totalAmount}',
                          style: AppTextStyles.titleLarge.copyWith(
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
              SizedBox(height: context.h(28)),

              // Return to Concierge Home Primary Button
              CustomButton(
                text: 'Return to Concierge Home',
                icon: Icons.home_rounded,
                height: context.h(50),
                onPressed: () {
                  if (widget.onBackToHome != null) {
                    setState(() => _currentStep = 0);
                    widget.onBackToHome!();
                  } else if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    setState(() => _currentStep = 0);
                  }
                },
              ),
              SizedBox(height: context.h(12)),

              // View Move Details Text Link
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    AnimationHelper.smoothRoute(
                      page: MoveDetailScreen(move: active),
                    ),
                  );
                },
                icon: Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.gold,
                  size: context.r(16),
                ),
                label: Text(
                  'View full relocation details',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.gold,
                    fontSize: context.sp(13),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCleanDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: context.r(16),
          color: AppColors.gold,
        ),
        SizedBox(width: context.w(10)),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textMuted,
            fontSize: context.sp(12),
          ),
        ),
        SizedBox(width: context.w(12)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontSize: context.sp(12.5),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Animated Green Circle with smoothly path-drawn White Checkmark.
class _AnimatedSuccessCheckmark extends StatefulWidget {
  final double size;
  const _AnimatedSuccessCheckmark({this.size = 80});

  @override
  State<_AnimatedSuccessCheckmark> createState() =>
      _AnimatedSuccessCheckmarkState();
}

class _AnimatedSuccessCheckmarkState extends State<_AnimatedSuccessCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _tickAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );

    // Green circle pops in smoothly with gentle spring bounce
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );

    // White tick draws continuously from 0.40 to 1.0
    _tickAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 1.0, curve: Curves.easeInOutCubic),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF4ADE80).withValues(alpha: 0.6),
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.38),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: CustomPaint(
              painter: _DrawCheckmarkPainter(
                progress: _tickAnimation.value,
                color: Colors.white,
                strokeWidth: widget.size * 0.058,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DrawCheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _DrawCheckmarkPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final path = Path();
    path.moveTo(size.width * 0.28, size.height * 0.52);
    path.lineTo(size.width * 0.43, size.height * 0.68);
    path.lineTo(size.width * 0.72, size.height * 0.36);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final totalLength = metric.length;
    final currentLength = totalLength * progress.clamp(0.0, 1.0);
    final extractPath = metric.extractPath(0.0, currentLength);

    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DrawCheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

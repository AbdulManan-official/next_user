import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme_styles.dart';
import '../utils/responsive_helper.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/glass_kit.dart';
import '../models/move_model.dart';
import '../controllers/move_store.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Public data (send this to your backend in `onSubmit`)
// ═══════════════════════════════════════════════════════════════════════════

class BookingLocation {
  const BookingLocation({
    required this.street,
    required this.city,
    required this.postcode,
    this.building = '',
    this.area = '',
    this.floor,
    this.hasLift = false,
    this.parking,
  });

  final String street;
  final String building;
  final String area;
  final String city;
  final String postcode;
  final String? floor;
  final bool hasLift;
  final String? parking;

  String get fullAddress => [street, building, area, city, postcode]
      .where((e) => e.trim().isNotEmpty)
      .join(', ');

  Map<String, dynamic> toMap() => {
        'street': street,
        'building': building,
        'area': area,
        'city': city,
        'postcode': postcode,
        'floor': floor,
        'hasLift': hasLift,
        'parking': parking,
      };
}

class BookingInquiry {
  const BookingInquiry({
    required this.residence,
    required this.package,
    required this.addOns,
    required this.from,
    required this.to,
    required this.moveDate,
    required this.fullName,
    required this.phone,
    required this.estimatedTotal,
    this.timeSlot,
    this.dateFlexibility,
    this.email = '',
    this.notes = '',
  });

  final String residence;
  final String package;
  final List<String> addOns;
  final BookingLocation from;
  final BookingLocation to;
  final String moveDate;
  final String? timeSlot;
  final String? dateFlexibility;
  final String fullName;
  final String phone;
  final String email;
  final String notes;
  final int estimatedTotal;

  Map<String, dynamic> toMap() => {
        'residence': residence,
        'package': package,
        'addOns': addOns,
        'from': from.toMap(),
        'to': to.toMap(),
        'moveDate': moveDate,
        'timeSlot': timeSlot,
        'dateFlexibility': dateFlexibility,
        'fullName': fullName,
        'phone': phone,
        'email': email,
        'notes': notes,
        'estimatedTotal': estimatedTotal,
      };
}

// ═══════════════════════════════════════════════════════════════════════════
//  Constants & catalogue  (EDIT copy / prices here)
// ═══════════════════════════════════════════════════════════════════════════

const int _stepCount = 4;

const List<String> _stepTitles = [
  'Select Residence',
  'Move Details',
  'Choose Your Package',
  'Review & Submit',
];

const List<String> _stepShort = ['Residence', 'Details', 'Package', 'Review'];

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

const List<String> _floors = ['Ground', '1st', '2nd', '3rd+'];
const List<String> _parkingOptions = ['Driveway', 'On-street', 'Permit needed'];
const List<String> _flexOptions = ['Fixed date', '± 1–2 days', 'Flexible'];

typedef _TimeSlot = ({String id, String title, String hours, IconData icon});

const List<_TimeSlot> _timeSlots = [
  (
    id: 'Morning (08:00 – 12:00)',
    title: 'Morning',
    hours: '08:00 – 12:00',
    icon: Icons.wb_twilight_rounded,
  ),
  (
    id: 'Afternoon (12:00 – 16:00)',
    title: 'Afternoon',
    hours: '12:00 – 16:00',
    icon: Icons.wb_sunny_rounded,
  ),
  (
    id: 'Evening (16:00 – 20:00)',
    title: 'Evening',
    hours: '16:00 – 20:00',
    icon: Icons.nightlight_round_rounded,
  ),
];

class _Tier {
  const _Tier({
    required this.id,
    required this.name,
    required this.tag,
    required this.perks,
    required this.icon,
    required this.accent,
    required this.multiplier,
    this.popular = false,
  });

  final String id;
  final String name;
  final String tag;

  /// Short, tier-specific services (no "everything in X").
  final List<String> perks;
  final IconData icon;
  final Color accent;

  /// Indicative price = residence base price × multiplier.
  final double multiplier;
  final bool popular;
}

const List<_Tier> _tiers = [
  _Tier(
    id: 'silver',
    name: 'Silver',
    tag: 'ESSENTIAL',
    icon: Icons.workspace_premium_rounded,
    accent: Color(0xFFC9CED6),
    multiplier: 1.0,
    perks: ['Professional crew', 'Furniture wrapping', 'Transit cover'],
  ),
  _Tier(
    id: 'gold',
    name: 'Gold',
    tag: 'SIGNATURE',
    icon: Icons.military_tech_rounded,
    accent: Color(0xFFE8C26A),
    multiplier: 1.25,
    popular: true,
    perks: ['Fragile packing', 'Furniture reassembly', 'Enhanced cover'],
  ),
  _Tier(
    id: 'platinum',
    name: 'Platinum',
    tag: 'PRESTIGE',
    icon: Icons.auto_awesome_rounded,
    accent: Color(0xFFB9C7DE),
    multiplier: 1.6,
    perks: [
      'Full pack & unpack',
      'Move coordinator',
      'Live tracking',
      'Premium cover',
    ],
  ),
  _Tier(
    id: 'diamond',
    name: 'Diamond',
    tag: 'WHITE-GLOVE',
    icon: Icons.diamond_rounded,
    accent: Color(0xFF8FD3FF),
    multiplier: 2.1,
    perks: [
      'Art & antiques care',
      '14-day free storage',
      '24/7 concierge',
      'Full-value cover',
    ],
  ),
];

class _AddOn {
  const _AddOn({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.icon,
  });

  final String id;
  final String title;
  final String subtitle;
  final int price;
  final IconData icon;
}

const List<_AddOn> _addOns = [
  _AddOn(
    id: 'waste',
    title: 'Waste Removal & Clearance',
    subtitle: 'Licensed disposal of unwanted items. We leave it spotless.',
    price: 120,
    icon: Icons.delete_sweep_rounded,
  ),
  _AddOn(
    id: 'pack',
    title: 'Premium Packing Service',
    subtitle: 'Expert packing with archival-grade materials.',
    price: 180,
    icon: Icons.inventory_2_rounded,
  ),
  _AddOn(
    id: 'dismantle',
    title: 'Dismantle & Reassembly',
    subtitle: 'Beds, wardrobes & bespoke pieces, rebuilt perfectly.',
    price: 95,
    icon: Icons.handyman_rounded,
  ),
  _AddOn(
    id: 'store',
    title: 'Secure Storage',
    subtitle: 'Climate-controlled storage, flexible duration.',
    price: 150,
    icon: Icons.warehouse_rounded,
  ),
  _AddOn(
    id: 'clean',
    title: 'Post-Move Deep Clean',
    subtitle: 'Handover-ready, top to bottom.',
    price: 140,
    icon: Icons.cleaning_services_rounded,
  ),
];

String _formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

int _tierPrice(PropertyType p, _Tier t) {
  final num base = p.basePrice;
  return ((base * t.multiplier) / 5).round() * 5;
}

bool _validPhone(String v) => v.replaceAll(RegExp(r'\D'), '').length >= 7;
bool _validEmail(String v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);

// ═══════════════════════════════════════════════════════════════════════════
//  Form state (ChangeNotifier: selections only; text lives in controllers)
// ═══════════════════════════════════════════════════════════════════════════

class _LocationForm extends ChangeNotifier {
  final TextEditingController street = TextEditingController();
  final TextEditingController building = TextEditingController();
  final TextEditingController area = TextEditingController();
  final TextEditingController city = TextEditingController();
  final TextEditingController postcode = TextEditingController();

  String? _floor;
  bool _lift = false;
  String? _parking;

  String? get floor => _floor;
  bool get lift => _lift;
  String? get parking => _parking;

  set floor(String? v) {
    _floor = v;
    notifyListeners();
  }

  set lift(bool v) {
    _lift = v;
    notifyListeners();
  }

  set parking(String? v) {
    _parking = v;
    notifyListeners();
  }

  bool get isValid =>
      street.text.trim().isNotEmpty &&
      city.text.trim().isNotEmpty &&
      postcode.text.trim().isNotEmpty;

  BookingLocation toLocation() => BookingLocation(
        street: street.text.trim(),
        building: building.text.trim(),
        area: area.text.trim(),
        city: city.text.trim(),
        postcode: postcode.text.trim().toUpperCase(),
        floor: _floor,
        hasLift: _lift,
        parking: _parking,
      );

  void reset() {
    street.clear();
    building.clear();
    area.clear();
    city.clear();
    postcode.clear();
    _floor = null;
    _lift = false;
    _parking = null;
    notifyListeners();
  }

  @override
  void dispose() {
    street.dispose();
    building.dispose();
    area.dispose();
    city.dispose();
    postcode.dispose();
    super.dispose();
  }
}

class _BookingForm extends ChangeNotifier {
  final _LocationForm from = _LocationForm();
  final _LocationForm to = _LocationForm();

  final TextEditingController date = TextEditingController();
  final TextEditingController name = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController notes = TextEditingController();

  final Set<String> addOnIds = <String>{};

  PropertyType? _property;
  String? _tierId;
  String? _slot;
  String? _flex;
  bool _attempted = false;

  PropertyType? get property => _property;
  String? get slot => _slot;
  String? get flex => _flex;
  bool get attempted => _attempted;

  _Tier? get tier {
    if (_tierId == null) return null;
    return _tiers.firstWhere((t) => t.id == _tierId);
  }

  set property(PropertyType? v) {
    _property = v;
    notifyListeners();
  }

  set tierId(String? v) {
    _tierId = v;
    notifyListeners();
  }

  set slot(String? v) {
    _slot = v;
    notifyListeners();
  }

  set flex(String? v) {
    _flex = v;
    notifyListeners();
  }

  void toggleAddOn(String id) {
    if (!addOnIds.add(id)) addOnIds.remove(id);
    notifyListeners();
  }

  List<_AddOn> get selectedAddOns =>
      _addOns.where((a) => addOnIds.contains(a.id)).toList();

  int get estimate {
    final p = _property;
    final t = tier;
    if (p == null || t == null) return 0;
    var sum = _tierPrice(p, t);
    for (final a in selectedAddOns) {
      sum += a.price;
    }
    return sum;
  }

  /// Marks fields as "attempted" (shows errors) and reports validity.
  bool validateDetails() {
    _attempted = true;
    notifyListeners();
    return from.isValid &&
        to.isValid &&
        date.text.trim().isNotEmpty &&
        name.text.trim().isNotEmpty &&
        _validPhone(phone.text) &&
        (email.text.trim().isEmpty || _validEmail(email.text.trim()));
  }

  BookingInquiry toInquiry() => BookingInquiry(
        residence: _property!.label,
        package: tier!.name,
        addOns: selectedAddOns.map((a) => a.title).toList(),
        from: from.toLocation(),
        to: to.toLocation(),
        moveDate: date.text.trim(),
        timeSlot: _slot,
        dateFlexibility: _flex,
        fullName: name.text.trim(),
        phone: phone.text.trim(),
        email: email.text.trim(),
        notes: notes.text.trim(),
        estimatedTotal: estimate,
      );

  void reset() {
    from.reset();
    to.reset();
    date.clear();
    name.clear();
    phone.clear();
    email.clear();
    notes.clear();
    addOnIds.clear();
    _property = null;
    _tierId = null;
    _slot = null;
    _flex = null;
    _attempted = false;
    notifyListeners();
  }

  @override
  void dispose() {
    from.dispose();
    to.dispose();
    date.dispose();
    name.dispose();
    phone.dispose();
    email.dispose();
    notes.dispose();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Screen (state + navigation only; UI lives in small widgets below)
// ═══════════════════════════════════════════════════════════════════════════

/// Luxury 4-step concierge inquiry flow, glass edition.
class BookingFlowScreen extends StatefulWidget {
  const BookingFlowScreen({
    super.key,
    this.onBackToHome,
    this.onSubmit,
    this.ownBackground = true,
  });

  final VoidCallback? onBackToHome;

  /// Called on final submit. Send `inquiry.toMap()` to your API here.
  /// Throw to show an error. If null, falls back to the old [MoveStore] flow.
  final Future<void> Function(BookingInquiry inquiry)? onSubmit;

  /// Set false if parent shell already paints [GlassAmbientBackground].
  final bool ownBackground;

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  final MoveStore _store = MoveStore.instance;
  final _BookingForm _form = _BookingForm();

  int _step = 0; // 0 Residence, 1 Details, 2 Package, 3 Review
  bool _forward = true;
  bool _submitting = false;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  // ─── Navigation / actions ────────────────────────────────────────────────

  void _goTo(int target) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _forward = target > _step;
      _step = target;
    });
  }

  void _warn(String message) {
    HapticFeedback.mediumImpact();
    AppSnackBar.showWarning(context, message);
  }

  void _leaveFlow() {
    if (widget.onBackToHome != null) {
      widget.onBackToHome!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _showExitSheet() {
    HapticFeedback.lightImpact();
    showNxSheet<void>(
      context,
      builder: (ctx) => NxSheet(
        title: 'Save your booking draft?',
        subtitle: 'Selections kept safely. Resume your move anytime.',
        child: Column(
          children: [
            GoldButton(
              label: 'Save draft & exit',
              icon: Icons.bookmark_added_rounded,
              height: 52,
              shine: true,
              onTap: () {
                Navigator.pop(ctx);
                if (!mounted) return;
                AppSnackBar.showSuccess(context, 'Booking draft saved.');
                _leaveFlow();
              },
            ),
            const SizedBox(height: 10),
            _DangerButton(
              label: 'Discard booking',
              icon: Icons.delete_outline_rounded,
              onTap: () {
                Navigator.pop(ctx);
                if (!mounted) return;
                _form.reset();
                setState(() {
                  _forward = false;
                  _step = 0;
                });
                _leaveFlow();
              },
            ),
            const SizedBox(height: 10),
            GlassButton(
              label: 'Keep editing',
              height: 48,
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _next() {
    HapticFeedback.selectionClick();

    if (_step == 0 && _form.property == null) {
      _warn('Please select your residence type to continue.');
      return;
    }
    if (_step == 1 && !_form.validateDetails()) {
      _warn('Please complete the highlighted fields.');
      return;
    }
    if (_step == 2 && _form.tier == null) {
      _warn('Please choose a package to continue.');
      return;
    }
    _goTo(_step + 1);
  }

  void _prev() {
    if (_submitting) return;
    HapticFeedback.selectionClick();
    if (_step > 0) _goTo(_step - 1);
  }

  Future<void> _pickDate() async {
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.gold,
            onPrimary: AppColors.textOnGold,
            surface: AppColors.surfaceElevated,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      _form.date.text = _formatDate(picked);
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    HapticFeedback.heavyImpact();
    setState(() => _submitting = true);

    try {
      final inquiry = _form.toInquiry();

      if (widget.onSubmit != null) {
        await widget.onSubmit!(inquiry);
      } else {
        // Fallback: keep the original MoveStore behaviour.
        _store.setProperty(_form.property!);
        _store.setRoute(
          from: inquiry.from.fullAddress,
          to: inquiry.to.fullAddress,
          date: inquiry.moveDate,
          timeSlot: inquiry.timeSlot ?? '',
          additionalNotes: inquiry.notes,
        );
        _store.confirmNewBooking();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _warn('Could not submit your inquiry. Please try again.');
      return;
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Inquiry submitted',
      barrierColor: Colors.black.withValues(alpha: 0.68),
      transitionDuration: const Duration(milliseconds: 340),
      pageBuilder: (ctx, a1, a2) => _SubmittedDialog(
        onDone: () => Navigator.of(ctx).pop(),
      ),
      transitionBuilder: (ctx, animation, _, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );

    if (!mounted) return;
    _form.reset();
    setState(() {
      _forward = false;
      _step = 0;
    });
    if (widget.onBackToHome != null) {
      widget.onBackToHome!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  Widget _stepView() {
    final key = ValueKey<int>(_step);
    switch (_step) {
      case 1:
        return _Step2Details(
          key: key,
          form: _form,
          onPickDate: _pickDate,
          onBack: _prev,
          onNext: _next,
        );
      case 2:
        return _Step3Package(
          key: key,
          form: _form,
          onBack: _prev,
          onNext: _next,
        );
      case 3:
        return _Step4Review(
          key: key,
          form: _form,
          busy: _submitting,
          onEdit: _goTo,
          onBack: _prev,
          onSubmit: _submit,
        );
      default:
        return _Step1Residence(
          key: key,
          form: _form,
          onNext: _next,
        );
    }
  }

  Widget _transition(Widget child, Animation<double> animation) {
    final incoming = child.key == ValueKey<int>(_step);
    final dx = (incoming == _forward) ? 0.06 : -0.06;
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: Offset(dx, 0), end: Offset.zero)
            .animate(animation),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    final content = Column(
      children: [
        _Header(step: _step, onBack: _prev, onClose: _showExitSheet),
        RepaintBoundary(child: _StepProgress(current: _step)),
        Expanded(
          child: ClipRect(
            child: ListenableBuilder(
              listenable: _form,
              builder: (context, _) => AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topCenter,
                  fit: StackFit.expand,
                  children: [
                    ...previous,
                    ?current,
                  ],
                ),
                transitionBuilder: _transition,
                child: _stepView(),
              ),
            ),
          ),
        ),
      ],
    );

    final body = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: r.maxContentWidth),
        child: content,
      ),
    );

    if (!widget.ownBackground) return body;
    return Stack(
      children: [
        const Positioned.fill(child: GlassAmbientBackground()),
        body,
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Chrome: header + progress
// ═══════════════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  const _Header({
    required this.step,
    required this.onBack,
    required this.onClose,
  });

  final int step;
  final VoidCallback onBack;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final hasPrev = step > 0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        r.pagePadding,
        context.h(8),
        r.pagePadding,
        context.h(4),
      ),
      child: Row(
        children: [
          GlassCircleButton(
            icon: hasPrev
                ? Icons.arrow_back_ios_new_rounded
                : Icons.close_rounded,
            iconSize: 18,
            iconColor: AppColors.gold,
            semanticLabel: hasPrev ? 'Previous step' : 'Close booking',
            onTap: hasPrev ? onBack : onClose,
          ),
          SizedBox(width: context.w(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONCIERGE BOOKING',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.gold,
                    fontSize: context.sp(10),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.4,
                  ),
                ),
                SizedBox(height: context.h(2)),
                Text(
                  _stepTitles[step],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: context.sp(17),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '0${step + 1}',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.gold,
                    fontSize: context.sp(20),
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                TextSpan(
                  text: ' / 0$_stepCount',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textMuted,
                    fontSize: context.sp(11),
                    fontWeight: FontWeight.w600,
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

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.w(18),
        context.h(8),
        context.w(18),
        context.h(10),
      ),
      child: Row(
        children: List<Widget>.generate(_stepCount, (i) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.w(3)),
              child: _ProgressSegment(
                label: _stepShort[i],
                done: i < current,
                current: i == current,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ProgressSegment extends StatelessWidget {
  const _ProgressSegment({
    required this.label,
    required this.done,
    required this.current,
  });

  final String label;
  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final active = done || current;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          height: 5,
          decoration: BoxDecoration(
            gradient: active
                ? LinearGradient(
                    colors: AppColors.goldGradient
                        .map((c) => c.withValues(alpha: done ? 1 : 0.7))
                        .toList(),
                  )
                : null,
            color: active ? null : Colors.white.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(4),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.gold
                          .withValues(alpha: done ? 0.35 : 0.22),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        ),
        SizedBox(height: context.h(6)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (done) ...[
              const Icon(Icons.check_circle_rounded,
                  size: 11, color: AppColors.gold),
              const SizedBox(width: 3),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSmall.copyWith(
                  fontSize: context.sp(10),
                  color: done
                      ? AppColors.goldLight
                      : (current
                          ? AppColors.textPrimary
                          : AppColors.textMuted),
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Shared building blocks
// ═══════════════════════════════════════════════════════════════════════════

/// Sliver scroll host for every step. Bottom padding already includes the
/// floating nav bar (Scaffold extendBody) + system inset.
class _StepScroll extends StatelessWidget {
  const _StepScroll({required this.slivers});

  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            r.pagePadding,
            context.h(10),
            r.pagePadding,
            context.h(20) + bottom + 12,
          ),
          sliver: SliverMainAxisGroup(slivers: slivers),
        ),
      ],
    );
  }
}

/// Fade + rise entrance, staggered by [index]. Plays once per mount.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final totalMs = 380 + index * 70;
    final start = (index * 70) / totalMs;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: totalMs),
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - t)),
          child: child,
        ),
      ),
    );
  }
}

class _StepHeading extends StatelessWidget {
  const _StepHeading({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.headlineSmall.copyWith(
                  fontSize: context.sp(22),
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: context.h(3)),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: context.sp(12),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          SizedBox(width: context.w(10)),
          trailing!,
        ],
      ],
    );
  }
}

/// Small card title: gold icon tile + title + subtitle.
class _CardTitle extends StatelessWidget {
  const _CardTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        NxGoldIconTile(icon: icon, size: 36, iconSize: 18, radius: 12),
        SizedBox(width: context.w(12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.titleMedium.copyWith(
                  fontSize: context.sp(15),
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: context.sp(11),
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Selectable frosted tile (residence / slot / package / extra).
class _SelectableTile extends StatelessWidget {
  const _SelectableTile({
    required this.selected,
    required this.onTap,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 22,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.97,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: selected
                ? AppColors.gold.withValues(alpha: 0.75)
                : Colors.transparent,
            width: 1.4,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: GlassCard(
          radius: radius - 1.4,
          blur: 0,
          shadow: false,
          fillAlpha: selected ? 0.12 : 0.07,
          tintGold: selected,
          edgeTint: selected ? AppColors.gold : Colors.white,
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

class _CheckDot extends StatelessWidget {
  const _CheckDot({required this.selected, required this.size});

  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: selected
            ? const LinearGradient(
                colors: AppColors.goldGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        border: Border.all(
          color: selected
              ? Colors.white.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.22),
          width: 1.3,
        ),
      ),
      child: selected
          ? Icon(Icons.check_rounded,
              size: size * 0.66, color: AppColors.textOnGold)
          : null,
    );
  }
}

class _NavButtons extends StatelessWidget {
  const _NavButtons({
    required this.nextLabel,
    required this.onBack,
    required this.onNext,
    this.nextIcon = Icons.arrow_forward_rounded,
    this.busy = false,
  });

  final String nextLabel;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final IconData nextIcon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GlassButton(
            label: 'Back',
            height: 52,
            onTap: busy ? () {} : onBack,
          ),
        ),
        SizedBox(width: context.w(12)),
        Expanded(
          flex: 2,
          child: GoldButton(
            label: busy ? 'Submitting…' : nextLabel,
            icon: busy ? Icons.hourglass_top_rounded : nextIcon,
            height: 52,
            shine: !busy,
            onTap: busy ? () {} : onNext,
          ),
        ),
      ],
    );
  }
}

// ─── Glass input field (self-contained; supports keyboard type, multiline) ──

class _GlassField extends StatefulWidget {
  const _GlassField({
    required this.label,
    required this.controller,
    this.hint,
    this.icon,
    this.suffixIcon,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.words,
    this.textInputAction = TextInputAction.next,
    this.minLines = 1,
    this.maxLines = 1,
    this.maxChars,
    this.required = false,
    this.showError = false,
    this.validator,
    this.readOnly = false,
    this.onTap,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final IconData? icon;
  final IconData? suffixIcon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction textInputAction;
  final int minLines;
  final int maxLines;
  final int? maxChars;
  final bool required;
  final bool showError;
  final String? Function(String value)? validator;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  State<_GlassField> createState() => _GlassFieldState();
}

class _GlassFieldState extends State<_GlassField> {
  final FocusNode _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (mounted) setState(() => _focused = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  String? _error(String text) {
    if (!widget.showError) return null;
    final v = text.trim();
    if (widget.required && v.isEmpty) return 'Required';
    if (v.isNotEmpty) return widget.validator?.call(v);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final multiline = widget.maxLines > 1;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final error = _error(widget.controller.text);
        final hasError = error != null;

        final borderColor = hasError
            ? AppColors.error
            : (_focused ? AppColors.gold : AppColors.border);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Text(
                widget.required ? '${widget.label} *' : widget.label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: hasError
                      ? AppColors.error
                      : (_focused ? AppColors.gold : AppColors.textMuted),
                  fontSize: context.sp(10),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(horizontal: context.w(14)),
              decoration: BoxDecoration(
                color: hasError
                    ? AppColors.error.withValues(alpha: 0.10)
                    : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: borderColor,
                  width: _focused ? 1.5 : 1.0,
                ),
                boxShadow: _focused
                    ? [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.16),
                          blurRadius: 14,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                crossAxisAlignment: multiline
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  if (widget.icon != null)
                    Padding(
                      padding: EdgeInsets.only(
                        top: multiline ? 15 : 0,
                        right: context.w(10),
                      ),
                      child: Icon(
                        widget.icon,
                        size: 20,
                        color: _focused ? AppColors.gold : AppColors.textMuted,
                      ),
                    ),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focus,
                      readOnly: widget.readOnly,
                      showCursor: !widget.readOnly,
                      canRequestFocus: !widget.readOnly,
                      onTap: widget.onTap,
                      keyboardType: multiline
                          ? TextInputType.multiline
                          : widget.keyboardType,
                      textCapitalization: widget.textCapitalization,
                      textInputAction: multiline
                          ? TextInputAction.newline
                          : widget.textInputAction,
                      minLines: widget.minLines,
                      maxLines: widget.maxLines,
                      inputFormatters: widget.maxChars == null
                          ? null
                          : [LengthLimitingTextInputFormatter(widget.maxChars)],
                      cursorColor: AppColors.gold,
                      keyboardAppearance: Brightness.dark,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: context.sp(14),
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: false,
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintText: widget.hint,
                        hintStyle: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textMuted.withValues(alpha: 0.75),
                          fontSize: context.sp(13),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                      ),
                    ),
                  ),
                  if (widget.suffixIcon != null)
                    Padding(
                      padding: EdgeInsets.only(
                        left: context.w(8),
                        top: multiline ? 15 : 0,
                      ),
                      child: Icon(
                        widget.suffixIcon,
                        size: 18,
                        color: AppColors.gold,
                      ),
                    ),
                ],
              ),
            ),
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(left: 6, top: 5),
                child: Text(
                  error,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.error,
                    fontSize: context.sp(10.5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ChoiceChips extends StatelessWidget {
  const _ChoiceChips({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in options)
          Pressable(
            onTap: () => onSelected(selected == o ? null : o),
            scale: 0.95,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: selected == o
                    ? AppColors.gold.withValues(alpha: 0.16)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected == o
                      ? AppColors.gold.withValues(alpha: 0.7)
                      : Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: Text(
                o,
                style: AppTextStyles.labelMedium.copyWith(
                  color: selected == o
                      ? AppColors.goldLight
                      : AppColors.textSecondary,
                  fontSize: context.sp(12),
                  fontWeight:
                      selected == o ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.gold),
        SizedBox(width: context.w(10)),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontSize: context.sp(13),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? AppColors.textOnGold
                : AppColors.textMuted,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? AppColors.gold
                : Colors.white.withValues(alpha: 0.12),
          ),
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        ),
      ],
    );
  }
}

class _MiniLabel extends StatelessWidget {
  const _MiniLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textMuted,
          fontSize: context.sp(10),
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  STEP 1: RESIDENCE  (nothing selected by default)
// ═══════════════════════════════════════════════════════════════════════════

class _Step1Residence extends StatelessWidget {
  const _Step1Residence({
    super.key,
    required this.form,
    required this.onNext,
  });

  final _BookingForm form;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final properties = PropertyType.values;
    final selected = form.property;

    return _StepScroll(
      slivers: [
        const SliverToBoxAdapter(
          child: _Reveal(
            index: 0,
            child: _StepHeading(
              title: 'Where do you live?',
              subtitle:
                  'Tell us about your home. We tailor crew, vehicles & equipment around it.',
              trailing: StatusPill(
                label: 'WHITE GLOVE',
                icon: Icons.star_rounded,
                color: AppColors.gold,
                fontSize: 9.5,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: context.h(16))),
        SliverGrid.builder(
          itemCount: properties.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: r.gridColumns(mobile: 2, tablet: 3, desktop: 4),
            crossAxisSpacing: context.w(10),
            mainAxisSpacing: context.h(10),
            childAspectRatio: 1.34,
          ),
          itemBuilder: (context, i) {
            final prop = properties[i];
            return _Reveal(
              index: i + 1,
              child: _PropertyTile(
                property: prop,
                selected: selected == prop,
                onTap: () => form.property = prop,
              ),
            );
          },
        ),
        SliverToBoxAdapter(child: SizedBox(height: context.h(12))),
        SliverToBoxAdapter(
          child: GoldButton(
            label: 'Continue to Move Details',
            icon: Icons.arrow_forward_rounded,
            height: 52,
            shine: true,
            onTap: onNext,
          ),
        ),
      ],
    );
  }
}

class _PropertyTile extends StatelessWidget {
  const _PropertyTile({
    required this.property,
    required this.selected,
    required this.onTap,
  });

  final PropertyType property;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SelectableTile(
      selected: selected,
      onTap: onTap,
      padding: EdgeInsets.symmetric(
        horizontal: context.r(12),
        vertical: context.r(10),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: _CheckDot(selected: selected, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              NxGoldIconTile(
                icon: property.icon,
                size: 34,
                iconSize: 17,
                radius: 11,
              ),
              SizedBox(height: context.h(8)),
              Text(
                property.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleMedium.copyWith(
                  color:
                      selected ? AppColors.goldLight : AppColors.textPrimary,
                  fontSize: context.sp(13),
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: context.h(2)),
              Text(
                'From £${property.basePrice}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: selected ? AppColors.gold : AppColors.textMuted,
                  fontSize: context.sp(11),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  STEP 2: MOVE DETAILS
// ═══════════════════════════════════════════════════════════════════════════

class _Step2Details extends StatelessWidget {
  const _Step2Details({
    super.key,
    required this.form,
    required this.onPickDate,
    required this.onBack,
    required this.onNext,
  });

  final _BookingForm form;
  final VoidCallback onPickDate;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final attempted = form.attempted;

    return _StepScroll(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Reveal(
                index: 0,
                child: _StepHeading(
                  title: 'Your Move, Perfectly Planned',
                  subtitle:
                      'Where from, where to, and when. We handle everything in between.',
                ),
              ),
              SizedBox(height: context.h(18)),

              // Moving From
              _Reveal(
                index: 1,
                child: _LocationCard(
                  title: 'Moving From',
                  subtitle: 'Your current address',
                  icon: Icons.radio_button_checked_rounded,
                  location: form.from,
                  showError: attempted,
                ),
              ),
              const _RouteConnector(),

              // Moving To
              _Reveal(
                index: 2,
                child: _LocationCard(
                  title: 'Moving To',
                  subtitle: 'Your new address',
                  icon: Icons.location_on_rounded,
                  location: form.to,
                  showError: attempted,
                ),
              ),
              SizedBox(height: context.h(16)),

              // Date & timing
              _Reveal(
                index: 3,
                child: GlassCard(
                  radius: 26,
                  blur: 0,
                  fillAlpha: 0.08,
                  padding: EdgeInsets.all(context.r(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _CardTitle(
                        icon: Icons.event_available_rounded,
                        title: 'Move Date & Timing',
                        subtitle: 'When should we arrive?',
                      ),
                      SizedBox(height: context.h(14)),
                      _GlassField(
                        label: 'MOVE DATE',
                        hint: 'Select your preferred date',
                        controller: form.date,
                        icon: Icons.calendar_today_rounded,
                        suffixIcon: Icons.expand_more_rounded,
                        readOnly: true,
                        onTap: onPickDate,
                        required: true,
                        showError: attempted,
                      ),
                      SizedBox(height: context.h(14)),
                      const _MiniLabel('ARRIVAL WINDOW (OPTIONAL)'),
                      Row(
                        children: [
                          for (final slot in _timeSlots)
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.w(3),
                                ),
                                child: _SlotTile(
                                  slot: slot,
                                  selected: form.slot == slot.id,
                                  onTap: () => form.slot =
                                      form.slot == slot.id ? null : slot.id,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: context.h(14)),
                      const _MiniLabel('DATE FLEXIBILITY (OPTIONAL)'),
                      _ChoiceChips(
                        options: _flexOptions,
                        selected: form.flex,
                        onSelected: (v) => form.flex = v,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: context.h(16)),

              // Contact
              _Reveal(
                index: 4,
                child: GlassCard(
                  radius: 26,
                  blur: 0,
                  fillAlpha: 0.08,
                  padding: EdgeInsets.all(context.r(16)),
                  child: Column(
                    children: [
                      const _CardTitle(
                        icon: Icons.person_rounded,
                        title: 'Your Contact Details',
                        subtitle: 'So our concierge can reach you',
                      ),
                      SizedBox(height: context.h(14)),
                      _GlassField(
                        label: 'FULL NAME',
                        hint: 'e.g. James Whitmore',
                        controller: form.name,
                        icon: Icons.badge_rounded,
                        required: true,
                        showError: attempted,
                      ),
                      SizedBox(height: context.h(12)),
                      _GlassField(
                        label: 'PHONE NUMBER',
                        hint: 'e.g. 07700 900123',
                        controller: form.phone,
                        icon: Icons.phone_rounded,
                        keyboardType: TextInputType.phone,
                        textCapitalization: TextCapitalization.none,
                        required: true,
                        showError: attempted,
                        validator: (v) =>
                            _validPhone(v) ? null : 'Enter a valid phone number',
                      ),
                      SizedBox(height: context.h(12)),
                      _GlassField(
                        label: 'EMAIL (OPTIONAL)',
                        hint: 'e.g. james@email.com',
                        controller: form.email,
                        icon: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        textCapitalization: TextCapitalization.none,
                        showError: attempted,
                        validator: (v) =>
                            _validEmail(v) ? null : 'Enter a valid email',
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: context.h(16)),

              // Special instructions (tall)
              _Reveal(
                index: 5,
                child: GlassCard(
                  radius: 26,
                  blur: 0,
                  fillAlpha: 0.08,
                  padding: EdgeInsets.all(context.r(16)),
                  child: Column(
                    children: [
                      const _CardTitle(
                        icon: Icons.edit_note_rounded,
                        title: 'Special Instructions',
                        subtitle: 'Anything we should know?',
                      ),
                      SizedBox(height: context.h(14)),
                      _GlassField(
                        label: 'NOTES (OPTIONAL)',
                        hint:
                            'e.g. Antique grandfather clock, narrow stairs, piano, access codes, fragile items, parking restrictions…',
                        controller: form.notes,
                        icon: Icons.notes_rounded,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.newline,
                        minLines: 5,
                        maxLines: 8,
                        maxChars: 500,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: context.h(26)),

              _NavButtons(
                nextLabel: 'Choose Your Package',
                onBack: onBack,
                onNext: onNext,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.location,
    required this.showError,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final _LocationForm location;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 26,
      blur: 0,
      fillAlpha: 0.08,
      padding: EdgeInsets.all(context.r(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(icon: icon, title: title, subtitle: subtitle),
          SizedBox(height: context.h(14)),
          _GlassField(
            label: 'HOUSE / FLAT NO. & STREET',
            hint: 'e.g. 12 Kingsway',
            controller: location.street,
            icon: Icons.home_rounded,
            required: true,
            showError: showError,
          ),
          SizedBox(height: context.h(12)),
          _GlassField(
            label: 'BUILDING / APARTMENT NAME (OPTIONAL)',
            hint: 'e.g. Rosewood Court, Flat 4B',
            controller: location.building,
            icon: Icons.apartment_rounded,
          ),
          SizedBox(height: context.h(12)),
          _GlassField(
            label: 'AREA / DISTRICT (OPTIONAL)',
            hint: 'e.g. Langley',
            controller: location.area,
            icon: Icons.map_rounded,
          ),
          SizedBox(height: context.h(12)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: _GlassField(
                  label: 'CITY / TOWN',
                  hint: 'e.g. Slough',
                  controller: location.city,
                  icon: Icons.location_city_rounded,
                  required: true,
                  showError: showError,
                ),
              ),
              SizedBox(width: context.w(10)),
              Expanded(
                flex: 4,
                child: _GlassField(
                  label: 'POSTCODE',
                  hint: 'SL1 1XN',
                  controller: location.postcode,
                  icon: Icons.pin_drop_rounded,
                  textCapitalization: TextCapitalization.characters,
                  required: true,
                  showError: showError,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(16)),
          ListenableBuilder(
            listenable: location,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _MiniLabel('FLOOR LEVEL (OPTIONAL)'),
                _ChoiceChips(
                  options: _floors,
                  selected: location.floor,
                  onSelected: (v) => location.floor = v,
                ),
                SizedBox(height: context.h(12)),
                _SwitchRow(
                  icon: Icons.elevator_rounded,
                  label: 'Lift available',
                  value: location.lift,
                  onChanged: (v) => location.lift = v,
                ),
                SizedBox(height: context.h(8)),
                const _MiniLabel('PARKING FOR OUR VAN (OPTIONAL)'),
                _ChoiceChips(
                  options: _parkingOptions,
                  selected: location.parking,
                  onSelected: (v) => location.parking = v,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteConnector extends StatelessWidget {
  const _RouteConnector();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: context.h(8),
        horizontal: context.w(22),
      ),
      child: Row(
        children: [
          Container(
            width: 1.5,
            height: context.h(22),
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
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.slot,
    required this.selected,
    required this.onTap,
  });

  final _TimeSlot slot;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SelectableTile(
      selected: selected,
      radius: 20,
      padding: EdgeInsets.symmetric(
        vertical: context.h(12),
        horizontal: context.w(6),
      ),
      onTap: onTap,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NxGoldIconTile(
              icon: slot.icon,
              size: 34,
              iconSize: 17,
              radius: 11,
            ),
            SizedBox(height: context.h(8)),
            Text(
              slot.title,
              style: AppTextStyles.labelMedium.copyWith(
                color: selected ? AppColors.goldLight : AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: context.sp(11.5),
              ),
            ),
            SizedBox(height: context.h(2)),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                slot.hours,
                style: AppTextStyles.bodySmall.copyWith(
                  color: selected ? AppColors.gold : AppColors.textMuted,
                  fontSize: context.sp(9.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  STEP 3: PACKAGE  (Silver / Gold / Platinum / Diamond + extras)
// ═══════════════════════════════════════════════════════════════════════════

class _Step3Package extends StatelessWidget {
  const _Step3Package({
    super.key,
    required this.form,
    required this.onBack,
    required this.onNext,
  });

  final _BookingForm form;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final property = form.property;
    final selectedTier = form.tier;

    return _StepScroll(
      slivers: [
        const SliverToBoxAdapter(
          child: _Reveal(
            index: 0,
            child: _StepHeading(
              title: 'Choose Your Experience',
              subtitle:
                  'From essential care to uncompromising white-glove. Every move, crafted your way.',
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: context.h(18))),
        SliverList.builder(
          itemCount: _tiers.length,
          itemBuilder: (context, i) {
            final t = _tiers[i];
            return Padding(
              padding: EdgeInsets.only(bottom: context.h(12)),
              child: _Reveal(
                index: i + 1,
                child: _TierTile(
                  tier: t,
                  selected: selectedTier?.id == t.id,
                  priceLabel: property == null
                      ? null
                      : '£${_tierPrice(property, t)}',
                  onTap: () => form.tierId = t.id,
                ),
              ),
            );
          },
        ),
        SliverToBoxAdapter(child: SizedBox(height: context.h(8))),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const NxSectionTitle('TAILOR-MADE EXTRAS · OPTIONAL'),
              SizedBox(height: context.h(10)),
            ],
          ),
        ),
        SliverList.builder(
          itemCount: _addOns.length,
          itemBuilder: (context, i) {
            final a = _addOns[i];
            return Padding(
              padding: EdgeInsets.only(bottom: context.h(10)),
              child: _AddOnTile(
                addOn: a,
                selected: form.addOnIds.contains(a.id),
                onTap: () => form.toggleAddOn(a.id),
              ),
            );
          },
        ),
        SliverToBoxAdapter(child: SizedBox(height: context.h(8))),
        SliverToBoxAdapter(
          child: Center(
            child: Text(
              'Prices are indicative. Your concierge confirms the final quote.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
                fontSize: context.sp(10.5),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: context.h(18))),
        SliverToBoxAdapter(
          child: _NavButtons(
            nextLabel: 'Review Your Request',
            onBack: onBack,
            onNext: onNext,
          ),
        ),
      ],
    );
  }
}

class _TierTile extends StatelessWidget {
  const _TierTile({
    required this.tier,
    required this.selected,
    required this.priceLabel,
    required this.onTap,
  });

  final _Tier tier;
  final bool selected;
  final String? priceLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SelectableTile(
      selected: selected,
      radius: 24,
      padding: EdgeInsets.symmetric(
        horizontal: context.r(14),
        vertical: context.r(13),
      ),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NxGoldIconTile(icon: tier.icon, size: 40, iconSize: 20, radius: 13),
              SizedBox(width: context.w(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          tier.name,
                          style: AppTextStyles.titleLarge.copyWith(
                            color: tier.accent,
                            fontSize: context.sp(17),
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (tier.popular)
                          const StatusPill(
                            label: 'POPULAR',
                            icon: Icons.star_rounded,
                            color: AppColors.gold,
                            fontSize: 8.5,
                          ),
                      ],
                    ),
                    Text(
                      tier.tag,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.gold,
                        fontSize: context.sp(9.5),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              if (priceLabel != null) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'from',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: context.sp(9.5),
                      ),
                    ),
                    Text(
                      priceLabel!,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.gold,
                        fontSize: context.sp(17),
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: context.w(10)),
              ],
              _CheckDot(selected: selected, size: 20),
            ],
          ),
          SizedBox(height: context.h(10)),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final perk in tier.perks) _PerkChip(text: perk)],
          ),
        ],
      ),
    );
  }
}

class _PerkChip extends StatelessWidget {
  const _PerkChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, size: 12, color: AppColors.gold),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: context.sp(11),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddOnTile extends StatelessWidget {
  const _AddOnTile({
    required this.addOn,
    required this.selected,
    required this.onTap,
  });

  final _AddOn addOn;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SelectableTile(
      selected: selected,
      padding: EdgeInsets.all(context.r(14)),
      onTap: onTap,
      child: Row(
        children: [
          NxGoldIconTile(icon: addOn.icon, size: 40, iconSize: 19, radius: 13),
          SizedBox(width: context.w(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  addOn.title,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontSize: context.sp(13.5),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color:
                        selected ? AppColors.goldLight : AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: context.h(2)),
                Text(
                  addOn.subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: context.sp(11),
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: context.w(10)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+£${addOn.price}',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.gold,
                  fontSize: context.sp(14),
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: context.h(6)),
              _CheckDot(selected: selected, size: 20),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  STEP 4: REVIEW & SUBMIT
// ═══════════════════════════════════════════════════════════════════════════

class _Step4Review extends StatelessWidget {
  const _Step4Review({
    super.key,
    required this.form,
    required this.busy,
    required this.onEdit,
    required this.onBack,
    required this.onSubmit,
  });

  final _BookingForm form;
  final bool busy;
  final ValueChanged<int> onEdit;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  String _access(_LocationForm l) {
    final parts = <String>[
      if (l.floor != null) '${l.floor} floor',
      l.lift ? 'Lift available' : 'No lift',
      if (l.parking != null) 'Parking: ${l.parking}',
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final property = form.property;
    final tier = form.tier;
    if (property == null || tier == null) {
      return const _StepScroll(slivers: [SliverToBoxAdapter()]);
    }

    final from = form.from.toLocation();
    final to = form.to.toLocation();
    final addOns = form.selectedAddOns;
    final notes = form.notes.text.trim();
    final email = form.email.text.trim();
    final total = '£${form.estimate}';

    return _StepScroll(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Reveal(
                index: 0,
                child: _StepHeading(
                  title: 'Review Your Request',
                  subtitle:
                      'Everything look perfect? Submit and your personal concierge will be in touch.',
                ),
              ),
              SizedBox(height: context.h(16)),

              _Reveal(
                index: 1,
                child: _ReviewCard(
                  icon: Icons.workspace_premium_rounded,
                  title: 'Residence & Package',
                  onEdit: () => onEdit(0),
                  children: [
                    _KvRow(label: 'Residence', value: property.label),
                    _KvRow(
                      label: 'Package',
                      value: '${tier.name} · ${tier.tag}',
                    ),
                    _KvRow(
                      label: 'Extras',
                      value: addOns.isEmpty
                          ? 'None selected'
                          : addOns.map((a) => a.title).join(', '),
                      last: true,
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.h(12)),

              _Reveal(
                index: 2,
                child: _ReviewCard(
                  icon: Icons.radio_button_checked_rounded,
                  title: 'Moving From',
                  onEdit: () => onEdit(1),
                  children: [
                    _KvRow(label: 'Address', value: from.fullAddress),
                    _KvRow(
                      label: 'Access',
                      value: _access(form.from),
                      last: true,
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.h(12)),

              _Reveal(
                index: 3,
                child: _ReviewCard(
                  icon: Icons.location_on_rounded,
                  title: 'Moving To',
                  onEdit: () => onEdit(1),
                  children: [
                    _KvRow(label: 'Address', value: to.fullAddress),
                    _KvRow(
                      label: 'Access',
                      value: _access(form.to),
                      last: true,
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.h(12)),

              _Reveal(
                index: 4,
                child: _ReviewCard(
                  icon: Icons.event_available_rounded,
                  title: 'Schedule & Contact',
                  onEdit: () => onEdit(1),
                  children: [
                    _KvRow(label: 'Date', value: form.date.text.trim()),
                    _KvRow(
                      label: 'Window',
                      value: form.slot ?? 'No preference',
                    ),
                    _KvRow(
                      label: 'Flexibility',
                      value: form.flex ?? 'Not specified',
                    ),
                    _KvRow(label: 'Name', value: form.name.text.trim()),
                    _KvRow(
                      label: 'Phone',
                      value: form.phone.text.trim(),
                      last: email.isEmpty,
                    ),
                    if (email.isNotEmpty)
                      _KvRow(label: 'Email', value: email, last: true),
                  ],
                ),
              ),
              if (notes.isNotEmpty) ...[
                SizedBox(height: context.h(12)),
                _Reveal(
                  index: 5,
                  child: _ReviewCard(
                    icon: Icons.edit_note_rounded,
                    title: 'Special Instructions',
                    onEdit: () => onEdit(1),
                    children: [_KvRow(label: 'Notes', value: notes, last: true)],
                  ),
                ),
              ],
              SizedBox(height: context.h(16)),

              // Estimate
              _Reveal(
                index: 6,
                child: GlassCard(
                  radius: 30,
                  blur: 0,
                  fillAlpha: 0.10,
                  tintGold: true,
                  highlight: true,
                  padding: EdgeInsets.all(context.r(20)),
                  child: Column(
                    children: [
                      Text(
                        'INDICATIVE ESTIMATE',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: context.sp(10),
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gold,
                        ),
                      ),
                      SizedBox(height: context.h(6)),
                      ShaderMask(
                        shaderCallback: (rect) => const LinearGradient(
                          colors: AppColors.goldGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(rect),
                        child: Text(
                          total,
                          style: AppTextStyles.displayLarge.copyWith(
                            color: Colors.white,
                            fontSize: context.sp(38),
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                      SizedBox(height: context.h(8)),
                      const StatusPill(
                        label: 'NO OBLIGATION · FINAL QUOTE BY OUR TEAM',
                        icon: Icons.verified_rounded,
                        color: AppColors.gold,
                        fontSize: 9,
                      ),
                      SizedBox(height: context.h(16)),
                      const NxHairline(),
                      SizedBox(height: context.h(14)),
                      _QuoteRow(
                        label: '${property.label} · ${tier.name} package',
                        value: '£${_tierPrice(property, tier)}',
                      ),
                      for (final a in addOns)
                        _QuoteRow(label: a.title, value: '£${a.price}'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: context.h(14)),

              const _Reveal(
                index: 7,
                child: _TrustStrip(),
              ),
              SizedBox(height: context.h(10)),
              Center(
                child: Text(
                  'By submitting you agree to be contacted about this request.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    fontSize: context.sp(10.5),
                  ),
                ),
              ),
              SizedBox(height: context.h(20)),

              _NavButtons(
                nextLabel: 'Submit Inquiry',
                nextIcon: Icons.send_rounded,
                busy: busy,
                onBack: onBack,
                onNext: onSubmit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.icon,
    required this.title,
    required this.onEdit,
    required this.children,
  });

  final IconData icon;
  final String title;
  final VoidCallback onEdit;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 24,
      blur: 0,
      fillAlpha: 0.08,
      padding: EdgeInsets.all(context.r(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NxGoldIconTile(icon: icon, size: 32, iconSize: 16, radius: 10),
              SizedBox(width: context.w(10)),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontSize: context.sp(14.5),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Pressable(
                onTap: onEdit,
                scale: 0.95,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Text(
                    'Edit',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.gold,
                      fontSize: context.sp(12),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(12)),
          ...children,
        ],
      ),
    );
  }
}

class _KvRow extends StatelessWidget {
  const _KvRow({required this.label, required this.value, this.last = false});

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : context.h(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: context.w(88),
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
                fontSize: context.sp(12),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontSize: context.sp(12.5),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteRow extends StatelessWidget {
  const _QuoteRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: context.sp(12.5),
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: context.sp(13),
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 20,
      blur: 0,
      padding: EdgeInsets.symmetric(
        horizontal: context.w(12),
        vertical: context.h(14),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _TrustItem(icon: Icons.verified_user_rounded, text: 'Fully Insured'),
          _TrustItem(icon: Icons.star_rounded, text: 'White-Glove'),
          _TrustItem(icon: Icons.support_agent_rounded, text: 'Concierge'),
        ],
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.gold, size: 14),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: context.sp(10.5),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  SUBMITTED POP-UP
// ═══════════════════════════════════════════════════════════════════════════

class _SubmittedDialog extends StatelessWidget {
  const _SubmittedDialog({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Material(
        type: MaterialType.transparency,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.w(26)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: GlassCard(
                radius: 32,
                blur: 24,
                fillAlpha: 0.14,
                tintGold: true,
                highlight: true,
                padding: EdgeInsets.fromLTRB(
                  context.r(24),
                  context.r(30),
                  context.r(24),
                  context.r(22),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _AnimatedSuccessCheckmark(size: context.r(84)),
                    SizedBox(height: context.h(22)),
                    Text(
                      'Inquiry Submitted!',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headlineSmall.copyWith(
                        fontSize: context.sp(23),
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: context.h(10)),
                    Text(
                      'Your booking quote has been submitted successfully. Our team will contact you soon.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: context.sp(13),
                        height: 1.45,
                      ),
                    ),
                    SizedBox(height: context.h(24)),
                    GoldButton(
                      label: 'Done',
                      icon: Icons.check_rounded,
                      height: 52,
                      shine: true,
                      onTap: onDone,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Local helpers
// ═══════════════════════════════════════════════════════════════════════════

/// Destructive action: red-tinted glass pill (kit has no danger variant).
class _DangerButton extends StatelessWidget {
  const _DangerButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Pressable(
        onTap: onTap,
        scale: 0.97,
        child: Container(
          height: 50,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.45)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: AppColors.error),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Green circle with a tick that draws itself.
class _AnimatedSuccessCheckmark extends StatefulWidget {
  const _AnimatedSuccessCheckmark({this.size = 80});

  final double size;

  @override
  State<_AnimatedSuccessCheckmark> createState() =>
      _AnimatedSuccessCheckmarkState();
}

class _AnimatedSuccessCheckmarkState extends State<_AnimatedSuccessCheckmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _tick;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _scale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
    );
    _tick = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.40, 1.0, curve: Curves.easeInOutCubic),
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
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Transform.scale(
            scale: _scale.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.42),
                    blurRadius: 28,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: CustomPaint(
                painter: _CheckPainter(
                  progress: _tick.value,
                  color: Colors.white,
                  strokeWidth: widget.size * 0.058,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final path = Path()
      ..moveTo(size.width * 0.28, size.height * 0.52)
      ..lineTo(size.width * 0.43, size.height * 0.68)
      ..lineTo(size.width * 0.72, size.height * 0.36);

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress.clamp(0.0, 1.0)),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _CheckPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}
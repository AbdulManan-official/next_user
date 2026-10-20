import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_theme_styles.dart';

/// Country details model for international dialing codes
class CountryCodeItem {
  final String name;
  final String dialCode;
  final String isoCode;
  final String hint;
  final String subtitle;

  const CountryCodeItem({
    required this.name,
    required this.dialCode,
    required this.isoCode,
    required this.hint,
    required this.subtitle,
  });
}

/// Supported countries: United Kingdom (+44) and Pakistan (+92)
const List<CountryCodeItem> supportedCountries = [
  CountryCodeItem(
    name: 'United Kingdom',
    dialCode: '+44',
    isoCode: 'GB',
    hint: '7911 123456',
    subtitle: 'UK (+44)',
  ),
  CountryCodeItem(
    name: 'Pakistan',
    dialCode: '+92',
    isoCode: 'PK',
    hint: '300 1234567',
    subtitle: 'Pakistan (+92)',
  ),
];

/// Dual-Country (+44 UK / +92 PK) Phone Input Field featuring native popup selector.
/// Eliminates Navigator conflicts and provides rock-solid country selection.
class PhoneInputField extends StatefulWidget {
  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final CountryCodeItem? initialCountry;
  final ValueChanged<CountryCodeItem>? onCountryChanged;

  const PhoneInputField({
    super.key,
    this.label = 'Mobile Number',
    this.hintText,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onFieldSubmitted,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.initialCountry,
    this.onCountryChanged,
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  late CountryCodeItem _selectedCountry;
  late FocusNode _internalFocusNode;
  bool _isFocused = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.initialCountry ?? supportedCountries.first;
    _internalFocusNode = widget.focusNode ?? FocusNode();
    _internalFocusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() => _isFocused = _internalFocusNode.hasFocus);
    }
  }

  @override
  void didUpdateWidget(covariant PhoneInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCountry != null &&
        widget.initialCountry != oldWidget.initialCountry) {
      _selectedCountry = widget.initialCountry!;
    }
    if (widget.focusNode != null && widget.focusNode != oldWidget.focusNode) {
      _internalFocusNode.removeListener(_handleFocusChange);
      _internalFocusNode = widget.focusNode!;
      _internalFocusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    } else {
      _internalFocusNode.removeListener(_handleFocusChange);
    }
    super.dispose();
  }

  Widget _buildCountrySelector() {
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: AppColors.surface,
          elevation: 16,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border, width: 1.2),
          ),
        ),
      ),
      child: PopupMenuButton<CountryCodeItem>(
        tooltip: 'Select Country Code',
        initialValue: _selectedCountry,
        offset: const Offset(8, 54),
        onSelected: (CountryCodeItem c) {
          HapticFeedback.selectionClick();
          setState(() => _selectedCountry = c);
          widget.onCountryChanged?.call(c);
        },
        itemBuilder: (ctx) => supportedCountries.map((c) {
          final isSelected = c.isoCode == _selectedCountry.isoCode;
          return PopupMenuItem<CountryCodeItem>(
            value: c,
            height: 52,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CountryFlag(isoCode: c.isoCode, width: 28, height: 18),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      c.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${c.dialCode} • e.g. ${c.hint}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color:
                            isSelected ? AppColors.gold : AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                if (isSelected)
                  const Icon(
                    Icons.check_rounded,
                    color: AppColors.gold,
                    size: 18,
                  ),
              ],
            ),
          );
        }).toList(),
        child: Container(
          margin: const EdgeInsets.fromLTRB(8, 7, 8, 7),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.8),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CountryFlag(
                isoCode: _selectedCountry.isoCode,
                width: 26,
                height: 17,
              ),
              const SizedBox(width: 8),
              Text(
                _selectedCountry.dialCode,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_drop_down_rounded,
                color: AppColors.textMuted,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _errorText != null && _errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label.isNotEmpty) ...[
          Text(
            widget.label,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasError
                  ? AppColors.error
                  : (_isFocused ? AppColors.gold : AppColors.border),
              width: (_isFocused || hasError) ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Independent native popup flag & country selector
              _buildCountrySelector(),

              // Divider between Country Selector and Phone Input
              Container(
                width: 1,
                height: 22,
                color: AppColors.border.withValues(alpha: 0.8),
              ),

              // Phone number input
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _internalFocusNode,
                  keyboardType: TextInputType.phone,
                  textInputAction: widget.textInputAction,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    const _StripLeadingZeroFormatter(),
                    LengthLimitingTextInputFormatter(11),
                  ],
                  onChanged: (val) {
                    if (_errorText != null) {
                      setState(() => _errorText = null);
                    }
                    widget.onChanged?.call(val);
                  },
                  onFieldSubmitted: widget.onFieldSubmitted,
                  validator: (val) {
                    final err = widget.validator?.call(val);
                    if (err != _errorText) {
                      setState(() => _errorText = err);
                    }
                    return err;
                  },
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                  cursorColor: AppColors.gold,
                  decoration: InputDecoration(
                    hintText: widget.hintText ?? _selectedCountry.hint,
                    hintStyle: AppTextStyles.hint,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 16,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    errorStyle: const TextStyle(height: 0, fontSize: 0),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              _errorText!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Selector rendering either UK or Pakistan vector flag
class CountryFlag extends StatelessWidget {
  final String isoCode;
  final double width;
  final double height;

  const CountryFlag({
    super.key,
    required this.isoCode,
    this.width = 26,
    this.height = 17,
  });

  @override
  Widget build(BuildContext context) {
    if (isoCode == 'PK') {
      return PkFlag(width: width, height: height);
    }
    return UkFlag(width: width, height: height);
  }
}

/// Pixel-perfect vector Union Jack flag (United Kingdom).
class UkFlag extends StatelessWidget {
  final double width;
  final double height;

  const UkFlag({
    super.key,
    this.width = 26,
    this.height = 17,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: CustomPaint(
          size: Size(width, height),
          painter: const _UkFlagPainter(),
        ),
      ),
    );
  }
}

class _UkFlagPainter extends CustomPainter {
  const _UkFlagPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      const Radius.circular(3),
    ));

    // 1. Navy Blue Field (#012169)
    final bluePaint = Paint()..color = const Color(0xFF012169);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bluePaint);

    // 2. White Saltire (St Andrew's Cross)
    final whiteDiagonalPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = h * 0.32
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset.zero, Offset(w, h), whiteDiagonalPaint);
    canvas.drawLine(Offset(0, h), Offset(w, 0), whiteDiagonalPaint);

    // 3. Red Saltire (St Patrick's Cross)
    final redDiagonalPaint = Paint()
      ..color = const Color(0xFFC8102E)
      ..strokeWidth = h * 0.12
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset.zero, Offset(w, h), redDiagonalPaint);
    canvas.drawLine(Offset(0, h), Offset(w, 0), redDiagonalPaint);

    // 4. White Central Cross (St George's Cross border)
    final whiteCrossPaint = Paint()..color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(0, (h - h * 0.34) / 2, w, h * 0.34),
      whiteCrossPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH((w - w * 0.24) / 2, 0, w * 0.24, h),
      whiteCrossPaint,
    );

    // 5. Red Central Cross (St George's Cross)
    final redCrossPaint = Paint()..color = const Color(0xFFC8102E);
    canvas.drawRect(
      Rect.fromLTWH(0, (h - h * 0.20) / 2, w, h * 0.20),
      redCrossPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH((w - w * 0.14) / 2, 0, w * 0.14, h),
      redCrossPaint,
    );

    // 6. Subtle outer border hairline
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), borderPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Pixel-perfect vector Pakistan Flag (Crescent & Star in emerald field).
class PkFlag extends StatelessWidget {
  final double width;
  final double height;

  const PkFlag({
    super.key,
    this.width = 26,
    this.height = 17,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: CustomPaint(
          size: Size(width, height),
          painter: const _PkFlagPainter(),
        ),
      ),
    );
  }
}

class _PkFlagPainter extends CustomPainter {
  const _PkFlagPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      const Radius.circular(3),
    ));

    // 1. Dark green field (#01411C)
    final greenColor = const Color(0xFF01411C);
    final greenPaint = Paint()..color = greenColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), greenPaint);

    // 2. White vertical stripe on hoist (left 25%)
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, w * 0.25, h), whitePaint);

    // 3. Crescent and Star in green portion
    final double greenWidth = w * 0.75;
    final double cx = w * 0.25 + greenWidth * 0.46;
    final double cy = h * 0.52;

    // Draw crescent
    final double outerR = h * 0.28;
    canvas.drawCircle(Offset(cx, cy), outerR, whitePaint);
    final double innerR = h * 0.25;
    final double offsetX = outerR * 0.35;
    final double offsetY = -outerR * 0.32;
    canvas.drawCircle(Offset(cx + offsetX, cy + offsetY), innerR, greenPaint);

    // Draw 5-pointed star (10 points around perimeter)
    final double starCx = cx + outerR * 0.62;
    final double starCy = cy - outerR * 0.48;
    final double starR = h * 0.11;
    final double starInnerR = starR * 0.40;

    final path = Path();
    for (int i = 0; i < 10; i++) {
      final double r = (i % 2 == 0) ? starR : starInnerR;
      final double angle = -pi / 2 + (i * pi / 5);
      final double x = starCx + r * cos(angle);
      final double y = starCy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, whitePaint);

    // 4. Subtle outer hairline border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), borderPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Automatically strips leading zeroes if the user enters them (e.g. 0320 -> 320)
class _StripLeadingZeroFormatter extends TextInputFormatter {
  const _StripLeadingZeroFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.startsWith('0')) {
      final stripped = newValue.text.replaceFirst(RegExp(r'^0+'), '');
      final removed = newValue.text.length - stripped.length;
      final newOffset =
          (newValue.selection.baseOffset - removed).clamp(0, stripped.length);
      return TextEditingValue(
        text: stripped,
        selection: TextSelection.collapsed(offset: newOffset),
      );
    }
    return newValue;
  }
}


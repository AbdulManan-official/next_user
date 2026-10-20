import 'package:flutter/material.dart';

/// Device type classification based on shortest screen side.
enum DeviceType { mobile, tablet, desktop }

/// App-wide responsive design helper.
class ResponsiveHelper {
  ResponsiveHelper(this.context) : _mediaQuery = MediaQuery.of(context);

  final BuildContext context;
  final MediaQueryData _mediaQuery;

  // ---------------------------------------------------------------------
  // Base design reference (iPhone-ish base size)
  // ---------------------------------------------------------------------
  static const double _baseWidth = 375.0;
  static const double _baseHeight = 812.0;

  // ---------------------------------------------------------------------
  // Breakpoints (logical pixels, shortest side)
  // ---------------------------------------------------------------------
  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 1024;

  // ---------------------------------------------------------------------
  // Core MediaQuery values
  // ---------------------------------------------------------------------
  Size get screenSize => _mediaQuery.size;
  double get screenWidth => _mediaQuery.size.width;
  double get screenHeight => _mediaQuery.size.height;
  double get shortestSide => _mediaQuery.size.shortestSide;
  double get longestSide => _mediaQuery.size.longestSide;

  double get pixelRatio => _mediaQuery.devicePixelRatio;
  double get textScaleFactor => _mediaQuery.textScaler.scale(1.0);

  EdgeInsets get padding => _mediaQuery.padding;
  EdgeInsets get viewInsets => _mediaQuery.viewInsets;
  EdgeInsets get viewPadding => _mediaQuery.viewPadding;

  double get statusBarHeight => _mediaQuery.padding.top;
  double get bottomSafeAreaHeight => _mediaQuery.padding.bottom;
  double get keyboardHeight => _mediaQuery.viewInsets.bottom;
  bool get isKeyboardOpen => _mediaQuery.viewInsets.bottom > 0;

  Orientation get orientation => _mediaQuery.orientation;
  bool get isPortrait => orientation == Orientation.portrait;
  bool get isLandscape => orientation == Orientation.landscape;

  Brightness get platformBrightness => _mediaQuery.platformBrightness;
  bool get isDarkMode => platformBrightness == Brightness.dark;

  // ---------------------------------------------------------------------
  // Device type detection
  // ---------------------------------------------------------------------
  DeviceType get deviceType {
    if (shortestSide >= tabletMaxWidth) return DeviceType.desktop;
    if (shortestSide >= mobileMaxWidth) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  bool get isMobile => deviceType == DeviceType.mobile;
  bool get isTablet => deviceType == DeviceType.tablet;
  bool get isDesktop => deviceType == DeviceType.desktop;
  bool get isFoldableOrLargeMobile =>
      isMobile && shortestSide >= 400 && shortestSide < mobileMaxWidth;

  // ---------------------------------------------------------------------
  // Width / Height percentage helpers
  // ---------------------------------------------------------------------

  /// Width in percentage of screen width. e.g. wp(50) => 50% of width.
  double wp(double percent) => screenWidth * (percent / 100);

  /// Height in percentage of screen height. e.g. hp(50) => 50% of height.
  double hp(double percent) => screenHeight * (percent / 100);

  // ---------------------------------------------------------------------
  // Scaled sizing (relative to base design size, clamped)
  // ---------------------------------------------------------------------

  /// Scaled width dimension (controlled mobile scaling, clamped proportionally)
  double w(double designWidth) {
    if (isTablet || isDesktop) return designWidth;
    final scale = (screenWidth / _baseWidth).clamp(0.84, 1.15);
    return designWidth * scale;
  }

  /// Scaled height dimension (controlled mobile scaling, clamped proportionally)
  double h(double designHeight) {
    if (isTablet || isDesktop) return designHeight;
    final scale = (screenHeight / _baseHeight).clamp(0.84, 1.15);
    return designHeight * scale;
  }

  /// Scaled font size (sp) - keeps typography tokens razor sharp and balanced
  double sp(double fontSize) {
    if (isTablet) return fontSize * 1.12;
    if (isDesktop) return fontSize * 1.20;
    final scale = (screenWidth / _baseWidth).clamp(0.85, 1.12);
    return fontSize * scale;
  }

  /// Generic radius/spacing scaler (cards, icons, gaps)
  double r(double value) {
    if (isTablet || isDesktop) return value;
    final scale = (screenWidth / _baseWidth).clamp(0.85, 1.12);
    return value * scale;
  }

  // ---------------------------------------------------------------------
  // Responsive value picker
  // ---------------------------------------------------------------------
  T value<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    switch (deviceType) {
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.mobile:
        return mobile;
    }
  }

  int gridColumns({int mobile = 2, int tablet = 4, int desktop = 6}) {
    return value(mobile: mobile, tablet: tablet, desktop: desktop);
  }

  double get pagePadding => value(mobile: 16.0, tablet: 32.0, desktop: 64.0);
  double get maxContentWidth =>
      value(mobile: double.infinity, tablet: 720.0, desktop: 1100.0);
}

/// Convenient BuildContext extensions
extension ResponsiveContextExtension on BuildContext {
  ResponsiveHelper get responsive => ResponsiveHelper(this);

  double wp(double percent) => ResponsiveHelper(this).wp(percent);
  double hp(double percent) => ResponsiveHelper(this).hp(percent);
  double w(double designWidth) => ResponsiveHelper(this).w(designWidth);
  double h(double designHeight) => ResponsiveHelper(this).h(designHeight);
  double sp(double fontSize) => ResponsiveHelper(this).sp(fontSize);
  double r(double value) => ResponsiveHelper(this).r(value);

  bool get isMobile => ResponsiveHelper(this).isMobile;
  bool get isTablet => ResponsiveHelper(this).isTablet;
  bool get isDesktop => ResponsiveHelper(this).isDesktop;

  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  bool get isKeyboardOpen => MediaQuery.viewInsetsOf(this).bottom > 0;
}

/// Widget wrapper for responsive layout swaps
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;

  @override
  Widget build(BuildContext context) {
    final helper = ResponsiveHelper(context);
    switch (helper.deviceType) {
      case DeviceType.desktop:
        return (desktop ?? tablet ?? mobile)(context);
      case DeviceType.tablet:
        return (tablet ?? mobile)(context);
      case DeviceType.mobile:
        return mobile(context);
    }
  }
}

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

  /// Scales a width dimension relative to base design width.
  double w(double designWidth) {
    final scale = screenWidth / _baseWidth;
    return (designWidth * scale).clamp(designWidth * 0.75, designWidth * 1.6);
  }

  /// Scales a height dimension relative to base design height.
  double h(double designHeight) {
    final scale = screenHeight / _baseHeight;
    return (designHeight * scale).clamp(designHeight * 0.75, designHeight * 1.6);
  }

  /// Scaled font size (sp)
  double sp(double fontSize) {
    final scale = screenWidth / _baseWidth;
    final scaled = fontSize * scale.clamp(0.85, 1.3);
    return scaled.clamp(fontSize * 0.8, fontSize * 1.4);
  }

  /// Generic radius/spacing scaler (icons, radius, gaps).
  double r(double value) {
    final scale = screenWidth / _baseWidth;
    return (value * scale).clamp(value * 0.8, value * 1.5);
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

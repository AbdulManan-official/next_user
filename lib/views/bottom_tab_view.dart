import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../utils/app_theme_styles.dart';
import 'booking_flow_screen.dart';
import 'home_screen.dart';
import 'moves_screen.dart';
import 'profile_screen.dart';

class _NavItem {
  final FaIconData activeIcon;
  final FaIconData inactiveIcon;
  final String label;

  const _NavItem(this.activeIcon, this.inactiveIcon, this.label);
}

const List<_NavItem> _navItems = [
  _NavItem(FontAwesomeIcons.solidHouse, FontAwesomeIcons.house, 'Home'),
  _NavItem(FontAwesomeIcons.solidCalendarCheck,
      FontAwesomeIcons.calendarCheck, 'Book'),
  _NavItem(FontAwesomeIcons.truckFast, FontAwesomeIcons.truck, 'Moves'),
  _NavItem(FontAwesomeIcons.solidUser, FontAwesomeIcons.user, 'Profile'),
];

// ---------------------------------------------------------------------------
// Host scaffold.
// NO extendBody: Scaffold puts the body ABOVE the nav strip, so every screen
// gets a normal viewport and MediaQuery.padding.bottom stays 0 for them.
// The nav bar can never change a screen's layout or scroll extent.
// ---------------------------------------------------------------------------
class BottomTabView extends StatefulWidget {
  const BottomTabView({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<BottomTabView> createState() => _BottomTabViewState();
}

class _BottomTabViewState extends State<BottomTabView> {
  late int _currentIndex;
  late final List<bool> _visited;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _visited = List<bool>.filled(_navItems.length, false);
    _visited[_currentIndex] = true;
  }

  void _select(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
      _visited[index] = true;
    });
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.lightImpact();
    _select(index);
  }

  Widget _page(int index) {
    if (!_visited[index]) return const SizedBox.shrink();
    switch (index) {
      case 0:
        return HomeScreen(onSwitchToTab: _select);
      case 1:
        return BookingFlowScreen(onBackToHome: () => _select(0));
      case 2:
        return const MovesScreen();
      default:
        return const ProfileScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(0);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _currentIndex,
            children: List<Widget>.generate(_navItems.length, _page),
          ),
        ),
        bottomNavigationBar: _NavStrip(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Strip under the body: background + soft gold ambient light + glass bar.
// The light gives the glass something to frost, so it still looks like glass.
// ---------------------------------------------------------------------------
class _NavStrip extends StatelessWidget {
  const _NavStrip({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static final BoxDecoration _stripDecoration = BoxDecoration(
    color: AppColors.background,
    gradient: RadialGradient(
      center: const Alignment(0, 1.1),
      radius: 1.1,
      colors: [
        AppColors.gold.withValues(alpha: 0.12),
        AppColors.gold.withValues(alpha: 0.0),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _stripDecoration,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: _GlassBar(currentIndex: currentIndex, onTap: onTap),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Apple-style obsidian glass bar
// ---------------------------------------------------------------------------
class _GlassBar extends StatelessWidget {
  const _GlassBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const double _height = 68.0;
  static const double _radius = 36.0;
  static const double _capsuleWidth = 72.0;
  static const double _capsuleHeight = 50.0;

  static final BoxDecoration _shadow = BoxDecoration(
    borderRadius: BorderRadius.circular(_radius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.6),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: AppColors.goldDark.withValues(alpha: 0.18),
        blurRadius: 22,
        spreadRadius: -3,
        offset: const Offset(0, 3),
      ),
    ],
  );

  static final BoxDecoration _body = BoxDecoration(
    borderRadius: BorderRadius.circular(_radius),
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.surfaceElevated.withValues(alpha: 0.80),
        AppColors.surface.withValues(alpha: 0.86),
        AppColors.background.withValues(alpha: 0.92),
      ],
    ),
  );

  static final BoxDecoration _gloss = BoxDecoration(
    borderRadius: const BorderRadius.vertical(top: Radius.circular(_radius)),
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white.withValues(alpha: 0.08),
        Colors.white.withValues(alpha: 0.0),
      ],
    ),
  );

  static final BoxDecoration _streak = BoxDecoration(
    borderRadius: BorderRadius.circular(2),
    gradient: LinearGradient(
      colors: [
        Colors.transparent,
        AppColors.goldDark.withValues(alpha: 0.30),
        AppColors.gold.withValues(alpha: 0.85),
        Colors.white.withValues(alpha: 0.95),
        AppColors.goldLight.withValues(alpha: 0.95),
        AppColors.gold.withValues(alpha: 0.85),
        AppColors.goldDark.withValues(alpha: 0.30),
        Colors.transparent,
      ],
      stops: const [0.0, 0.16, 0.40, 0.50, 0.60, 0.84, 0.94, 1.0],
    ),
  );

  static final BoxDecoration _capsule = BoxDecoration(
    borderRadius: BorderRadius.circular(24),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.gold.withValues(alpha: 0.30),
        AppColors.goldDark.withValues(alpha: 0.12),
      ],
    ),
    border: Border.all(
      color: AppColors.goldLight.withValues(alpha: 0.55),
      width: 1.0,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.18),
        blurRadius: 2,
        offset: const Offset(0, -0.8),
      ),
      BoxShadow(
        color: AppColors.gold.withValues(alpha: 0.30),
        blurRadius: 14,
        spreadRadius: 1,
        offset: const Offset(0, 2),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final count = _navItems.length;
    final alignX = -1.0 + (2.0 * currentIndex / (count - 1));

    return RepaintBoundary(
      child: SizedBox(
        height: _height,
        child: DecoratedBox(
          decoration: _shadow,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_radius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
              child: DecoratedBox(
                decoration: _body,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: _height / 2,
                      child: IgnorePointer(
                        child: DecoratedBox(decoration: _gloss),
                      ),
                    ),
                    Positioned(
                      top: 1.2,
                      left: 30,
                      right: 30,
                      height: 2,
                      child: IgnorePointer(
                        child: DecoratedBox(decoration: _streak),
                      ),
                    ),
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment(alignX, 0),
                      child: FractionallySizedBox(
                        widthFactor: 1 / count,
                        child: Center(
                          child: IgnorePointer(
                            child: SizedBox(
                              width: _capsuleWidth,
                              height: _capsuleHeight,
                              child: DecoratedBox(decoration: _capsule),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Row(
                        children: List<Widget>.generate(count, (i) {
                          return Expanded(
                            child: _NavTab(
                              item: _navItems[i],
                              isSelected: currentIndex == i,
                              onTap: () => onTap(i),
                            ),
                          );
                        }),
                      ),
                    ),
                    const Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _RimPainter(radius: _radius),
                        ),
                      ),
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

class _NavTab extends StatefulWidget {
  const _NavTab({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_NavTab> createState() => _NavTabState();
}

class _NavTabState extends State<_NavTab> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.isSelected;

    return Semantics(
      button: true,
      selected: selected,
      label: widget.item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: Center(
          child: AnimatedScale(
            scale: _pressed ? 0.90 : (selected ? 1.05 : 0.97),
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 20,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    switchInCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.8, end: 1.0)
                            .animate(animation),
                        child: child,
                      ),
                    ),
                    child: selected
                        ? ShaderMask(
                            key: const ValueKey('active'),
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (rect) => LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [AppColors.goldLight, AppColors.gold],
                            ).createShader(rect),
                            child: FaIcon(
                              widget.item.activeIcon,
                              size: 18,
                              color: Colors.white,
                            ),
                          )
                        : FaIcon(
                            widget.item.inactiveIcon,
                            key: const ValueKey('inactive'),
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 10.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.goldLight : AppColors.textMuted,
                    letterSpacing: selected ? 0.5 : 0.2,
                  ),
                  child: Text(
                    widget.item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RimPainter extends CustomPainter {
  const _RimPainter({required this.radius});

  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(0.6);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.goldLight.withValues(alpha: 0.80),
          AppColors.gold.withValues(alpha: 0.32),
          AppColors.goldDark.withValues(alpha: 0.16),
          AppColors.gold.withValues(alpha: 0.38),
        ],
        stops: const [0.0, 0.35, 0.70, 1.0],
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _RimPainter old) => old.radius != radius;
}
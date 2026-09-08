import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Soft “icy” visual tokens for the home shell.
///
/// Cute = friendly and rounded, not stickers / neon / purple gradients.
abstract final class HomeUi {
  static const Color primary = Color(0xFF4BA3F0);
  static const Color primarySoft = Color(0xFFE8F3FC);
  static const Color sectionFill = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF2C3E50);
  static const Color inkMuted = Color(0xFF6B7C8F);
  static const Color runningFill = Color(0xFFE6F7F0);
  static const Color runningAccent = Color(0xFF3CB371);
  static const Color stoppedFill = Color(0xFFFDECEE);
  static const Color stoppedAccent = Color(0xFFE57373);
  static const Color chipFill = Color(0xFFEEF5FB);
  static const Color borderSoft = Color(0xFFE2EBF3);

  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;

  static TextStyle get sectionTitleStyle => const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: ink,
        letterSpacing: 0.1,
      );

  static TextStyle get bodyStyle => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: ink,
      );

  static TextStyle get captionStyle => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: inkMuted,
        height: 1.35,
      );

  static BorderRadius get sectionRadius => BorderRadius.circular(radiusMd);

  static BoxDecoration get sectionDecoration => BoxDecoration(
        color: sectionFill,
        borderRadius: sectionRadius,
        border: Border.all(color: borderSoft, width: 1),
      );

  static ButtonStyle softFilledButton({bool enabled = true}) {
    return FilledButton.styleFrom(
      elevation: 0,
      backgroundColor: enabled ? primary : primary.withValues(alpha: 0.35),
      foregroundColor: Colors.white,
      disabledBackgroundColor: primary.withValues(alpha: 0.25),
      disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
      ),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    );
  }

  static ButtonStyle softOutlinedButton() {
    return OutlinedButton.styleFrom(
      elevation: 0,
      foregroundColor: primary,
      side: const BorderSide(color: Color(0xFFB7D6F5)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
      ),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    );
  }
}

/// Layout form factor for the home shell (like CSS breakpoints).
enum HomeBreakpoint {
  /// Phone portrait / narrow windows — prefer stacked controls, full labels.
  narrow,

  /// Tablet landscape / desktop — denser horizontal arrangements OK.
  wide,
}

extension HomeBreakpointX on HomeBreakpoint {
  bool get isNarrow => this == HomeBreakpoint.narrow;
  bool get isWide => this == HomeBreakpoint.wide;

  static HomeBreakpoint fromSize(Size size) {
    // Width-based: rotation to landscape on phone can flip to wide.
    return size.width < 600 ? HomeBreakpoint.narrow : HomeBreakpoint.wide;
  }
}

/// Bounded vertical rhythm for the home page.
///
/// Tall phones get a bit more breathing room; short / wide windows stay compact.
/// Scale is capped so very tall screens do not balloon gaps.
class HomeLayoutMetrics {
  final HomeBreakpoint breakpoint;
  final double sectionGap;
  final double itemGap;
  final double sectionTitleGap;
  final double bottomBreathing;
  final EdgeInsets pagePadding;
  final EdgeInsets sectionPadding;

  /// 0 = compact, 1 = max allowed comfort (never exceeds this).
  final double scale;

  const HomeLayoutMetrics({
    required this.breakpoint,
    required this.sectionGap,
    required this.itemGap,
    required this.sectionTitleGap,
    required this.bottomBreathing,
    required this.pagePadding,
    required this.sectionPadding,
    required this.scale,
  });

  bool get isNarrow => breakpoint.isNarrow;
  bool get isWide => breakpoint.isWide;

  static const HomeLayoutMetrics compact = HomeLayoutMetrics(
    breakpoint: HomeBreakpoint.narrow,
    sectionGap: 14,
    itemGap: 8,
    sectionTitleGap: 10,
    bottomBreathing: 8,
    pagePadding: EdgeInsets.fromLTRB(16, 10, 16, 20),
    sectionPadding: EdgeInsets.fromLTRB(14, 12, 14, 12),
    scale: 0,
  );

  /// Resolve from the scaffold body viewport (after AppBar / safe area).
  factory HomeLayoutMetrics.resolve({
    required Size viewSize,
    required double bodyHeight,
  }) {
    final breakpoint = HomeBreakpointX.fromSize(viewSize);

    // Map body height → 0..1, then clamp. Extra height past the top of the
    // range does not increase spacing further.
    // Phone bodies are often ~650–800+; start easing earlier so mid-size
    // phones already get noticeably more air.
    const minH = 520.0;
    const maxH = 720.0;
    var t = ((bodyHeight - minH) / (maxH - minH)).clamp(0.0, 1.0);

    // Wide layouts already feel balanced — keep gaps closer to compact.
    if (breakpoint.isWide) {
      t *= 0.4;
    }

    double lerp(double a, double b) => lerpDouble(a, b, t)!;

    // Narrow (phone portrait): keep section gaps moderate so cards don't feel
    // sparse. Wide layouts keep the previous comfort curve unchanged.
    final sectionGapMax = breakpoint.isNarrow ? 22.0 : 36.0;
    final bottomMax = breakpoint.isNarrow ? 28.0 : 48.0;
    final pageTopMax = breakpoint.isNarrow ? 16.0 : 22.0;
    final pageBottomMax = breakpoint.isNarrow ? 28.0 : 40.0;
    final sectionPadMax = breakpoint.isNarrow ? 16.0 : 22.0;

    return HomeLayoutMetrics(
      breakpoint: breakpoint,
      sectionGap: lerp(16, sectionGapMax),
      itemGap: lerp(10, breakpoint.isNarrow ? 14.0 : 18.0),
      sectionTitleGap: lerp(12, breakpoint.isNarrow ? 14.0 : 18.0),
      bottomBreathing: lerp(16, bottomMax),
      pagePadding: EdgeInsets.fromLTRB(
        16,
        lerp(12, pageTopMax),
        16,
        lerp(24, pageBottomMax),
      ),
      sectionPadding: EdgeInsets.fromLTRB(
        14,
        lerp(14, sectionPadMax),
        14,
        lerp(14, sectionPadMax),
      ),
      scale: t,
    );
  }
}

/// Provides [HomeLayoutMetrics] to the home subtree.
class HomeLayoutScope extends InheritedWidget {
  final HomeLayoutMetrics metrics;

  const HomeLayoutScope({
    super.key,
    required this.metrics,
    required super.child,
  });

  static HomeLayoutMetrics of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<HomeLayoutScope>();
    return scope?.metrics ?? HomeLayoutMetrics.compact;
  }

  @override
  bool updateShouldNotify(HomeLayoutScope oldWidget) {
    return oldWidget.metrics.scale != metrics.scale ||
        oldWidget.metrics.sectionGap != metrics.sectionGap ||
        oldWidget.metrics.breakpoint != metrics.breakpoint;
  }
}

/// Soft rounded section with a light title row.
class HomeSection extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const HomeSection({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = HomeLayoutScope.of(context);
    return Container(
      width: double.infinity,
      padding: padding ?? metrics.sectionPadding,
      decoration: HomeUi.sectionDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: HomeUi.primary),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(title, style: HomeUi.sectionTitleStyle),
              ),
            ],
          ),
          SizedBox(height: metrics.sectionTitleGap),
          child,
        ],
      ),
    );
  }
}

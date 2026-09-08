import 'package:flutter/material.dart';

import '../home_ui.dart';

/// Visual chrome for [ExpandableSplitControl]'s primary row.
enum ExpandableSplitStyle {
  /// White fill + soft blue border (file pick, target IP).
  outlined,

  /// Primary-filled CTA (send).
  filled,
}

/// Shared “primary row + chevron → animated details below” shell used by
/// file pick, target endpoint, and send / QR actions.
class ExpandableSplitControl extends StatefulWidget {
  static const Color borderColor = Color(0xFFB7D6F5);
  static const Duration expandDuration = Duration(milliseconds: 220);
  static const double chevronColumnWidth = 48;
  static const double dividerWidth = 1;

  /// Width of the invisible trailing band so expanded labels align with the
  /// primary action (divider + chevron).
  static double get trailingReserveWidth =>
      dividerWidth + chevronColumnWidth;

  /// Left-side content of the primary row (placed in [Expanded]).
  final Widget primary;

  /// Content revealed under the primary row when expanded.
  final Widget expanded;

  final bool chevronEnabled;
  final ExpandableSplitStyle style;

  /// For [ExpandableSplitStyle.filled]: full primary vs muted bar fill.
  final bool filledActive;

  final double radius;
  final double expandedTopGap;
  final bool initiallyExpanded;
  final double? primaryMinHeight;

  const ExpandableSplitControl({
    super.key,
    required this.primary,
    required this.expanded,
    this.chevronEnabled = true,
    this.style = ExpandableSplitStyle.outlined,
    this.filledActive = true,
    this.radius = HomeUi.radiusMd,
    this.expandedTopGap = 8,
    this.initiallyExpanded = false,
    this.primaryMinHeight,
  });

  /// Soft bordered panel used for expanded rows / fields.
  static Widget panel({
    required Widget child,
    double radius = HomeUi.radiusMd,
    bool reserveChevronSpace = false,
  }) {
    final r = BorderRadius.circular(radius);
    final body = reserveChevronSpace
        ? IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: child),
                SizedBox(width: trailingReserveWidth),
              ],
            ),
          )
        : child;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: r,
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(borderRadius: r, child: body),
    );
  }

  /// Borderless [InputDecoration] for fields sitting inside [panel].
  static InputDecoration fieldDecoration({
    required String labelText,
    required String hintText,
    String? errorText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      errorText: errorText,
      errorMaxLines: 10,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.transparent,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  /// Icon + label text button used inside outlined split rows.
  static Widget outlinedAction({
    required VoidCallback? onPressed,
    required Widget icon,
    required String label,
    required bool enabled,
    Color color = HomeUi.primary,
  }) {
    final fg = enabled ? color : color.withValues(alpha: 0.4);
    return TextButton.icon(
      onPressed: onPressed,
      icon: IconTheme.merge(
        data: IconThemeData(color: fg, size: 18),
        child: icon,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: const RoundedRectangleBorder(),
        foregroundColor: color,
      ),
    );
  }

  @override
  State<ExpandableSplitControl> createState() =>
      _ExpandableSplitControlState();
}

class _ExpandableSplitControlState extends State<ExpandableSplitControl>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late final AnimationController _chevronController;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _chevronController = AnimationController(
      vsync: this,
      duration: ExpandableSplitControl.expandDuration,
      value: _expanded ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _chevronController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _chevronController.forward();
      } else {
        _chevronController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.radius);
    final chevronEnabled = widget.chevronEnabled;
    final filled = widget.style == ExpandableSplitStyle.filled;

    final Color headerColor;
    final Color dividerColor;
    final Color chevronColor;
    final BoxBorder? border;

    if (filled) {
      headerColor = widget.filledActive
          ? HomeUi.primary
          : HomeUi.primary.withValues(alpha: 0.28);
      dividerColor = Colors.white.withValues(alpha: 0.35);
      chevronColor = chevronEnabled
          ? Colors.white
          : Colors.white.withValues(alpha: 0.55);
      border = null;
    } else {
      headerColor = Colors.white;
      dividerColor = ExpandableSplitControl.borderColor;
      chevronColor = chevronEnabled
          ? HomeUi.primary
          : HomeUi.primary.withValues(alpha: 0.4);
      border = Border.all(color: ExpandableSplitControl.borderColor);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: headerColor,
            borderRadius: radius,
            border: border,
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: widget.primary),
                  VerticalDivider(
                    width: ExpandableSplitControl.dividerWidth,
                    thickness: 1,
                    color: dividerColor,
                  ),
                  SizedBox(
                    width: ExpandableSplitControl.chevronColumnWidth,
                    child: TextButton(
                      onPressed: chevronEnabled ? _toggle : null,
                      style: TextButton.styleFrom(
                        minimumSize: Size(
                          ExpandableSplitControl.chevronColumnWidth,
                          widget.primaryMinHeight ?? 0,
                        ),
                        padding: EdgeInsets.zero,
                        shape: const RoundedRectangleBorder(),
                        foregroundColor: chevronColor,
                      ),
                      child: RotationTransition(
                        turns: Tween<double>(begin: 0, end: 0.5).animate(
                          CurvedAnimation(
                            parent: _chevronController,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                        child: Icon(
                          Icons.expand_more_rounded,
                          color: chevronColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: ExpandableSplitControl.expandDuration,
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _expanded
              ? Padding(
                  padding: EdgeInsets.only(top: widget.expandedTopGap),
                  child: widget.expanded,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

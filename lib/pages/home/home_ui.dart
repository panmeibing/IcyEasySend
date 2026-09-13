import 'package:flutter/material.dart';

/// Soft "icy" visual tokens for the home shell.
///
/// Orbit home: cool grey page, white surfaces, one blue accent.
abstract final class HomeUi {
  static const Color primary = Color(0xFF4BA3F0);
  static const Color primaryDeep = Color(0xFF2B7FD4);
  static const Color primarySoft = Color(0xFFEBF4FD);
  static const Color pageBackground = Color(0xFFF0F5FA);
  static const Color ink = Color(0xFF22303E);
  static const Color inkMuted = Color(0xFF6E7F92);
  static const Color runningFill = Color(0xFFE6F7F0);
  static const Color runningAccent = Color(0xFF3CB371);
  static const Color stoppedFill = Color(0xFFFDECEE);
  static const Color stoppedAccent = Color(0xFFE57373);
  static const Color chipFill = Color(0xFFF2F7FC);
  static const Color fieldFill = Color(0xFFF5F9FC);
  static const Color borderSoft = Color(0xFFE3ECF4);

  static const double radiusMd = 16;
  static const double radiusLg = 20;

  static TextStyle get sectionTitleStyle => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: inkMuted,
        letterSpacing: 0.3,
      );

  static TextStyle get captionStyle => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: inkMuted,
        height: 1.35,
      );

  /// Shared field chrome for orbit sheets / forms.
  static InputDecoration fieldDecoration({
    required String hintText,
    String? errorText,
    Widget? suffix,
  }) {
    const radius = BorderRadius.all(Radius.circular(14));
    return InputDecoration(
      hintText: hintText,
      errorText: errorText,
      errorMaxLines: 4,
      filled: true,
      fillColor: fieldFill,
      suffixIcon: suffix,
      suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      border: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide.none,
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: primary, width: 1.2),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: stoppedAccent, width: 1),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: stoppedAccent, width: 1.2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

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
      side: const BorderSide(color: borderSoft),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
      ),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    );
  }

  /// Tonal button — tinted background, accent foreground, no border.
  static ButtonStyle softTonalButton() {
    return FilledButton.styleFrom(
      elevation: 0,
      backgroundColor: primarySoft,
      foregroundColor: primary,
      disabledBackgroundColor: primarySoft.withValues(alpha: 0.55),
      disabledForegroundColor: primary.withValues(alpha: 0.4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
      ),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    );
  }
}

import 'package:flutter/material.dart';

import '../home/home_ui.dart';

/// Phone theme enlarged for a couch: bigger type, taller buttons, a visible
/// focus ring. Leftover phone dialogs inherit this when the TV shell is up.
TextStyle? _scale(TextStyle? style) {
  final size = style?.fontSize;
  if (style == null || size == null) return style;
  return style.copyWith(fontSize: size * 1.2);
}

TextTheme _scaleTextTheme(TextTheme text) {
  return text.copyWith(
    displayLarge: _scale(text.displayLarge),
    displayMedium: _scale(text.displayMedium),
    displaySmall: _scale(text.displaySmall),
    headlineLarge: _scale(text.headlineLarge),
    headlineMedium: _scale(text.headlineMedium),
    headlineSmall: _scale(text.headlineSmall),
    titleLarge: _scale(text.titleLarge),
    titleMedium: _scale(text.titleMedium),
    titleSmall: _scale(text.titleSmall),
    bodyLarge: _scale(text.bodyLarge),
    bodyMedium: _scale(text.bodyMedium),
    bodySmall: _scale(text.bodySmall),
    labelLarge: _scale(text.labelLarge),
    labelMedium: _scale(text.labelMedium),
    labelSmall: _scale(text.labelSmall),
  );
}

ThemeData buildTvTheme(ThemeData phone) {
  final text = _scaleTextTheme(phone.textTheme);
  // Outlined controls use the same blue as the fill. On a filled button that
  // ring disappears, so focus uses a deeper sapphire and leaves the fill alone.
  const focusedSide = BorderSide(color: HomeUi.primary, width: 3);
  const focusedOnFill = BorderSide(color: Color(0xFF1B6EC2), width: 3);

  ButtonStyle focusStyle(ButtonStyle base, {bool onFill = false}) {
    return base.copyWith(
      minimumSize: const WidgetStatePropertyAll(Size(88, 52)),
      textStyle: WidgetStatePropertyAll(
        text.labelLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (onFill && states.contains(WidgetState.focused)) {
          return Colors.transparent;
        }
        return base.overlayColor?.resolve(states);
      }),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused)) {
          return onFill ? focusedOnFill : focusedSide;
        }
        return base.side?.resolve(states);
      }),
    );
  }

  return phone.copyWith(
    textTheme: text,
    visualDensity: VisualDensity.standard,
    dialogTheme: phone.dialogTheme.copyWith(
      insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: focusStyle(
        phone.filledButtonTheme.style ?? const ButtonStyle(),
        onFill: true,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: focusStyle(
        phone.outlinedButtonTheme.style ?? const ButtonStyle(),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: focusStyle(phone.textButtonTheme.style ?? const ButtonStyle()),
    ),
  );
}

import 'package:flutter/material.dart';

/// ホームだけに適用する配色。設定画面や保存済みの色は変更しない。
ThemeData homeTheme(ThemeData base, {required bool highContrast}) {
  highContrast = highContrast || base.colorScheme.primary == Colors.black;
  final dark = base.brightness == Brightness.dark;
  final scheme = highContrast
      ? base.colorScheme
      : base.colorScheme.copyWith(
          primary: dark ? const Color(0xFF71D6D7) : const Color(0xFF006D77),
          onPrimary: dark ? const Color(0xFF002F34) : Colors.white,
          primaryContainer:
              dark ? const Color(0xFF173B46) : const Color(0xFFE0F2FD),
          onPrimaryContainer:
              dark ? const Color(0xFFE0F2FD) : const Color(0xFF17242B),
          surface: dark ? const Color(0xFF142124) : const Color(0xFFFAFAF8),
          onSurface: dark ? const Color(0xFFEDF3F4) : const Color(0xFF17242B),
          outline: dark ? const Color(0xFF8A969A) : const Color(0xFF778187),
        );
  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: base.elevatedButtonTheme.style?.copyWith(
        elevation: const WidgetStatePropertyAll(0),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        side: WidgetStateProperty.resolveWith((states) => BorderSide(
              color: scheme.outline.withValues(
                  alpha: states.contains(WidgetState.disabled) ? 0.38 : 1),
              width: highContrast ? 2 : 1,
            )),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: scheme.surface,
      selectedColor: scheme.surface,
      side: BorderSide.none,
      shape: const RoundedRectangleBorder(),
      labelStyle: TextStyle(color: scheme.onSurface),
    ),
  );
}

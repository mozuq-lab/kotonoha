import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_colors.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';

/// ホームと各画面で共通の配色・輪郭。文字サイズとタップ領域は base を保つ。
ThemeData appVisualTheme(ThemeData base, {required bool highContrast}) {
  highContrast = highContrast || base.colorScheme.primary == Colors.black;
  final dark = base.brightness == Brightness.dark;
  final scheme = highContrast
      ? base.colorScheme.copyWith(
          secondary: Colors.black,
          onSecondary: Colors.white,
          secondaryContainer: Colors.black,
          onSecondaryContainer: Colors.white,
          surfaceContainerLow: Colors.white,
          surfaceContainerHighest: Colors.white,
          onSurfaceVariant: Colors.black,
          outlineVariant: Colors.black,
        )
      : base.colorScheme.copyWith(
          primary: dark ? AppColors.primaryDark : AppColors.primaryLight,
          onPrimary: dark ? AppColors.onPrimaryDark : AppColors.onPrimaryLight,
          primaryContainer:
              dark ? const Color(0xFF173B46) : const Color(0xFFE0F2FD),
          onPrimaryContainer:
              dark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
          secondary: dark ? AppColors.primaryDark : AppColors.primaryLight,
          onSecondary:
              dark ? AppColors.onPrimaryDark : AppColors.onPrimaryLight,
          secondaryContainer:
              dark ? const Color(0xFF173B46) : const Color(0xFFE6F2F0),
          onSecondaryContainer:
              dark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
          surface: dark ? AppColors.surfaceDark : AppColors.surfaceLight,
          onSurface: dark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
          surfaceContainerLow: dark ? const Color(0xFF192B2E) : Colors.white,
          surfaceContainerHighest:
              dark ? const Color(0xFF2A4146) : const Color(0xFFE6EEEE),
          onSurfaceVariant:
              dark ? const Color(0xFFC3CED0) : const Color(0xFF44545B),
          outline: dark ? const Color(0xFF8A969A) : const Color(0xFF778187),
          outlineVariant:
              dark ? const Color(0xFF51666A) : const Color(0xFFCBD5D7),
        );
  final border = BorderSide(
    color: scheme.outline,
    width: highContrast ? 2 : 1,
  );
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
    side: border,
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
    cardTheme: base.cardTheme.copyWith(
      color: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: shape,
      clipBehavior: Clip.antiAlias,
    ),
    dialogTheme: base.dialogTheme.copyWith(
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: shape,
    ),
    floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 0,
      shape: shape,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: base.elevatedButtonTheme.style?.copyWith(
        elevation: const WidgetStatePropertyAll(0),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        side: WidgetStateProperty.resolveWith((states) => border.copyWith(
              color: border.color.withValues(
                  alpha: states.contains(WidgetState.disabled) ? 0.38 : 1),
            )),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: scheme.surface,
      selectedColor: scheme.surface,
      checkmarkColor: scheme.onSurface,
      side: BorderSide.none,
      shape: const RoundedRectangleBorder(),
      labelStyle: TextStyle(color: scheme.onSurface),
    ),
  );
}

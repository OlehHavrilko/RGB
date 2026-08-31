import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Тёмная тема приложения на шрифте Manrope.
ThemeData buildAppTheme() {
  const scheme = ColorScheme.dark(
    primary: AppColors.accent,
    onPrimary: Colors.white,
    secondary: AppColors.accentSoft,
    surface: AppColors.bgElevated,
    onSurface: AppColors.textPrimary,
    error: AppColors.danger,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    fontFamily: 'Manrope',
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );

  return base.copyWith(
    textTheme: base.textTheme
        .apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        )
        .copyWith(
          displaySmall: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          headlineSmall: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          titleMedium: const TextStyle(fontWeight: FontWeight.w600),
          labelLarge: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          bodyMedium: const TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.bgElevated,
      contentTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontFamily: 'Manrope',
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

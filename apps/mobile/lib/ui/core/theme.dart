import 'package:flutter/material.dart';

import 'tokens.dart';

// Light only — design is ink on paper, no dark mode.
abstract final class AppTheme {
  static final light = ThemeData(
    useMaterial3: true,
    fontFamily: AppText.family,
    colorScheme: const ColorScheme.light(
      primary: AppColors.ink,
      onPrimary: AppColors.paper,
      secondary: AppColors.ink,
      onSecondary: AppColors.paper,
      surface: AppColors.paper,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.muted,
      surfaceContainerLowest: AppColors.paper,
      surfaceContainerLow: AppColors.mist,
      surfaceContainer: AppColors.mist,
      surfaceContainerHigh: AppColors.mist,
      surfaceContainerHighest: AppColors.track,
      outline: AppColors.line,
      outlineVariant: AppColors.divider,
      scrim: AppColors.ink,
      shadow: AppColors.ink,
      surfaceTint: Colors.transparent,
    ),
    scaffoldBackgroundColor: AppColors.paper,
    textTheme: const TextTheme(
      displayLarge: AppText.displayXl,
      displayMedium: AppText.displayL,
      displaySmall: AppText.display,
      headlineLarge: AppText.displayS,
      headlineMedium: AppText.title,
      headlineSmall: AppText.headline,
      titleLarge: AppText.sheetTitle,
      titleMedium: AppText.body,
      bodyLarge: AppText.body,
      bodyMedium: AppText.label,
      bodySmall: AppText.caption,
      labelLarge: AppText.label,
      labelMedium: AppText.caption,
      labelSmall: AppText.micro,
    ).apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
    splashFactory: NoSplash.splashFactory,
    highlightColor: AppColors.pressed,
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: AppStroke.hairline,
      space: AppStroke.hairline,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.paper,
      modalBackgroundColor: AppColors.paper,
      modalBarrierColor: AppColors.scrim,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      modalElevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
    ),
  );
}

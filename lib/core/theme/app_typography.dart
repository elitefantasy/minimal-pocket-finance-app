import 'package:akm_finance_manager/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Material 3 typography and convenient text-style accessors.
abstract final class AppTypography {
  static const _fontFamily = 'Roboto';

  static TextTheme get textTheme => Typography.material2021().black.apply(
    fontFamily: _fontFamily,
    bodyColor: AppColors.text,
    displayColor: AppColors.text,
  );

  static TextStyle get displayLarge => textTheme.displayLarge!;
  static TextStyle get displayMedium => textTheme.displayMedium!;
  static TextStyle get headlineLarge => textTheme.headlineLarge!;
  static TextStyle get headlineMedium => textTheme.headlineMedium!;
  static TextStyle get titleLarge => textTheme.titleLarge!;
  static TextStyle get titleMedium => textTheme.titleMedium!;
  static TextStyle get titleSmall => textTheme.titleSmall!;
  static TextStyle get bodyLarge => textTheme.bodyLarge!;
  static TextStyle get bodyMedium => textTheme.bodyMedium!;
  static TextStyle get bodySmall => textTheme.bodySmall!;
  static TextStyle get labelLarge => textTheme.labelLarge!;
  static TextStyle get labelMedium => textTheme.labelMedium!;
  static TextStyle get labelSmall => textTheme.labelSmall!;
}

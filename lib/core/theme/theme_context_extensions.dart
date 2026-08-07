import 'package:minimal_pocket_finance_app/core/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';

/// Concise access to the active Material theme and custom theme extensions.
extension AppThemeContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);

  ColorScheme get colors => theme.colorScheme;

  TextTheme get text => theme.textTheme;

  AppGradientTheme get gradients =>
      theme.extension<AppGradientTheme>() ?? AppGradientTheme.light;

  AppSemanticColors get semantic =>
      theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
}

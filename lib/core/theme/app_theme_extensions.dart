import 'package:akm_finance_manager/core/theme/app_colors.dart';
import 'package:akm_finance_manager/core/theme/app_gradients.dart';
import 'package:flutter/material.dart';

@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.warning,
    required this.info,
    required this.border,
    required this.divider,
    required this.disabled,
  });

  final Color success;
  final Color warning;
  final Color info;
  final Color border;
  final Color divider;
  final Color disabled;

  static const light = AppSemanticColors(
    success: AppColors.success,
    warning: AppColors.warning,
    info: AppColors.info,
    border: AppColors.border,
    divider: AppColors.divider,
    disabled: AppColors.disabled,
  );

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? warning,
    Color? info,
    Color? border,
    Color? divider,
    Color? disabled,
  }) => AppSemanticColors(
    success: success ?? this.success,
    warning: warning ?? this.warning,
    info: info ?? this.info,
    border: border ?? this.border,
    divider: divider ?? this.divider,
    disabled: disabled ?? this.disabled,
  );

  @override
  AppSemanticColors lerp(AppSemanticColors? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
    );
  }
}

@immutable
class AppGradientTheme extends ThemeExtension<AppGradientTheme> {
  const AppGradientTheme({
    required this.primary,
    required this.surface,
    required this.income,
    required this.expense,
    required this.success,
  });

  final Gradient primary;
  final Gradient surface;
  final Gradient income;
  final Gradient expense;
  final Gradient success;

  static const light = AppGradientTheme(
    primary: AppGradients.primary,
    surface: AppGradients.surface,
    income: AppGradients.income,
    expense: AppGradients.expense,
    success: AppGradients.success,
  );

  @override
  AppGradientTheme copyWith({
    Gradient? primary,
    Gradient? surface,
    Gradient? income,
    Gradient? expense,
    Gradient? success,
  }) => AppGradientTheme(
    primary: primary ?? this.primary,
    surface: surface ?? this.surface,
    income: income ?? this.income,
    expense: expense ?? this.expense,
    success: success ?? this.success,
  );

  @override
  AppGradientTheme lerp(AppGradientTheme? other, double t) => this;
}

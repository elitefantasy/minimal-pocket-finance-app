import 'package:minimal_pocket_finance_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Reusable gradients for decorative and semantic finance UI elements.
abstract final class AppGradients {
  static const primary = LinearGradient(
    colors: [AppColors.primary, AppColors.secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const surface = LinearGradient(
    colors: [AppColors.surface, AppColors.background],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const income = LinearGradient(
    colors: [Color(0xFF7DDBA4), Color(0xFF299B62)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const expense = LinearGradient(
    colors: [Color(0xFFF4A261), Color(0xFFE76F51)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const success = LinearGradient(
    colors: [Color(0xFFBDEBCF), Color(0xFF69C68C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

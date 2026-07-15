import 'package:akm_finance_manager/core/theme/app_colors.dart';
import 'package:akm_finance_manager/core/theme/app_radius.dart';
import 'package:akm_finance_manager/core/theme/app_sizes.dart';
import 'package:akm_finance_manager/core/theme/app_spacing.dart';
import 'package:akm_finance_manager/core/theme/app_theme_extensions.dart';
import 'package:akm_finance_manager/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Central Material 3 theme configuration for the application.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _buildLightTheme();

  /// Public API reserved for a future dark color palette.
  static ThemeData get darkTheme => _buildDarkTheme();

  static ThemeData _buildLightTheme() {
    const colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      tertiary: AppColors.accent,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      error: AppColors.error,
      onError: AppColors.onError,
      outline: AppColors.border,
      outlineVariant: AppColors.divider,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: AppTypography.textTheme,
      dividerColor: AppColors.divider,
      disabledColor: AppColors.disabled,
      extensions: const [AppSemanticColors.light, AppGradientTheme.light],
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: AppSizes.cardElevation,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size(0, AppSizes.fabSize),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          minimumSize: const Size(0, AppSizes.fabSize),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          side: const BorderSide(color: AppColors.border),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: AppSizes.cardElevation,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.text,
        contentTextStyle: TextStyle(color: AppColors.surface),
        actionTextColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        height: AppSizes.bottomNavigationHeight,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(color: AppColors.text),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.disabled,
        type: BottomNavigationBarType.fixed,
        elevation: AppSizes.cardElevation,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: AppSizes.cardElevation,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.extraLarge),
        constraints: BoxConstraints(maxWidth: AppSizes.dialogMaxWidth),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
      ),
      checkboxTheme: const CheckboxThemeData(
        fillColor: WidgetStatePropertyAll(AppColors.accent),
        checkColor: WidgetStatePropertyAll(AppColors.surface),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.small),
      ),
      switchTheme: const SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(AppColors.surface),
        trackColor: WidgetStatePropertyAll(AppColors.secondary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        disabledColor: AppColors.disabled,
        labelStyle: AppTypography.labelLarge,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        side: const BorderSide(color: AppColors.border),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pill),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: AppSpacing.lg,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        iconColor: AppColors.accent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
        linearTrackColor: AppColors.divider,
        circularTrackColor: AppColors.divider,
      ),
      tooltipTheme: const TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.text,
          borderRadius: AppRadius.small,
        ),
        textStyle: TextStyle(color: AppColors.surface),
      ),
      scrollbarTheme: const ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(AppColors.disabled),
        radius: Radius.circular(999),
        thickness: WidgetStatePropertyAll(AppSpacing.xs),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.accent,
        selectionColor: AppColors.primary,
        selectionHandleColor: AppColors.accent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.disabled),
        border: OutlineInputBorder(borderRadius: AppRadius.medium),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: BorderSide(color: AppColors.accent, width: 2),
        ),
      ),
    );
  }

  static ThemeData _buildDarkTheme() {
    // The public dark-theme API is ready; its palette will be introduced later.
    return _buildLightTheme();
  }
}

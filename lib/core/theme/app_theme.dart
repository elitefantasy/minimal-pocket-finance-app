import 'package:minimal_pocket_finance_app/core/theme/app_colors.dart';
import 'package:minimal_pocket_finance_app/core/theme/app_elevations.dart';
import 'package:minimal_pocket_finance_app/core/theme/app_radius.dart';
import 'package:minimal_pocket_finance_app/core/theme/app_sizes.dart';
import 'package:minimal_pocket_finance_app/core/theme/app_spacing.dart';
import 'package:minimal_pocket_finance_app/core/theme/app_theme_extensions.dart';
import 'package:minimal_pocket_finance_app/core/theme/app_typography.dart';
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
      dividerColor: colorScheme.outlineVariant,
      disabledColor: AppColors.disabled,
      extensions: const [AppSemanticColors.light, AppGradientTheme.light],
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: AppColors.background,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: AppElevations.card,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.large),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
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
          foregroundColor: colorScheme.tertiary,
          minimumSize: const Size(0, AppSizes.fabSize),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          side: BorderSide(color: colorScheme.outline),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.tertiary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: AppElevations.fab,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.large),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.onSurface,
        contentTextStyle: TextStyle(color: colorScheme.surface),
        actionTextColor: colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: AppSizes.bottomNavigationHeight,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primary,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(color: colorScheme.onSurface),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.tertiary,
        unselectedItemColor: AppColors.disabled,
        type: BottomNavigationBarType.fixed,
        elevation: AppElevations.none,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: AppRadius.extraLarge.topLeft,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: AppElevations.dialog,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.extraLarge),
        constraints: const BoxConstraints(maxWidth: AppSizes.dialogMaxWidth),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStatePropertyAll(colorScheme.tertiary),
        checkColor: WidgetStatePropertyAll(colorScheme.surface),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.small),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(colorScheme.surface),
        trackColor: WidgetStatePropertyAll(colorScheme.secondary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surface,
        selectedColor: colorScheme.primary,
        disabledColor: AppColors.disabled,
        labelStyle: AppTypography.labelLarge,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        side: BorderSide(color: colorScheme.outline),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pill),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: AppSpacing.lg,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        iconColor: colorScheme.tertiary,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.tertiary,
        linearTrackColor: colorScheme.outlineVariant,
        circularTrackColor: colorScheme.outlineVariant,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.onSurface,
          borderRadius: AppRadius.small,
        ),
        textStyle: TextStyle(color: colorScheme.surface),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(AppColors.disabled),
        radius: AppRadius.pill.topLeft,
        thickness: const WidgetStatePropertyAll(AppSpacing.xs),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colorScheme.tertiary,
        selectionColor: colorScheme.primary,
        selectionHandleColor: colorScheme.tertiary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.disabled),
        border: OutlineInputBorder(borderRadius: AppRadius.medium),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: BorderSide(color: colorScheme.tertiary, width: 2),
        ),
      ),
    );
  }

  static ThemeData _buildDarkTheme() {
    // This intentionally reuses the light theme until dark tokens are defined.
    // Replace this implementation with a dark ColorScheme and theme extensions
    // when dark mode is introduced; callers can already use [darkTheme].
    return _buildLightTheme();
  }
}

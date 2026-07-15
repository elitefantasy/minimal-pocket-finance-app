import 'package:akm_finance_manager/core/theme/app_sizes.dart';
import 'package:flutter/material.dart';

/// Canonical Material icons and icon sizes used by the application.
abstract final class AppIcons {
  static const dashboard = Icons.dashboard_outlined;
  static const history = Icons.history;
  static const income = Icons.arrow_downward_rounded;
  static const expense = Icons.arrow_upward_rounded;
  static const wallet = Icons.account_balance_wallet_outlined;
  static const statistics = Icons.bar_chart_rounded;
  static const category = Icons.category_outlined;
  static const calendar = Icons.calendar_today_outlined;
  static const repeat = Icons.repeat_rounded;
  static const database = Icons.storage_outlined;
  static const backup = Icons.backup_outlined;
  static const note = Icons.note_outlined;
  static const search = Icons.search;
  static const filter = Icons.filter_list_rounded;
  static const sort = Icons.sort_rounded;
  static const settings = Icons.settings_outlined;
  static const github = Icons.code_rounded;
  static const delete = Icons.delete_outline_rounded;
  static const edit = Icons.edit_outlined;

  static const double smallSize = AppSizes.iconSmall;
  static const double mediumSize = AppSizes.iconMedium;
  static const double largeSize = AppSizes.iconLarge;
}

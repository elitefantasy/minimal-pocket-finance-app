import 'package:shared_preferences/shared_preferences.dart';

/// Handles app preferences.
class PreferencesService {
  PreferencesService._();

  static final PreferencesService instance = PreferencesService._();

  static const String _exportDirectoryUriKey = 'export_directory_uri';
  static const String _selectedYearKey = 'selected_transaction_year';
  static const String _allYearsSelectedKey = 'all_transaction_years_selected';

  Future<int?> getSelectedYear() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getInt(_selectedYearKey);
  }

  Future<void> setSelectedYear(int? year) async {
    final preferences = await SharedPreferences.getInstance();
    if (year == null) {
      await preferences.remove(_selectedYearKey);
      await preferences.setBool(_allYearsSelectedKey, true);
      return;
    }
    await preferences.setInt(_selectedYearKey, year);
    await preferences.setBool(_allYearsSelectedKey, false);
  }

  Future<bool> isAllYearsSelected() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_allYearsSelectedKey) ?? false;
  }

  /// Save export folder URI.
  Future<void> setExportDirectoryUri(String uri) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(_exportDirectoryUriKey, uri);
  }

  /// Read export folder URI.
  Future<String?> getExportDirectoryUri() async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.getString(_exportDirectoryUriKey);
  }

  /// Remove saved export folder.
  Future<void> clearExportDirectoryUri() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_exportDirectoryUriKey);
  }
}

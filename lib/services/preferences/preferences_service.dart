import 'package:shared_preferences/shared_preferences.dart';

/// Handles app preferences.
class PreferencesService {
  PreferencesService._();

  static const String _exportDirectoryUriKey = 'export_directory_uri';

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

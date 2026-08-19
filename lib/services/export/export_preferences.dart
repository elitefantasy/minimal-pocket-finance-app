import 'package:shared_preferences/shared_preferences.dart';

class ExportPreferences {
  static const String _exportRootUriKey = 'export_root_uri';

  Future<String?> getExportRootUri() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_exportRootUriKey);
  }

  Future<bool> isCustomExportFolderSet() async {
    final uri = await getExportRootUri();
    return uri != null && uri.isNotEmpty;
  }

  Future<void> saveExportRootUri(String uri) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_exportRootUriKey, uri);
  }

  Future<void> clearExportRootUri() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_exportRootUriKey);
  }
}

import 'dart:io';

import 'package:saf_util/saf_util.dart';

import 'package:akm_finance_manager/services/export/export_preferences.dart';

class AndroidExportLocationService {
  // SAF helper
  final SafUtil _saf = SafUtil();
  AndroidExportLocationService({
    ExportPreferences? preferences,
  }) : _preferences = preferences ?? ExportPreferences();

  final ExportPreferences _preferences;

  /// Returns saved export folder URI.
  Future<String?> getSavedUri() {
    return _preferences.getExportRootUri();
  }

  /// Ask user to choose export folder.
  Future<String?> selectExportFolder() async {
    final directory = await _saf.pickDirectory(
      writePermission: true,
      persistablePermission: true,
    );

    if (directory == null) {
      return null;
    }

    final uri = directory.uri.toString();

    await _preferences.saveExportRootUri(uri);

    return uri;
  }

  /// Check saved permission.
  Future<bool> hasPermission() async {
    final uri = await getSavedUri();

    if (uri == null) {
      return false;
    }

    return _saf.hasPersistedPermission(uri, checkWrite: true);
  }

  /// Returns a valid export URI.
  Future<String?> getExportRootUri() async {
    final uri = await getSavedUri();

    if (uri != null &&
        await _saf.hasPersistedPermission(uri, checkWrite: true)) {
      return uri;
    }

    return selectExportFolder();
  }

  /// Forget selected folder.
  Future<void> clear() async {
    final uri = await getSavedUri();

    if (uri != null) {
      await _saf.releasePersistedPermission(uri, write: true);
    }

    await _preferences.clearExportRootUri();
  }
}
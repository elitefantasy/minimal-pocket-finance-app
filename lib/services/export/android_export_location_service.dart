import 'package:saf_util/saf_util.dart';

import 'package:minimal_pocket_finance_app/services/export/export_preferences.dart';

/// Service responsible for managing user-selected export directory via Android Storage Access Framework (SAF).
class AndroidExportLocationService {
  AndroidExportLocationService({
    SafUtil? safUtil,
    ExportPreferences? preferences,
  })  : _saf = safUtil ?? SafUtil(),
        _preferences = preferences ?? ExportPreferences();

  final SafUtil _saf;
  final ExportPreferences _preferences;

  /// Validates whether [uri] is a well-formed Android SAF content URI.
  bool _isValidSafUri(String? uri) {
    if (uri == null) return false;
    final trimmed = uri.trim();
    return trimmed.isNotEmpty && trimmed.startsWith('content://');
  }

  /// Returns saved export folder URI if valid.
  /// If the stored URI is corrupted or invalid (e.g. "/" or a POSIX file path),
  /// it is cleared from preferences to avoid plugin errors and returns null.
  Future<String?> getSavedUri() async {
    final uri = await _preferences.getExportRootUri();
    if (uri != null && !_isValidSafUri(uri)) {
      // Clean up invalid or corrupted URI from preferences.
      await _preferences.clearExportRootUri();
      return null;
    }
    return uri;
  }

  /// Asks user to choose an export folder using the native Android SAF directory picker.
  Future<String?> selectExportFolder() async {
    try {
      final directory = await _saf.pickDirectory(
        writePermission: true,
        persistablePermission: true,
      );

      if (directory == null) {
        return null;
      }

      final uri = directory.uri.toString();
      if (!_isValidSafUri(uri)) {
        return null;
      }

      await _preferences.saveExportRootUri(uri);
      return uri;
    } catch (_) {
      return null;
    }
  }

  /// Check whether the saved URI has active persisted write permission.
  Future<bool> hasPermission() async {
    final uri = await getSavedUri();
    if (uri == null) {
      return false;
    }

    try {
      return await _saf.hasPersistedPermission(uri, checkWrite: true);
    } catch (_) {
      return false;
    }
  }

  /// Returns the selected export folder URI.
  ///
  /// Reuses existing valid permission if present, otherwise prompts the user
  /// to select an export folder.
  Future<String?> getExportRootUri() async {
    final savedUri = await getSavedUri();

    if (savedUri != null) {
      try {
        final hasPermission = await _saf.hasPersistedPermission(
          savedUri,
          checkWrite: true,
        );

        if (hasPermission) {
          return savedUri;
        }
      } catch (_) {
        // Fall through to clear and re-select if checking fails.
      }

      // Permission was revoked or invalid.
      await _preferences.clearExportRootUri();
    }

    return selectExportFolder();
  }

  /// Forgets the selected folder and releases SAF persisted permission.
  Future<void> clear() async {
    final uri = await _preferences.getExportRootUri();

    if (uri != null && _isValidSafUri(uri)) {
      try {
        await _saf.releasePersistedPermission(uri, write: true);
      } catch (_) {}
    }

    await _preferences.clearExportRootUri();
  }
}

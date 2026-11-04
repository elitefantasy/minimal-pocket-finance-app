import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path_provider;

import 'package:minimal_pocket_finance_app/services/export/android_saf_export_service.dart';
import 'package:minimal_pocket_finance_app/services/export/export_preferences.dart';
import 'package:minimal_pocket_finance_app/models/export_result.dart';

/// Resolves the platform's public Downloads directory.
abstract class ExportDestinationResolver {
  const ExportDestinationResolver();

  Future<Directory> getDownloadsDirectory();
}

/// Resolves the download directory using path_provider.
class PathProviderExportDestinationResolver
    implements ExportDestinationResolver {
  const PathProviderExportDestinationResolver();

  @override
  Future<Directory> getDownloadsDirectory() async {
    if (!kIsWeb && Platform.isAndroid) {
      final external = await path_provider.getExternalStorageDirectory();
      if (external != null) {
        return external;
      }
    }

    final downloads = await path_provider.getDownloadsDirectory();
    if (downloads != null) {
      return downloads;
    }

    final fallback = await path_provider.getApplicationDocumentsDirectory();
    return fallback;
  }
}

/// Copies application artifacts into a managed folder under Downloads or custom export directory.
class ExportService {
  ExportService({
    ExportDestinationResolver? destinationResolver,
    AndroidSafExportService? androidSafExportService,
    ExportPreferences? preferences,
  }) : _destinationResolver =
           destinationResolver ?? const PathProviderExportDestinationResolver(),
       _androidSafExportService =
           androidSafExportService ?? AndroidSafExportService(),
       _preferences = preferences ?? ExportPreferences();

  final ExportDestinationResolver _destinationResolver;
  final AndroidSafExportService _androidSafExportService;
  final ExportPreferences _preferences;

  /// Returns the current active export directory path (custom if configured, otherwise default downloads).
  Future<String> getExportDirectoryPath() async {
    final customUri = await _preferences.getExportRootUri();

    // On Android, resolve SAF content URI to a human-readable display string.
    if (!kIsWeb && Platform.isAndroid) {
      if (customUri != null && customUri.startsWith('content://')) {
        final resolved = AndroidSafExportService.resolveDisplayPath(customUri);
        if (resolved != null && resolved.isNotEmpty) {
          return resolved;
        }
      }
      return 'Downloads';
    }

    // On Desktop, verify that custom folder exists.
    if (customUri != null && customUri.isNotEmpty) {
      final dir = Directory(customUri);
      if (await dir.exists()) {
        return customUri;
      }
    }
    final downloads = await _destinationResolver.getDownloadsDirectory();
    return downloads.path;
  }

  /// Returns whether a custom export folder is currently set and valid.
  Future<bool> isCustomExportFolder() async {
    final customUri = await _preferences.getExportRootUri();
    if (customUri == null || customUri.isEmpty) {
      return false;
    }

    if (!kIsWeb && Platform.isAndroid) {
      return customUri.startsWith('content://');
    }

    return true;
  }

  /// Sets a new custom export folder path.
  Future<void> setCustomExportFolder(String pathOrUri) async {
    await _preferences.saveExportRootUri(pathOrUri);
  }

  /// Prompts user to select a folder on Android via SAF and persists it.
  Future<String?> selectAndroidExportFolder() async {
    return _androidSafExportService.locationService.selectExportFolder();
  }

  /// Resets the export folder back to default downloads.
  Future<void> resetExportFolder() async {
    if (!kIsWeb && Platform.isAndroid) {
      await _androidSafExportService.locationService.clear();
    } else {
      await _preferences.clearExportRootUri();
    }
  }

  /// Moves existing export files (.db and .csv) from [sourcePath] to [targetPath].
  Future<void> moveExportFiles({
    required String sourcePath,
    required String targetPath,
  }) async {
    if (sourcePath.isEmpty || targetPath.isEmpty || sourcePath == targetPath) {
      return;
    }

    final sourceDir = Directory(sourcePath);
    final targetDir = Directory(targetPath);

    if (!await sourceDir.exists()) return;
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    await for (final entity in sourceDir.list()) {
      if (entity is File) {
        final name = path.basename(entity.path);
        if (name.endsWith('.db') || name.endsWith('.csv')) {
          final destFile = File(path.join(targetDir.path, name));
          await entity.copy(destFile.path);
          try {
            await entity.delete();
          } catch (_) {}
        }
      }
    }
  }

  /// Exports [sourcePath]. When [fileName] is supplied, uses it for the
  /// exported artifact instead of the source file's name.
  Future<ExportResult> exportFile({
    required String sourcePath,
    required String artifactFolder,
    String? fileName,
  }) async {
    final source = File(sourcePath);
    final exportedFileName = fileName ?? path.basename(sourcePath);

    if (!await source.exists()) {
      throw ExportException('The source file does not exist: $sourcePath');
    }

    try {
      // Android uses Storage Access Framework.
      if (!kIsWeb && Platform.isAndroid) {
        return await _androidSafExportService.exportFile(
          sourcePath: sourcePath,
          artifactFolder: artifactFolder,
          fileName: exportedFileName,
        );
      }

      // Desktop platforms.
      final exportDir = await getExportDirectoryPath();

      final destinationPath = path.join(
        exportDir,
        exportedFileName,
      );

      final destFile = File(destinationPath);
      if (await destFile.exists()) {
        throw ExportException('An export named $exportedFileName already exists.');
      }

      final exportedFile = await source.copy(destinationPath);

      // Desktop return
      return ExportResult(
        fileName: exportedFileName,
        relativePath: exportedFileName,
        absolutePath: exportedFile.absolute.path,
      );
    } on ExportException {
      rethrow;
    } on FileSystemException catch (error) {
      throw ExportException(
        'Unable to export ${path.basename(sourcePath)}.',
        cause: error,
      );
    }
  }
}

class ExportException implements Exception {
  const ExportException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() {
    final underlyingCause = cause;
    return underlyingCause == null
        ? 'ExportException: $message'
        : 'ExportException: $message ($underlyingCause)';
  }
}

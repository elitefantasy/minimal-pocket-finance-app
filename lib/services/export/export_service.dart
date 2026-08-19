import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path_provider;

import 'package:minimal_pocket_finance_app/services/export/android_saf_export_service.dart';
import 'package:minimal_pocket_finance_app/services/export/export_preferences.dart';
import 'package:minimal_pocket_finance_app/models/export_result.dart';

/// Resolves the platform's public Downloads directory.
///
/// This boundary can later be replaced by an Android SAF implementation
/// without changing repositories or presentation code.
abstract interface class ExportDestinationResolver {
  Future<Directory> getDownloadsDirectory();
}

class PathProviderExportDestinationResolver
    implements ExportDestinationResolver {
  const PathProviderExportDestinationResolver();

  @override
  Future<Directory> getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      final downloads = Directory('/storage/emulated/0/Download');

      if (await downloads.exists()) {
        return downloads;
      }

      throw const ExportException('Public Downloads folder not found.');
    }

    final directory = await path_provider.getDownloadsDirectory();

    if (directory == null) {
      throw const ExportException('Downloads directory not found.');
    }

    return directory;
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
    if (customUri != null && customUri.isNotEmpty) {
      final dir = Directory(customUri);
      if (await dir.exists()) {
        return customUri;
      }
    }
    final downloads = await _destinationResolver.getDownloadsDirectory();
    return downloads.path;
  }

  /// Returns whether a custom export folder is currently set.
  Future<bool> isCustomExportFolder() async {
    return _preferences.isCustomExportFolderSet();
  }

  /// Sets a new custom export folder path.
  Future<void> setCustomExportFolder(String pathOrUri) async {
    await _preferences.saveExportRootUri(pathOrUri);
  }

  /// Resets the export folder back to default downloads.
  Future<void> resetExportFolder() async {
    await _preferences.clearExportRootUri();
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
        return _androidSafExportService.exportFile(
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

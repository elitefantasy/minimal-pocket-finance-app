import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path_provider;

import 'package:minimal_pocket_finance_app/services/export/android_saf_export_service.dart';
import 'package:minimal_pocket_finance_app/core/constants/app_constants.dart';
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

/// Copies application artifacts into a managed folder under Downloads.
class ExportService {
  ExportService({
    ExportDestinationResolver? destinationResolver,
    AndroidSafExportService? androidSafExportService,
  }) : _destinationResolver =
           destinationResolver ?? const PathProviderExportDestinationResolver(),
       _androidSafExportService =
           androidSafExportService ?? AndroidSafExportService();

  static const String _applicationFolder = AppConstants.appName;

  final ExportDestinationResolver _destinationResolver;

  final AndroidSafExportService _androidSafExportService;

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
      final downloadsDirectory = await _destinationResolver
          .getDownloadsDirectory();

      final destinationDirectory = Directory(
        path.join(downloadsDirectory.path, _applicationFolder, artifactFolder),
      );

      await destinationDirectory.create(recursive: true);

      final destinationPath = path.join(
        destinationDirectory.path,
        exportedFileName,
      );

      if (await File(destinationPath).exists()) {
        throw ExportException('An export named $exportedFileName already exists.');
      }

      final exportedFile = await source.copy(destinationPath);

      // Desktop return
      return ExportResult(
        fileName: exportedFileName,
        relativePath:
            '${AppConstants.appName}/$artifactFolder/$exportedFileName',
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

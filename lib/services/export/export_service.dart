import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path_provider;

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

      throw const ExportException(
        'Public Downloads folder not found.',
      );
    }

    final directory = await path_provider.getDownloadsDirectory();

    if (directory == null) {
      throw const ExportException(
        'Downloads directory not found.',
      );
    }

    return directory;
  }
}

/// Copies application artifacts into a managed folder under Downloads.
class ExportService {
  ExportService({ExportDestinationResolver? destinationResolver})
    : _destinationResolver =
          destinationResolver ?? const PathProviderExportDestinationResolver();

  static const String _applicationFolder = 'AKM Finance Manager';

  final ExportDestinationResolver _destinationResolver;

  /// Exports [sourcePath] while preserving its original file name.
  Future<String> exportFile({
    required String sourcePath,
    required String artifactFolder,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw ExportException('The source file does not exist: $sourcePath');
    }

    try {
      final downloadsDirectory = await _destinationResolver
          .getDownloadsDirectory();
      final destinationDirectory = Directory(
        path.join(downloadsDirectory.path, _applicationFolder, artifactFolder),
      );
      await destinationDirectory.create(recursive: true);

      final destinationPath = path.join(
        destinationDirectory.path,
        path.basename(sourcePath),
      );
      final exportedFile = await source.copy(destinationPath);
      return exportedFile.absolute.path;
    } on ExportException {
      rethrow;
    } on FileSystemException catch (error) {
      throw ExportException(
        'Unable to export ${path.basename(sourcePath)} to Downloads.',
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

import 'dart:io';

import 'package:minimal_pocket_finance_app/services/export/android_export_location_service.dart';
import 'package:minimal_pocket_finance_app/services/export/export_service.dart';
import 'package:minimal_pocket_finance_app/models/export_result.dart';

import 'package:saf_stream/saf_stream.dart';

/// Handles exporting files through Android's Storage Access Framework (SAF).
///
/// Android 11+ (API 30+) requires Storage Access Framework permissions
/// to write files into user-selected storage locations.
class AndroidSafExportService {
  AndroidSafExportService({
    AndroidExportLocationService? locationService,
    SafStream? safStream,
  })  : _locationService = locationService ?? AndroidExportLocationService(),
        _safStream = safStream ?? SafStream();

  /// Responsible for asking the user to select an export folder.
  final AndroidExportLocationService _locationService;

  /// Exposes the underlying location service.
  AndroidExportLocationService get locationService => _locationService;

  /// Used to copy local files into SAF.
  final SafStream _safStream;

  /// Export a local file into the selected SAF folder.
  Future<ExportResult> exportFile({
    required String sourcePath,
    required String artifactFolder,
    required String fileName,
  }) async {
    // Make sure the source file exists.
    final sourceFile = File(sourcePath);

    if (!await sourceFile.exists()) {
      throw const ExportException('Source file not found.');
    }

    // Ask for or retrieve the valid export folder SAF URI.
    final rootUri = await _locationService.getExportRootUri();

    if (rootUri == null) {
      throw const ExportException('Export cancelled.');
    }

    try {
      await _safStream.pasteLocalFile(
        sourcePath,
        rootUri,
        fileName,
        'application/octet-stream',
        overwrite: false,
      );
    } on Object catch (error) {
      throw ExportException(
        'Failed to save export file to the selected destination.',
        cause: error,
      );
    }

    final absolutePath = resolveDisplayPath(rootUri, fileName);

    // Return exported filename.
    return ExportResult(
      fileName: fileName,
      relativePath: fileName,
      absolutePath: absolutePath,
    );
  }

  /// Converts an Android SAF Tree URI into a human-readable storage path.
  static String? resolveDisplayPath(String rootUri, [String? fileName]) {
    try {
      final decodedUri = Uri.decodeComponent(rootUri);

      String treePath = decodedUri;
      if (treePath.contains('/tree/')) {
        treePath = treePath.split('/tree/').last;
      } else if (treePath.contains('/document/')) {
        treePath = treePath.split('/document/').last;
      }

      if (treePath.contains('?')) {
        treePath = treePath.split('?').first;
      }

      String basePath = '';
      if (treePath.startsWith('primary:')) {
        final subPath = treePath.substring('primary:'.length);
        basePath = '/storage/emulated/0${subPath.isEmpty ? '' : '/$subPath'}';
      } else if (treePath.startsWith('raw:')) {
        basePath = treePath.substring('raw:'.length);
      } else if (RegExp(r'^[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}:').hasMatch(treePath)) {
        final parts = treePath.split(':');
        final volume = parts.first;
        final subPath = parts.sublist(1).join(':');
        basePath = '/storage/$volume${subPath.isEmpty ? '' : '/$subPath'}';
      } else {
        final colonIndex = treePath.indexOf(':');
        if (colonIndex != -1 && colonIndex < treePath.length - 1) {
          basePath = '/storage/emulated/0/${treePath.substring(colonIndex + 1)}';
        } else {
          basePath = treePath;
        }
      }

      if (fileName == null || fileName.isEmpty) {
        return basePath;
      }

      if (basePath.endsWith('/')) {
        return '$basePath$fileName';
      } else {
        return '$basePath/$fileName';
      }
    } catch (_) {
      return fileName != null ? '$rootUri/$fileName' : rootUri;
    }
  }
}

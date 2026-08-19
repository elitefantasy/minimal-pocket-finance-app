import 'dart:io';

import 'package:minimal_pocket_finance_app/services/export/android_export_location_service.dart';
import 'package:minimal_pocket_finance_app/models/export_result.dart';

import 'package:saf_stream/saf_stream.dart';

/// Handles exporting files through Android's Storage Access Framework (SAF).
///
/// Why do we need this?
///
/// Android 11+ does not allow apps to freely write into public folders
/// like Download using normal File.copy().
///
/// Instead, the user grants access to a folder using SAF.
/// After that we can safely create folders and write files there.
class AndroidSafExportService {
  AndroidSafExportService({
    AndroidExportLocationService? locationService,
    SafStream? safStream,
  }) : _locationService = locationService ?? AndroidExportLocationService(),
       _safStream = safStream ?? SafStream();

  /// Responsible for asking the user to select an export folder.
  final AndroidExportLocationService _locationService;

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
      throw Exception('Source file not found.');
    }

    // Ask for the export folder if needed.
    final rootUri = await _locationService.getExportRootUri();

    if (rootUri == null) {
      throw Exception('Export cancelled.');
    }

    // Create:
    //
    // Minimal Pocket Finance/
    //     Database/
    //
    await _safStream.pasteLocalFile(
      sourcePath,
      rootUri,
      fileName,
      'application/octet-stream',
      overwrite: false,
    );

    final absolutePath = _resolveAbsolutePath(
      rootUri: rootUri,
      fileName: fileName,
    );

    // Return exported filename.
    return ExportResult(
      fileName: fileName,
      relativePath: fileName,
      absolutePath: absolutePath,
    );
  }

  String? _resolveAbsolutePath({
    required String rootUri,
    required String fileName,
  }) {
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

      if (basePath.endsWith('/')) {
        return '$basePath$fileName';
      } else {
        return '$basePath/$fileName';
      }
    } catch (_) {
      return null;
    }
  }
}

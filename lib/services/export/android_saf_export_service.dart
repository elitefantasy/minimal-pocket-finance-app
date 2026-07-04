import 'dart:io';

import 'package:akm_finance_manager/services/export/android_export_location_service.dart';
import 'package:akm_finance_manager/core/constants/app_constants.dart';


import 'package:path/path.dart' as path;
import 'package:saf_stream/saf_stream.dart';
import 'package:saf_util/saf_util.dart';

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
    SafUtil? safUtil,
    SafStream? safStream,
  }) : _locationService =
            locationService ?? AndroidExportLocationService(),
       _safUtil = safUtil ?? SafUtil(),
       _safStream = safStream ?? SafStream();

  /// Responsible for asking the user to select an export folder.
  final AndroidExportLocationService _locationService;

  /// Utility methods for SAF directory operations.
  final SafUtil _safUtil;

  /// Used to copy local files into SAF.
  final SafStream _safStream;

  /// Export a local file into the selected SAF folder.
  Future<String> exportFile({
    required String sourcePath,
    required String artifactFolder,
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
    // AKM Finance Manager/
    //     Database/
    //
    final destinationFolder = await _safUtil.mkdirp(
      rootUri,
      <String>[
        AppConstants.appName,
        artifactFolder,
      ],
    );

    await _safStream.pasteLocalFile(
      sourcePath,
      destinationFolder.uri,
      path.basename(sourcePath),
      'application/octet-stream',
      overwrite: true,
    );

    // Return exported filename.
    return path.basename(sourcePath);
  }
}
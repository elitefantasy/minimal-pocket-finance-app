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

  /// Exports a file into:
  ///
  /// AKM Finance Manager/
  ///     Database/
  ///         finance.db
  Future<String> exportFile({
    required String sourcePath,
    required String artifactFolder,
  }) async {
    // Make sure the source file actually exists.
    final sourceFile = File(sourcePath);

    if (!await sourceFile.exists()) {
      throw Exception('Source file not found.');
    }

    // Get (or ask for) the export folder.
    final rootUri = await _locationService.getExportRootUri();

    if (rootUri == null) {
      throw Exception('Export cancelled.');
    }

    // Create:
    // AKM Finance Manager/
    //     Database/

    final destinationFolder = await _safUtil.mkdirp(
      rootUri,
      <String>[
        AppConstants.appName,
        artifactFolder,
      ],
    );

    // URI of the final folder
    final destinationFolderUri = destinationFolder.uri;

    // Copy the file into SAF.
    await _safStream.pasteLocalFile(
      sourcePath,
      destinationFolderUri,
      path.basename(sourcePath),
      'application/x-sqlite3',
      overwrite: true,
    );

    // Return only the exported filename.
    return path.basename(sourcePath);
  }
}
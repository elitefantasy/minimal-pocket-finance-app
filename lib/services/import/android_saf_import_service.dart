import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:saf_stream/saf_stream.dart';
import 'package:saf_util/saf_util.dart';

import 'package:akm_finance_manager/models/import_selection.dart';

/// Imports a SQLite database through Android's
/// Storage Access Framework (SAF).
///
/// Responsibility:
/// - Open Android file picker.
/// - Copy selected database into a temporary local file.
/// - Return the temporary file path.
///
/// Validation and database replacement are handled
/// by DatabaseManagementRepository.
class AndroidSafImportService {
  AndroidSafImportService({SafUtil? safUtil, SafStream? safStream})
    : _safUtil = safUtil ?? SafUtil(),
      _safStream = safStream ?? SafStream();

  final SafUtil _safUtil;
  final SafStream _safStream;

  Future<ImportSelection?> pickDatabase() async {
    // Let the user choose a SQLite database.
    final file = await _safUtil.pickFile(
      mimeTypes: const <String>[
        'application/octet-stream',
        'application/x-sqlite3',
      ],
    );

    // User cancelled.
    if (file == null) {
      return null;
    }

    // Temporary directory inside the app.
    final tempDirectory = await getTemporaryDirectory();

    // Preserve the original filename when possible.
    final fileName = file.name.isEmpty ? 'import.db' : file.name;

    final localPath = path.join(tempDirectory.path, fileName);

    // Remove any previous temporary copy.
    final localFile = File(localPath);

    if (await localFile.exists()) {
      await localFile.delete();
    }

    // Copy the selected SAF file into app storage.
    await _safStream.copyToLocalFile(file.uri, localPath);

    return ImportSelection(localPath: localPath, databaseName: fileName);
  }
}

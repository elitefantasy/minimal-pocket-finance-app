import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:saf_stream/saf_stream.dart';
import 'package:saf_util/saf_util.dart';

import 'package:akm_finance_manager/models/import_selection.dart';

/// Imports a SQLite database through Android's Storage Access Framework (SAF)
/// or Desktop's native FilePicker.
class AndroidSafImportService {
  AndroidSafImportService({SafUtil? safUtil, SafStream? safStream})
    : _safUtil = safUtil ?? SafUtil(),
      _safStream = safStream ?? SafStream();

  final SafUtil _safUtil;
  final SafStream _safStream;

  Future<ImportSelection?> pickDatabase() async {
    if (!kIsWeb && Platform.isAndroid) {
      // Android Storage Access Framework (SAF)
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
      final fileName = file.name.isEmpty ? 'import.db' : file.name;
      final localPath = path.join(tempDirectory.path, fileName);
      final localFile = File(localPath);

      if (await localFile.exists()) {
        await localFile.delete();
      }

      // Copy the selected SAF file into app storage.
      await _safStream.copyToLocalFile(file.uri, localPath);
      return ImportSelection(localPath: localPath, databaseName: fileName);
    } else {
      // Windows / Desktop / Non-Android File Picker
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const <String>['db', 'sqlite', 'sqlite3'],
      );

      if (result == null ||
          result.files.isEmpty ||
          result.files.single.path == null) {
        return null;
      }

      final pickedFilePath = result.files.single.path!;
      final fileName = path.basename(pickedFilePath);
      final tempDirectory = await getTemporaryDirectory();
      final localPath = path.join(tempDirectory.path, fileName);
      final localFile = File(localPath);

      if (await localFile.exists()) {
        await localFile.delete();
      }

      await File(pickedFilePath).copy(localPath);
      return ImportSelection(localPath: localPath, databaseName: fileName);
    }
  }
}

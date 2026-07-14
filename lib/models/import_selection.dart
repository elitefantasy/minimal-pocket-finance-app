/// Represents a database selected through Android's
/// Storage Access Framework (SAF).
///
/// The import service is responsible only for selecting
/// and copying the file into temporary storage.
/// It should not decide how the repository uses it.
class ImportSelection {
  const ImportSelection({required this.localPath, required this.databaseName});

  /// Temporary local file path.
  final String localPath;

  /// Original database filename.
  ///
  /// Example:
  /// finance.db
  final String databaseName;
}

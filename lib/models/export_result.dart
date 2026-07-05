/// Information about a completed export.
///
/// Keeping export results in a dedicated model makes it easy
/// to extend in the future without changing every method
/// signature.
class ExportResult {
  const ExportResult({
    required this.fileName,
    required this.relativePath,
    this.absolutePath,
  });

  /// Name of the exported file.
  final String fileName;

  /// User-friendly location.
  ///
  /// Example:
  /// AKM Finance Manager/Database/finance.db
  final String relativePath;

  /// Physical path if available.
  ///
  /// Desktop:
  ///     C:\Users\Anil\Downloads\...
  ///
  /// Android SAF:
  ///     null
  final String? absolutePath;
}
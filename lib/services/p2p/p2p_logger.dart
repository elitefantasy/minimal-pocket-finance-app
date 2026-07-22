import 'dart:developer' as developer;
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Centralized file and console logger for P2P debugging across platforms.
class P2PLogger {
  static File? _logFile;
  static bool _initialized = false;

  /// Initializes the persistent log file in app documents directory.
  static Future<void> init() async {
    if (_initialized) return;
    try {
      final docs = await getApplicationDocumentsDirectory();
      _logFile = File(path.join(docs.path, 'p2p_debug.log'));
      _initialized = true;
      await log('=== P2P Session Log Initialized ===');
    } catch (e) {
      developer.log('P2PLogger init error: $e', name: 'P2P.Logger');
    }
  }

  /// Appends a formatted timestamped message to both console output and log file.
  static Future<void> log(String message) async {
    final now = DateTime.now();
    final timestamp =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}';
    final line = '[$timestamp] $message';

    // Print to standard console stdout for flutter run
    // ignore: avoid_print
    print(line);

    // Send to Dart DevTools
    developer.log(message, name: 'P2P');

    // Append to file on disk for Windows GUI / Android offline inspection
    try {
      if (_logFile != null) {
        await _logFile!.writeAsString('$line\n', mode: FileMode.append, flush: true);
      }
    } catch (_) {}
  }

  /// Reads and returns the complete log content from disk.
  static Future<String> getLogContent() async {
    try {
      if (_logFile != null && await _logFile!.exists()) {
        return await _logFile!.readAsString();
      }
    } catch (_) {}
    return 'No log file found.';
  }

  /// Returns the absolute path of the log file on disk.
  static Future<String?> getLogFilePath() async {
    try {
      if (_logFile != null) return _logFile!.path;
    } catch (_) {}
    return null;
  }
}

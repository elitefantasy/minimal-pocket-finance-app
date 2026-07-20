import 'dart:io' show Platform;

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Configures sqflite to use SQLite FFI on desktop platforms.
///
/// This function is called once from `main()` before any providers are created.
/// Android continues to use sqflite's platform implementation unchanged.
Future<void> initializeDatabase() async {
  if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
    return;
  }

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

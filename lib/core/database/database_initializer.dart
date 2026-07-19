import 'database_initializer_stub.dart'
    if (dart.library.io) 'database_initializer_io.dart' as implementation;

/// Initializes the database implementation required by the current platform.
///
/// The IO implementation configures SQLite FFI on desktop platforms. On web,
/// this is intentionally a no-op so this bootstrap API remains web-safe.
Future<void> initializeDatabase() => implementation.initializeDatabase();

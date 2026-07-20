/// Web-safe fallback for the database bootstrap.
///
/// A web database implementation can replace this later without changing the
/// application startup sequence.
Future<void> initializeDatabase() async {}

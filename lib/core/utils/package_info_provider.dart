import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Provides information about the installed application.
///
/// Uses the values from pubspec.yaml and the platform build files,
/// so the version never needs to be maintained manually.
final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return PackageInfo.fromPlatform();
});

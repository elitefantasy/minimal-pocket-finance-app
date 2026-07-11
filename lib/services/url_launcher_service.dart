import 'package:url_launcher/url_launcher.dart';

/// Opens external links using the platform's default application.
class UrlLauncherService {
  const UrlLauncherService();

  Future<bool> openUrl(String url) async {
    try {
      return await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }
}
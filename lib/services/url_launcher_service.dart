import 'package:url_launcher/url_launcher.dart';

/// Opens external links using the platform's default application.
class UrlLauncherService {
  const UrlLauncherService();

  /// Opens a website in the user's default browser.
  ///
  /// Returns true if the URL was launched successfully.
  Future<bool> openUrl(String url) async {
    final uri = Uri.parse(url);

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
}
import '../config/app_config.dart';

/// Routing logic that determines whether a URL should stay inside
/// the WebView or be opened externally.
class WebViewService {
  WebViewService._();

  /// Returns true if [url] belongs to the tracker domain and should
  /// be handled by the WebView. Returns false for all external URLs.
  static bool isInternalUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    // Matches fl501st.com and any subdomain (e.g. www.fl501st.com)
    return uri.host.endsWith(AppConfig.trackerDomain);
  }
}

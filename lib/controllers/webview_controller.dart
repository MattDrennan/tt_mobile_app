import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../config/app_config.dart';
import '../services/url_launcher_service.dart';
import '../services/webview_service.dart';

/// Manages WebView state and exposes it to the UI via ChangeNotifier.
///
/// Ownership: Created and disposed by MainShellView. Passed as a
/// constructor parameter to TrackerView and SettingsView.
class WebviewController extends ChangeNotifier {
  late final WebViewController _webViewController;

  bool _isLoading = true;
  double _loadingProgress = 0.0;
  bool _hasError = false;
  String _errorMessage = '';

  bool get isLoading => _isLoading;
  double get loadingProgress => _loadingProgress;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;

  /// The underlying webview_flutter controller used by WebViewWidget.
  WebViewController get webViewController => _webViewController;

  /// Sets up the WebViewController and loads the tracker URL.
  /// Must be called once by MainShellView.initState().
  void initialize() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppConfig.splashBackgroundColor)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: _onPageStarted,
          onPageFinished: _onPageFinished,
          onProgress: _onProgress,
          onWebResourceError: _onWebResourceError,
          onNavigationRequest: _onNavigationRequest,
        ),
      )
      ..loadRequest(Uri.parse(AppConfig.trackerUrl));
  }

  void _onPageStarted(String url) {
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();
  }

  void _onPageFinished(String url) {
    _isLoading = false;
    notifyListeners();
  }

  void _onProgress(int progress) {
    _loadingProgress = progress / 100.0;
    notifyListeners();
  }

  void _onWebResourceError(WebResourceError error) {
    // Only treat main-frame errors as fatal — sub-resource failures
    // (ads, tracking pixels) should not interrupt the user experience.
    if (error.isForMainFrame ?? true) {
      _isLoading = false;
      _hasError = true;
      _errorMessage = error.description;
      notifyListeners();
    }
  }

  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    if (WebViewService.isInternalUrl(request.url)) {
      return NavigationDecision.navigate;
    }
    // External URL: open in system browser and block in-app navigation.
    UrlLauncherService.openExternal(request.url);
    return NavigationDecision.prevent;
  }

  /// Reloads the tracker URL. Clears any visible error state first.
  Future<void> reload() async {
    _hasError = false;
    _errorMessage = '';
    notifyListeners();
    await _webViewController.reload();
  }

  /// Navigates back in the WebView history if possible.
  Future<void> goBack() async {
    if (await _webViewController.canGoBack()) {
      await _webViewController.goBack();
    }
  }

  /// Returns true if the WebView has history to go back to.
  Future<bool> canGoBack() => _webViewController.canGoBack();

  /// Clears the WebView cache and local storage, then reloads.
  Future<void> clearCache() async {
    await _webViewController.clearCache();
    await _webViewController.clearLocalStorage();
    await reload();
  }

  /// Loads a specific URL. Used for deep link support.
  Future<void> load(String url) async {
    await _webViewController.loadRequest(Uri.parse(url));
  }
}

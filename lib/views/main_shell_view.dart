import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../controllers/notifications_controller.dart';
import '../controllers/webview_controller.dart';
import '../services/url_launcher_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/loading_overlay.dart';
import 'notifications_view.dart';
import 'settings_view.dart';
import 'tracker_view.dart';

/// Root shell that owns the WebviewController and hosts the three main tabs.
///
/// The controller is created here so it can be shared between TrackerView
/// (which renders it) and SettingsView (which can clear its cache).
/// IndexedStack keeps the WebView alive when the user switches tabs.
class MainShellView extends StatefulWidget {
  const MainShellView({super.key});

  @override
  State<MainShellView> createState() => _MainShellViewState();
}

class _MainShellViewState extends State<MainShellView> {
  int _currentIndex = 0;
  late final WebviewController _webviewController;
  late final NotificationsController _notificationsController;
  bool? _lastKnownLoggedIn;

  static const _tabTitles = ['Troop Tracker', 'Notifications', 'Settings'];

  @override
  void initState() {
    super.initState();

    _webviewController = WebviewController();
    _webviewController.addListener(_onWebviewChanged);
    _webviewController.initialize();

    _notificationsController = NotificationsController();

    FirebaseMessaging.onMessage.listen((_) {
      if (_webviewController.isLoggedIn != false) _notificationsController.refresh();
    });
  }

  @override
  void dispose() {
    _webviewController.removeListener(_onWebviewChanged);
    _webviewController.dispose();
    _notificationsController.dispose();
    super.dispose();
  }

  void _onWebviewChanged() {
    final isLoggedIn = _webviewController.isLoggedIn;
    if (_lastKnownLoggedIn == true && isLoggedIn == false) {
      _notificationsController.clearForLogout();
    }
    _lastKnownLoggedIn = isLoggedIn;
    if (mounted) setState(() {});
  }

  AppBar _buildAppBar() {
    final isTrackerTab = _currentIndex == 0;

    return AppBar(
      title: Text(
        _tabTitles[_currentIndex].toUpperCase(),
        style: const TextStyle(
          color: Color(0xFFFFE81F),
          letterSpacing: 3.5,
          fontWeight: FontWeight.w700,
          fontSize: 17,
          shadows: [
            Shadow(color: Color(0xFFFFAA00), blurRadius: 12),
            Shadow(
              color: Color(0xFF000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
      actions: [
        if (isTrackerTab) ...[
          IconButton(
            icon: const Icon(Icons.home_rounded),
            tooltip: 'Home',
            onPressed: () => _webviewController.load(AppConfig.trackerUrl),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser_rounded),
            tooltip: 'Open in Browser',
            onPressed: () =>
                UrlLauncherService.openExternal(AppConfig.trackerUrl),
          ),
        ],
      ],
    );
  }

  void _switchToTracker() => setState(() => _currentIndex = 0);

  @override
  Widget build(BuildContext context) {
    final showLoader = _currentIndex == 0 && _webviewController.isLoading;

    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                TrackerView(controller: _webviewController),
                NotificationsView(
                  controller: _notificationsController,
                  webviewController: _webviewController,
                  onNavigateToTracker: _switchToTracker,
                ),
                SettingsView(webviewController: _webviewController),
              ],
            ),
          ),
          LoadingOverlay(
            progress: _webviewController.loadingProgress,
            isVisible: showLoader,
          ),
        ],
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: _notificationsController,
        builder: (context, _) => AppBottomNav(
          currentIndex: _currentIndex,
          unreadNotificationCount: _webviewController.isLoggedIn == false
              ? 0
              : _notificationsController.unreadCount,
          onTap: (index) {
            setState(() => _currentIndex = index);
            if (index == 1 && _webviewController.isLoggedIn != false) {
              _notificationsController.refresh();
            }
          },
        ),
      ),
    );
  }
}

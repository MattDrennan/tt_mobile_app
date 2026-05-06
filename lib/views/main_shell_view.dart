import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../controllers/webview_controller.dart';
import '../services/url_launcher_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/loading_overlay.dart';
import 'tracker_view.dart';
import 'notifications_view.dart';
import 'settings_view.dart';

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

  static const _tabTitles = ['Troop Tracker', 'Notifications', 'Settings'];

  @override
  void initState() {
    super.initState();
    _webviewController = WebviewController();
    _webviewController.addListener(_onWebviewChanged);
    _webviewController.initialize();
  }

  @override
  void dispose() {
    _webviewController.removeListener(_onWebviewChanged);
    _webviewController.dispose();
    super.dispose();
  }

  void _onWebviewChanged() {
    if (mounted) setState(() {});
  }

  PreferredSizeWidget _buildAppBar() {
    final isTrackerTab = _currentIndex == 0;

    return AppBar(
      title: Text(_tabTitles[_currentIndex]),
      actions: [
        if (isTrackerTab)
          IconButton(
            icon: const Icon(Icons.open_in_browser_rounded),
            tooltip: 'Open in Browser',
            onPressed: () =>
                UrlLauncherService.openExternal(AppConfig.trackerUrl),
          ),
      ],
      bottom: isTrackerTab && _webviewController.isLoading
          ? PreferredSize(
              preferredSize: const Size.fromHeight(3),
              child: LoadingOverlay(
                progress: _webviewController.loadingProgress,
                isVisible: true,
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          TrackerView(controller: _webviewController),
          const NotificationsView(),
          SettingsView(webviewController: _webviewController),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

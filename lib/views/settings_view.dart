import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../controllers/settings_controller.dart';
import '../controllers/webview_controller.dart';
import '../services/url_launcher_service.dart';

/// Native settings screen — no WebView.
///
/// Receives the live [WebviewController] from MainShellView so that
/// "Clear Cache" operates on the active WebView instance.
class SettingsView extends StatefulWidget {
  final WebviewController webviewController;

  const SettingsView({super.key, required this.webviewController});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _settingsController = SettingsController();
  bool _isClearingCache = false;

  Future<void> _clearCache() async {
    setState(() => _isClearingCache = true);
    try {
      await widget.webviewController.clearCache();
    } finally {
      if (mounted) setState(() => _isClearingCache = false);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cache cleared.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 8),

        // App version
        ListTile(
          leading: const Icon(Icons.info_outline_rounded),
          title: const Text('App Version'),
          subtitle: FutureBuilder<String>(
            future: _settingsController.getVersionString(),
            builder: (context, snapshot) {
              return Text(
                snapshot.data ?? '…',
                style: const TextStyle(color: Colors.white54),
              );
            },
          ),
        ),
        const Divider(indent: 16, endIndent: 16),

        // Clear cache
        ListTile(
          leading: _isClearingCache
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_sweep_outlined),
          title: const Text('Clear Cache'),
          subtitle: const Text(
            'Clears WebView cache and reloads',
            style: TextStyle(color: Colors.white54),
          ),
          onTap: _isClearingCache ? null : _clearCache,
        ),
        const Divider(indent: 16, endIndent: 16),

        // Open in browser
        ListTile(
          leading: const Icon(Icons.open_in_browser_rounded),
          title: const Text('Open in Browser'),
          subtitle: Text(
            AppConfig.trackerUrl,
            style: const TextStyle(color: Colors.white54),
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => UrlLauncherService.openExternal(AppConfig.trackerUrl),
        ),
        const Divider(indent: 16, endIndent: 16),

        const SizedBox(height: 32),
        Text(
          AppConfig.appName,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white24, fontSize: 13),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

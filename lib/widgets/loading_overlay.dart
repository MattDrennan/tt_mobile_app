import 'package:flutter/material.dart';

import '../config/app_config.dart';

/// A thin LinearProgressIndicator shown at the top of the screen
/// while the WebView is loading a page.
class LoadingOverlay extends StatelessWidget {
  final double progress;
  final bool isVisible;

  const LoadingOverlay({
    super.key,
    required this.progress,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();
    return LinearProgressIndicator(
      value: progress > 0 ? progress : null,
      backgroundColor: Colors.transparent,
      valueColor: const AlwaysStoppedAnimation<Color>(AppConfig.primaryColor),
      minHeight: 3,
    );
  }
}

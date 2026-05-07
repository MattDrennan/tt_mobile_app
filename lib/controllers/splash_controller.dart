/// Controls the minimum time the Flutter splash view is visible.
/// Keeps the splash from flashing away immediately on fast devices
/// while not adding a noticeable delay on slower ones.
class SplashController {
  static const Duration _minimumDisplayDuration = Duration(milliseconds: 1800);

  /// Resolves after the minimum splash duration elapses.
  Future<void> waitForReady() => Future.delayed(_minimumDisplayDuration);
}

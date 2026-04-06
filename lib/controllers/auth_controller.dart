import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/site_status.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

/// Global controller registered in the Provider tree.
///
/// Owns:
/// - The current [AppUser] (replaces the global `types.User user` variable)
/// - Auth lifecycle: restoreSession, login, logout
/// - Access checks: fetchSiteStatus, checkUserAccess
class AuthController extends ChangeNotifier {
  final AuthService _authService;
  final ApiClient _api;
  final StorageService _storage;
  NotificationService? _notificationService;

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  SiteStatus? _siteStatus;
  bool _loggedOut = false;

  AuthController(this._authService, this._api, this._storage);

  // ── Exposed state ─────────────────────────────────────────────────────────

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  SiteStatus? get siteStatus => _siteStatus;
  bool get loggedOut => _loggedOut;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// Call once at startup to restore a previous session from storage.
  Future<void> restoreSession() async {
    _setLoading(true);
    try {
      final userData = _authService.restoreSession();
      if (userData != null) {
        _currentUser = AppUser.fromJson(userData);
      }
    } catch (_) {
      _currentUser = null;
    } finally {
      _setLoading(false);
    }
  }

  /// Wire in the notification service after construction.
  /// Called from main after both objects are created.
  void setNotificationService(NotificationService service) {
    _notificationService = service;
  }

  // ── Auth actions ───────────────────────────────────────────────────────────

  /// Runs the OAuth2 PKCE flow and populates [currentUser] on success.
  Future<void> login() async {
    _setLoading(true);
    _clearError();
    try {
      final userData = await _authService.performOAuthLogin();
      _currentUser = AppUser.fromJson(userData);
      // Register FCM after a successful login
      await _notificationService?.registerFcmToken(_currentUser!.id);
    } catch (e) {
      _errorMessage =
          e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Clears session and deregisters FCM token.
  Future<void> logout() async {
    _setLoading(true);
    try {
      // Best-effort FCM deregistration
      try {
        await _api.postJson(
          _api.mobileApiUri(),
          {
            'action': 'logoutFCM',
            'apiKey': _storage.getApiKey() ?? '',
            'fcm': _storage.getFcmToken() ?? '',
          },
        );
      } catch (_) {}
      await _authService.clearSession();
      _currentUser = null;
      _loggedOut = true;
    } catch (_) {
      // Still clear local state on error
      await _authService.clearSession();
      _currentUser = null;
      _loggedOut = true;
    } finally {
      _setLoading(false);
    }
  }

  /// Resets the loggedOut flag after navigation has been handled.
  void clearLoggedOutFlag() {
    _loggedOut = false;
  }

  // ── Access checks ──────────────────────────────────────────────────────────

  /// Checks whether the site is open (`is_closed` action).
  Future<void> fetchSiteStatus() async {
    try {
      final data = await _api.getJson(
        _api.mobileApiUri({'action': 'is_closed'}),
      );
      _siteStatus = SiteStatus.fromClosedJson(data as Map<String, dynamic>);
      notifyListeners();
    } catch (_) {
      // Non-fatal — leave siteStatus null
    }
  }

  /// Checks whether [trooperId] can access the app (`user_status` action).
  /// Returns a [SiteStatus] — the view decides how to route.
  Future<SiteStatus> checkUserAccess(int trooperId) async {
    final data = await _api.getJson(
      _api.mobileApiUri({
        'action': 'user_status',
        'trooperid': trooperId,
      }),
    );
    return SiteStatus.fromUserStatusJson(data as Map<String, dynamic>);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}

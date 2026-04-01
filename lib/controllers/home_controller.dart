import 'package:flutter/foundation.dart';

import '../services/api_client.dart';

/// Page-scoped controller for HomeView.
/// Checks whether the current trooper has unconfirmed troops.
class HomeController extends ChangeNotifier {
  final ApiClient _api;
  final int trooperId;

  bool _hasUnconfirmedTroops = false;
  bool _isLoading = false;

  HomeController(this._api, {required this.trooperId});

  bool get hasUnconfirmedTroops => _hasUnconfirmedTroops;
  bool get isLoading => _isLoading;

  /// Checks the API and sets [hasUnconfirmedTroops].
  Future<void> checkUnconfirmedTroops() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _api.getJson(
        _api.mobileApiUri({
          'trooperid': trooperId,
          'action': 'get_confirm_events_trooper',
        }),
      );
      final troops = (data as Map<String, dynamic>)['troops'];
      _hasUnconfirmedTroops = troops is List && troops.isNotEmpty;
    } catch (_) {
      _hasUnconfirmedTroops = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

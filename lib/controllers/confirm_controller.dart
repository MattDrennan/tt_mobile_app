import 'package:flutter/foundation.dart';

import '../models/costume.dart';
import '../services/api_client.dart';

/// Page-scoped controller for ConfirmView.
class ConfirmController extends ChangeNotifier {
  final ApiClient _api;
  final int trooperId;

  List<dynamic> _troops = [];
  final List<int> _selectedTroopIds = [];
  Costume? _selectedCostume;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  ConfirmController(this._api, {required this.trooperId});

  // ── Exposed state ──────────────────────────────────────────────────────────

  List<dynamic> get troops => _troops;
  List<int> get selectedTroopIds => _selectedTroopIds;
  Costume? get selectedCostume => _selectedCostume;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

  // ── Data loading ───────────────────────────────────────────────────────────

  Future<void> fetchTroops() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _api.getJson(
        _api.mobileApiUri({
          'trooperid': trooperId,
          'action': 'get_confirm_events_trooper',
        }),
      );
      _troops =
          (data as Map<String, dynamic>)['troops'] as List? ?? [];
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Returns the costume list for the [DropdownSearch] widget.
  /// Called as an async loader directly by the dropdown.
  Future<List<Costume>> fetchCostumes(String? filter) async {
    final data = await _api.getJson(
      _api.mobileApiUri({
        'action': 'get_costumes_for_trooper',
        'trooperid': trooperId,
        'friendid': 0,
        'allowDualCostume': true,
      }),
    );
    final list = data as List? ?? [];
    return list.map((c) => Costume.fromJson(c as Map<String, dynamic>)).toList();
  }

  // ── Selection ──────────────────────────────────────────────────────────────

  void selectCostume(Costume? costume) {
    _selectedCostume = costume;
    notifyListeners();
  }

  void toggleTroop(int troopId, bool selected) {
    if (selected) {
      _selectedTroopIds.add(troopId);
    } else {
      _selectedTroopIds.remove(troopId);
    }
    notifyListeners();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<bool> confirmAttendance() async {
    if (_selectedTroopIds.isEmpty || _selectedCostume == null) return false;
    return _updateStatus('attended', costumeId: _selectedCostume!.id);
  }

  Future<bool> adviseNoShow() async {
    if (_selectedTroopIds.isEmpty) return false;
    return _updateStatus('noshow');
  }

  Future<bool> _updateStatus(String status, {int? costumeId}) async {
    _isSubmitting = true;
    notifyListeners();
    final updated = <int>[];
    try {
      for (final troopId in List.of(_selectedTroopIds)) {
        await _api.getJson(
          _api.mobileApiUri({
            'action': 'set_status_costume',
            'trooperid': trooperId,
            'troopid': troopId,
            'status': status,
            'costume': costumeId ?? 0,
          }),
        );
        updated.add(troopId);
      }
      _troops.removeWhere((t) => updated.contains(t['troopid']));
      _selectedTroopIds.clear();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}

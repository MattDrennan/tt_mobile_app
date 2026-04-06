import 'package:flutter/foundation.dart';

import '../models/costume.dart';
import '../models/trooper.dart';
import '../services/api_client.dart';

/// Page-scoped controller for AddFriendView.
class AddFriendController extends ChangeNotifier {
  final ApiClient _api;
  final int troopId;
  final String addedByUserId;
  final int limitedEvent;
  final int allowTentative;
  final List<dynamic> shifts;

  String _selectedStatus;
  Trooper? _selectedTrooper;
  Costume? _selectedCostume;
  Costume? _backupCostume;
  int? _selectedShiftId;
  bool _isSubmitting = false;
  bool _submitSuccess = false;
  String? _successMessage;
  String? _error;

  AddFriendController(
    this._api, {
    required this.troopId,
    required this.addedByUserId,
    required this.limitedEvent,
    required this.allowTentative,
    required this.shifts,
  }) : _selectedStatus = limitedEvent == 1 ? 'pending' : 'going' {
    final available = availableShifts;
    if (available.isNotEmpty) {
      _selectedShiftId = (available.first['id'] as num).toInt();
    }
  }

  // ── Exposed state ──────────────────────────────────────────────────────────

  String get selectedStatus => _selectedStatus;
  Trooper? get selectedTrooper => _selectedTrooper;
  Costume? get selectedCostume => _selectedCostume;
  Costume? get backupCostume => _backupCostume;
  int? get selectedShiftId => _selectedShiftId;
  bool get isSubmitting => _isSubmitting;
  bool get submitSuccess => _submitSuccess;
  String? get successMessage => _successMessage;
  String? get error => _error;
  bool get hasMultipleShifts => shifts.length > 1;

  List<dynamic> get availableShifts =>
      shifts.where((s) => s['can_add_friend'] != false).toList();

  // ── Data loading ───────────────────────────────────────────────────────────

  Future<List<Trooper>> fetchAvailableTroopers(String? filter) async {
    final params = <String, dynamic>{
      'action': 'get_available_troopers_for_event',
      'troopid': troopId,
    };
    if (_selectedShiftId != null) params['shiftid'] = _selectedShiftId!;

    final data = await _api.getJson(_api.mobileApiUri(params));
    final list = data as List? ?? [];
    return list.map((t) => Trooper.fromJson(t as Map<String, dynamic>)).toList();
  }

  Future<List<Costume>> fetchCostumes(int friendId, String? filter) async {
    final data = await _api.getJson(
      _api.mobileApiUri({
        'action': 'get_costumes_for_trooper',
        'trooperid': 0,
        'friendid': friendId,
      }),
    );
    final list = data as List? ?? [];
    return list.map((c) => Costume.fromJson(c as Map<String, dynamic>)).toList();
  }

  // ── Selection ──────────────────────────────────────────────────────────────

  void setStatus(String status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void setTrooper(Trooper? trooper) {
    _selectedTrooper = trooper;
    _selectedCostume = null;
    _backupCostume = null;
    notifyListeners();
  }

  void setCostume(Costume? costume) {
    _selectedCostume = costume;
    notifyListeners();
  }

  void setBackupCostume(Costume? costume) {
    _backupCostume = costume;
    notifyListeners();
  }

  void setShift(int? shiftId) {
    _selectedShiftId = shiftId;
    _selectedTrooper = null;
    _selectedCostume = null;
    _backupCostume = null;
    notifyListeners();
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<bool> submit() async {
    if (_selectedTrooper == null || _selectedCostume == null) return false;

    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final params = <String, dynamic>{
        'action': 'sign_up',
        'trooperid': _selectedTrooper!.id,
        'addedby': addedByUserId,
        'troopid': troopId,
        'status': _selectedStatus,
        'costume': _selectedCostume?.id ?? 0,
        'backupcostume': _backupCostume?.id ?? 0,
      };
      if (_selectedShiftId != null) params['shiftid'] = _selectedShiftId!;

      final data = await _api.getJson(_api.mobileApiUri(params));
      final map = data as Map<String, dynamic>;
      final success = map['success'] == true;
      if (success) {
        _submitSuccess = true;
        _successMessage = map['success_message']?.toString();
      } else {
        _error = map['success_message']?.toString() ?? 'Failed to sign up!';
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}

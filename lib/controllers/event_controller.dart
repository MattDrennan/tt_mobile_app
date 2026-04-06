import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../models/event_detail.dart';
import '../models/roster_entry.dart';
import '../services/api_client.dart';

/// Page-scoped controller for EventView.
/// Owns all data fetching and mutating actions for a single troop event.
class EventController extends ChangeNotifier {
  final ApiClient _api;
  final int eventId;
  final String userId;

  EventDetail? _event;
  List<RosterEntry> _roster = [];
  List<dynamic> _photoList = [];
  List<dynamic> _myFriends = [];
  List<dynamic> _myGuests = [];
  bool _isInRoster = false;
  Map<int, String> _myShiftStatuses = {};
  int? _selectedRosterShiftId;

  bool _isLoading = false;
  bool _isActionInProgress = false;
  String? _actionError;
  bool _actionSuccess = false;

  EventController(this._api, {required this.eventId, required this.userId});

  // ── Exposed state ──────────────────────────────────────────────────────────

  EventDetail? get event => _event;
  List<RosterEntry> get roster => _roster;
  List<dynamic> get photoList => _photoList;
  List<dynamic> get myFriends => _myFriends;
  List<dynamic> get myGuests => _myGuests;
  bool get isInRoster => _isInRoster;
  Map<int, String> get myShiftStatuses => _myShiftStatuses;
  int? get selectedRosterShiftId => _selectedRosterShiftId;
  bool get isLoading => _isLoading;
  bool get isActionInProgress => _isActionInProgress;
  String? get actionError => _actionError;
  bool get actionSuccess => _actionSuccess;

  List<RosterEntry> get filteredRoster {
    final shifts = _event?.shifts ?? [];
    if (shifts.length <= 1 || _selectedRosterShiftId == null) return _roster;
    return _roster.where((m) => m.shiftId == _selectedRosterShiftId).toList();
  }

  // ── Data loading ───────────────────────────────────────────────────────────

  /// Fetches all event data in parallel.
  Future<void> fetchAll() async {
    _isLoading = true;
    notifyListeners();
    await Future.wait([
      _fetchEvent(),
      _fetchRoster(),
      _checkInRoster(),
      _fetchMyFriends(),
      _fetchMyGuests(),
      _fetchPhotos(),
    ]);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchEvent() async {
    try {
      final data = await _api.getJson(
        _api.mobileApiUri({
          'troopid': eventId,
          'trooperid': userId,
          'action': 'event',
        }),
      );
      _event = EventDetail.fromJson(data as Map<String, dynamic>);
      final shifts = _event!.shifts;
      if (shifts.isNotEmpty && _selectedRosterShiftId == null) {
        _selectedRosterShiftId = (shifts.first['id'] as num).toInt();
      }
    } catch (_) {}
  }

  Future<void> _fetchRoster() async {
    try {
      final data = await _api.getJson(
        _api.mobileApiUri({
          'troopid': eventId,
          'action': 'get_roster_for_event',
        }),
      );
      final list = data as List? ?? [];
      _roster = list
          .map((m) => RosterEntry.fromJson(m as Map<String, dynamic>))
          .toList();
    } catch (_) {}
  }

  Future<void> _checkInRoster() async {
    try {
      final data = await _api.getJson(
        _api.mobileApiUri({
          'trooperid': userId,
          'troopid': eventId,
          'action': 'trooper_in_event',
        }),
      );
      final map = data as Map<String, dynamic>;
      _isInRoster = map['inEvent'] == true;
      final shifts = map['my_shifts'] as List? ?? [];
      _myShiftStatuses = {
        for (final s in shifts)
          (s['shift_id'] as num).toInt(): s['status_formatted'] as String,
      };
    } catch (_) {
      _isInRoster = false;
      _myShiftStatuses = {};
    }
  }

  Future<void> _fetchMyFriends() async {
    try {
      final data = await _api.getJson(
        _api.mobileApiUri({
          'action': 'get_friends_for_event',
          'trooperid': userId,
          'troopid': eventId,
        }),
      );
      _myFriends = data as List? ?? [];
    } catch (_) {}
  }

  Future<void> _fetchMyGuests() async {
    try {
      final data = await _api.getJson(
        _api.mobileApiUri({
          'action': 'get_guests_for_event',
          'trooperid': userId,
          'troopid': eventId,
        }),
      );
      _myGuests = data as List? ?? [];
    } catch (_) {}
  }

  Future<void> _fetchPhotos() async {
    try {
      final data = await _api.getJson(
        _api.mobileApiUri({
          'action': 'get_photos_by_event',
          'troopid': eventId,
        }),
      );
      _photoList = (data as Map<String, dynamic>)['photos'] as List? ?? [];
    } catch (_) {}
  }

  Future<void> refreshAll() => fetchAll();

  // ── Mutating actions ───────────────────────────────────────────────────────

  void setRosterShiftFilter(int shiftId) {
    _selectedRosterShiftId = shiftId;
    notifyListeners();
  }

  Future<bool> cancelTroop() async {
    if (_event?.isManualSelection == true) {
      _actionError =
          'Manual Selection events do not allow cancellations from the app.';
      notifyListeners();
      return false;
    }
    _startAction();
    try {
      final data = await _api.getJson(
        _api.mobileApiUri({
          'trooperid': userId,
          'troopid': eventId,
          'action': 'cancel_troop',
        }),
      );
      final success = (data as Map<String, dynamic>)['success'] == true;
      if (success) {
        _isInRoster = false;
        _myShiftStatuses = {};
        await Future.wait([_fetchEvent(), _fetchRoster()]);
      } else {
        _actionError = 'Something went wrong.';
      }
      _endAction();
      return success;
    } catch (e) {
      _actionError = e.toString();
      _endAction();
      return false;
    }
  }

  Future<bool> cancelShift(int shiftId) async {
    if (_event?.isManualSelection == true) {
      _actionError =
          'Manual Selection events do not allow cancellations from the app.';
      notifyListeners();
      return false;
    }
    _startAction();
    try {
      final data = await _api.getJson(
        _api.mobileApiUri({
          'action': 'cancel_shift',
          'trooperid': userId,
          'shiftid': shiftId,
        }),
      );
      final success = (data as Map<String, dynamic>)['success'] == true;
      if (success) {
        await Future.wait([_fetchEvent(), _fetchMyFriends(), _fetchMyGuests(), _checkInRoster()]);
      } else {
        _actionError = 'Something went wrong.';
      }
      _endAction();
      return success;
    } catch (e) {
      _actionError = e.toString();
      _endAction();
      return false;
    }
  }

  Future<bool> cancelGuest(int guestId) async {
    if (_event?.isManualSelection == true) {
      _actionError =
          'Manual Selection events do not allow cancellations from the app.';
      notifyListeners();
      return false;
    }
    _startAction();
    try {
      final data = await _api.getJson(
        _api.mobileApiUri({
          'action': 'cancel_guest',
          'trooperid': userId,
          'guestid': guestId,
        }),
      );
      final success = (data as Map<String, dynamic>)['success'] == true;
      if (success) {
        await Future.wait([_fetchMyGuests(), _fetchEvent()]);
      } else {
        _actionError = 'Something went wrong.';
      }
      _endAction();
      return success;
    } catch (e) {
      _actionError = e.toString();
      _endAction();
      return false;
    }
  }

  Future<bool> cancelFriendShift(int friendTrooperId, int shiftId) async {
    if (_event?.isManualSelection == true) {
      _actionError =
          'Manual Selection events do not allow cancellations from the app.';
      notifyListeners();
      return false;
    }
    _startAction();
    try {
      final data = await _api.getJson(
        _api.mobileApiUri({
          'action': 'cancel_shift',
          'trooperid': userId,
          'shiftid': shiftId,
          'friendtrooperid': friendTrooperId,
        }),
      );
      final success = (data as Map<String, dynamic>)['success'] == true;
      if (success) {
        await Future.wait([_fetchMyFriends(), _fetchEvent()]);
      } else {
        _actionError = 'Something went wrong.';
      }
      _endAction();
      return success;
    } catch (e) {
      _actionError = e.toString();
      _endAction();
      return false;
    }
  }

  Future<bool> uploadPhoto(XFile photo) async {
    _startAction();
    try {
      final file = File(photo.path);
      final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType.parse(mimeType),
      );
      final response = await _api.postMultipart(
        _api.mobileApiUri(),
        fields: {
          'action': 'upload_photo',
          'troopid': eventId.toString(),
          'trooperid': userId,
          'admin': (_event?.isInFuture == true) ? '1' : '0',
        },
        files: [multipartFile],
      );
      final body = await http.Response.fromStream(response);
      final result = json.decode(body.body) as Map<String, dynamic>;
      final success = body.statusCode == 200 && result['success'] == true;
      if (!success) {
        _actionError = result['message']?.toString()
            ?? result['error']?.toString()
            ?? 'Upload failed.';
      } else {
        await _fetchPhotos();
      }
      _endAction();
      return success;
    } catch (e) {
      _actionError = 'Upload error: $e';
      _endAction();
      return false;
    }
  }

  void clearActionError() {
    _actionError = null;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _startAction() {
    _isActionInProgress = true;
    _actionError = null;
    _actionSuccess = false;
    notifyListeners();
  }

  void _endAction() {
    _isActionInProgress = false;
    notifyListeners();
  }
}

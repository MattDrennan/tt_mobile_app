import 'package:intl/intl.dart';

/// Wraps the raw event detail map returned by the `event` API action.
///
/// Provides typed getters for frequently accessed fields and business-logic
/// helpers (isManualSelection, isInFuture, etc.) so views stay dumb.
class EventDetail {
  final Map<String, dynamic> _data;

  EventDetail(this._data);

  factory EventDetail.fromJson(Map<String, dynamic> json) => EventDetail(json);

  /// The underlying raw map, needed by views that access less-common fields.
  Map<String, dynamic> get data => _data;

  String get name => _data['name']?.toString() ?? '';
  String get venue => _data['venue']?.toString() ?? '';
  String? get location => _data['location']?.toString();
  String? get website => _data['website']?.toString();
  String? get dateStart => _data['dateStart']?.toString();
  String? get dateEnd => _data['dateEnd']?.toString();
  String? get comments => _data['comments']?.toString();
  String? get referred => _data['referred']?.toString();
  String? get amenities => _data['amenities']?.toString();

  List<dynamic> get shifts => List<dynamic>.from(_data['shifts'] ?? []);

  bool get isLimited =>
      _data['isLimited'] == true || _data['isLimited'] == 1;

  bool get guestsAllowed {
    final v = _data['guests_allowed'];
    if (v == null) return true;
    return (v as num).toInt() > 0;
  }

  bool get friendsAllowed {
    final v = _data['friends_allowed'];
    if (v == null) return true;
    return (v as num).toInt() > 0;
  }

  int get limitedEvent => (_data['limitedEvent'] as num?)?.toInt() ?? 0;
  int get allowTentative => (_data['allowTentative'] as num?)?.toInt() ?? 0;

  int? get numberOfAttend => (_data['numberOfAttend'] as num?)?.toInt();
  int? get requestedNumber => (_data['requestedNumber'] as num?)?.toInt();
  String? get requestedCharacter => _data['requestedCharacter']?.toString();

  bool get secureChanging => (_data['secureChanging'] as num?)?.toInt() == 1;
  bool get blasters => (_data['blasters'] as num?)?.toInt() == 1;
  bool get lightsabers => (_data['lightsabers'] as num?)?.toInt() == 1;
  bool get parking => (_data['parking'] as num?)?.toInt() == 1;
  bool get mobility => (_data['mobility'] as num?)?.toInt() == 1;

  String? get limitTotal => _data['limitTotal']?.toString();
  String? get limitClubs => _data['limitClubs']?.toString();
  String? get limitAll => _data['limitAll']?.toString();

  // ── Business logic helpers ────────────────────────────────────────────────

  bool get isClosed {
    final closed = _data['closed'];
    if (closed is int) return closed == 2 || closed == 3 || closed == 4;
    return false;
  }

  bool get isManualSelection {
    final status = _data['closed']?.toString().toLowerCase().trim();
    return status == 'manualselection';
  }

  bool get isInFuture {
    final endDateStr = _data['dateEnd']?.toString();
    if (endDateStr == null || endDateStr.isEmpty) return false;
    final endDate = _parseApiDateTime(endDateStr);
    if (endDate == null) return false;
    return DateTime.now().isBefore(endDate);
  }

  DateTime? _parseApiDateTime(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return null;
    try {
      return DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateTime);
    } catch (_) {
      return DateTime.tryParse(dateTime)?.toLocal();
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:html_unescape/html_unescape.dart';

import '../models/troop.dart';
import '../services/api_client.dart';

/// Page-scoped controller shared by TroopListView and MyTroopsView.
class TroopController extends ChangeNotifier {
  final ApiClient _api;
  final _unescape = HtmlUnescape();

  List<Troop> _allTroops = [];
  List<Troop> _filtered = [];
  List<Troop> _myTroops = [];
  int _selectedSquad = 0;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;

  TroopController(this._api);

  // ── Exposed state ──────────────────────────────────────────────────────────

  List<Troop> get troops => _filtered;
  List<Troop> get myTroops => _myTroops;
  int get selectedSquad => _selectedSquad;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Data loading ───────────────────────────────────────────────────────────

  Future<void> fetchTroops([int squad = 0]) async {
    _selectedSquad = squad;
    _setLoading(true);
    _error = null;
    try {
      final data = await _api.getJson(
        _api.mobileApiUri({'squad': squad, 'action': 'get_troops_by_squad'}),
      );
      final list = (data as Map<String, dynamic>)['troops'] as List? ?? [];
      _allTroops = list.map((t) => Troop.fromJson(t as Map<String, dynamic>)).toList();
      _applyFilter();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchMyTroops(String userId) async {
    _setLoading(true);
    _error = null;
    try {
      final data = await _api.getJson(
        _api.mobileApiUri({'user_id': userId, 'action': 'troops'}),
      );
      final list = (data as Map<String, dynamic>)['troops'] as List? ?? [];
      _myTroops = list.map((t) => Troop.fromJson(t as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ── Filtering ──────────────────────────────────────────────────────────────

  void setSearch(String query) {
    _searchQuery = query;
    _applyFilter();
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filtered = List.of(_allTroops);
    } else {
      final q = _searchQuery.toLowerCase();
      _filtered = _allTroops
          .where((t) => _unescape.convert(t.name).toLowerCase().contains(q))
          .toList();
    }
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

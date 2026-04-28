import 'api_client.dart';

/// ApiClient that returns canned fixture data instead of making network calls.
/// Used exclusively by lib/main_screenshot.dart for screenshot tests.
class FakeApiClient extends ApiClient {
  FakeApiClient(super.storage);

  @override
  Future<dynamic> getJson(Uri uri, {Map<String, String>? headers}) async {
    switch (uri.queryParameters['action']) {
      case 'get_organizations':
        return _orgs;
      case 'get_troops_by_squad':
        return _troops;
      case 'troops':
        return _myTroops;
      case 'is_closed':
        return {'isWebsiteClosed': false, 'siteMessage': null};
      case 'user_status':
        return {'canAccess': true, 'isBanned': false};
      default:
        return <String, dynamic>{};
    }
  }

  @override
  Future<dynamic> postJson(
    Uri uri,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async =>
      {'success': true};
}

// ── Fixture data ──────────────────────────────────────────────────────────────

const _orgs = {
  'organizations': [
    {'id': 1, 'name': 'Everglades Squad'},
    {'id': 2, 'name': 'Makaze Squad'},
    {'id': 3, 'name': 'Parjai Squad'},
    {'id': 4, 'name': 'Squad 7'},
    {'id': 5, 'name': 'Tampa Bay Squad'},
  ],
};

const _troops = {
  'troops': [
    {
      'troopid': 1001,
      'name': 'Star Wars Celebration 2025',
      'dateStart': '2025-05-07T10:00:00',
      'dateEnd': '2025-05-11T18:00:00',
      'squad': 1,
      'link': 0,
      'notice': null,
      'trooper_count': 24,
    },
    {
      'troopid': 1002,
      'name': "Galaxy's Edge Character Experience",
      'dateStart': '2025-06-14T09:00:00',
      'dateEnd': '2025-06-14T17:00:00',
      'squad': 5,
      'link': 0,
      'notice': null,
      'trooper_count': 8,
    },
    {
      'troopid': 1003,
      'name': "Children's Hospital Visit - Tampa",
      'dateStart': '2025-07-19T10:00:00',
      'dateEnd': '2025-07-19T14:00:00',
      'squad': 5,
      'link': 0,
      'notice': null,
      'trooper_count': 6,
    },
    {
      'troopid': 1004,
      'name': 'Make-A-Wish Foundation Event',
      'dateStart': '2025-08-02T09:00:00',
      'dateEnd': '2025-08-02T13:00:00',
      'squad': 2,
      'link': 0,
      'notice': 'Minimum 5 troopers required',
      'trooper_count': 3,
    },
    {
      'troopid': 1005,
      'name': 'MegaCon Orlando',
      'dateStart': '2025-08-22T10:00:00',
      'dateEnd': '2025-08-24T18:00:00',
      'squad': 3,
      'link': 0,
      'notice': null,
      'trooper_count': 15,
    },
  ],
};

const _myTroops = {
  'troops': [
    {
      'troopid': 1002,
      'name': "Galaxy's Edge Character Experience",
      'dateStart': '2025-06-14T09:00:00',
      'dateEnd': '2025-06-14T17:00:00',
      'squad': 5,
      'link': 1,
      'thread_id': 5001,
      'post_id': 10001,
      'trooper_count': 8,
      'my_shifts': [
        {'display': 'Jun 14, 9:00 AM – 1:00 PM', 'status': 'Approved'},
      ],
    },
    {
      'troopid': 1003,
      'name': "Children's Hospital Visit - Tampa",
      'dateStart': '2025-07-19T10:00:00',
      'dateEnd': '2025-07-19T14:00:00',
      'squad': 5,
      'link': 0,
      'trooper_count': 6,
      'my_shifts': [
        {'display': 'Jul 19, 10:00 AM – 2:00 PM', 'status': 'Pending'},
      ],
    },
  ],
};

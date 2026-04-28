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
      case 'event':
        return _event;
      case 'get_roster_for_event':
        return _roster;
      case 'trooper_in_event':
        return _trooperInEvent;
      case 'get_friends_for_event':
        return <dynamic>[];
      case 'get_guests_for_event':
        return <dynamic>[];
      case 'get_photos_by_event':
        return {'photos': <dynamic>[]};
      case 'is_closed':
        return {'isWebsiteClosed': false, 'siteMessage': null};
      case 'user_status':
        return {'canAccess': true, 'isBanned': false};
      default:
        return <String, dynamic>{};
    }
  }

  @override
  Future<dynamic> getThread(int threadId, {int page = 1}) async => _thread;

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

const _event = {
  'name': "Galaxy's Edge Character Experience",
  'venue': "Disney's Hollywood Studios — Star Wars: Galaxy's Edge",
  'location': '351 S Studio Dr, Lake Buena Vista, FL 32830',
  'website': '',
  'dateStart': '2025-06-14 09:00:00',
  'dateEnd': '2025-06-14 17:00:00',
  'comments':
      '[b]All members must be in full kit.[/b]\nCheck-in at the main entrance 30 minutes before your shift.',
  'referred': 'John Smith (FL-12345)',
  'amenities': 'Yes — indoor restrooms available',
  'shifts': [
    {'id': 1, 'display': '9:00 AM – 1:00 PM'},
    {'id': 2, 'display': '1:00 PM – 5:00 PM'},
  ],
  'isLimited': false,
  'guests_allowed': 1,
  'friends_allowed': 1,
  'limitedEvent': 0,
  'allowTentative': 0,
  'numberOfAttend': 8,
  'requestedNumber': 10,
  'requestedCharacter': 'Stormtroopers, Darth Vader',
  'secureChanging': 1,
  'blasters': 1,
  'lightsabers': 0,
  'parking': 1,
  'mobility': 1,
  'closed': 0,
  'missionBriefRequired': false,
  'hasMissionBriefAck': false,
  'thread_id': 5001,
  'post_id': 10001,
};

const _roster = [
  {
    'status_formatted': 'Approved',
    'trooper_name': 'CommanderRex_FL',
    'tkid_formatted': 'FL-11111',
    'costume_name': 'Phase II Clone Trooper',
    'backup_costume_name': '',
    'signuptime': '2025-05-01',
    'shift_id': 1,
  },
  {
    'status_formatted': 'Approved',
    'trooper_name': 'Demo Trooper',
    'tkid_formatted': 'FL-99999',
    'costume_name': 'TK Stormtrooper',
    'backup_costume_name': 'Darth Vader',
    'signuptime': '2025-05-03',
    'shift_id': 1,
  },
  {
    'status_formatted': 'Approved',
    'trooper_name': 'Boba_Fett_FL',
    'tkid_formatted': 'FL-22222',
    'costume_name': 'Boba Fett (ESB)',
    'backup_costume_name': '',
    'signuptime': '2025-05-05',
    'shift_id': 2,
  },
  {
    'status_formatted': 'Tentative',
    'trooper_name': 'VaderFL501',
    'tkid_formatted': 'FL-33333',
    'costume_name': 'Darth Vader',
    'backup_costume_name': '',
    'signuptime': '2025-05-06',
    'shift_id': 2,
  },
];

const _trooperInEvent = {
  'inEvent': true,
  'my_shifts': [
    {'shift_id': 1, 'status_formatted': 'Approved'},
  ],
};

const _thread = {
  'thread': {'thread_id': 5001, 'title': "Galaxy's Edge Character Experience"},
  'posts': [
    {
      'post_id': 10001,
      'message_state': 'visible',
      'post_date': 1747123200,
      'message_parsed':
          '<p>Reminder: meet at the main entrance 15 minutes early! Parking is in the main lot.</p>',
      'User': {
        'user_id': '11111',
        'username': 'CommanderRex_FL',
        'avatar_urls': {'s': null},
      },
    },
    {
      'post_id': 10002,
      'message_state': 'visible',
      'post_date': 1747209600,
      'message_parsed': '<p>Looking forward to it! Bringing my TK armor.</p>',
      'User': {
        'user_id': '99999',
        'username': 'Demo Trooper',
        'avatar_urls': {'s': null},
      },
    },
    {
      'post_id': 10003,
      'message_state': 'visible',
      'post_date': 1747296000,
      'message_parsed':
          '<p>Does anyone need a ride from the I-4 park-and-ride?</p>',
      'User': {
        'user_id': '22222',
        'username': 'Boba_Fett_FL',
        'avatar_urls': {'s': null},
      },
    },
  ],
};

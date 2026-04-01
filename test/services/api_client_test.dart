import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/services/api_client.dart';
import 'package:tt_mobile_app/services/storage_service.dart';

/// Minimal mock — we only test URI builders, which don't call storage.
class _FakeStorage extends StorageService {
  @override
  String? getApiKey() => 'test-api-key';
}

void main() {
  late ApiClient api;

  setUp(() {
    api = ApiClient(_FakeStorage());
  });

  group('ApiClient URI builders', () {
    test('mobileApiUri builds correct base URI with params', () {
      final uri = api.mobileApiUri({'action': 'get_troops_by_squad', 'squad': 2});
      expect(uri.queryParameters['action'], 'get_troops_by_squad');
      expect(uri.queryParameters['squad'], '2');
    });

    test('mobileApiUri works with no params', () {
      final uri = api.mobileApiUri();
      expect(uri, isA<Uri>());
    });

    test('forumApiUri appends path and params', () {
      final uri = api.forumApiUri('threads/42', {'with_posts': true});
      expect(uri.path, contains('threads/42'));
      expect(uri.queryParameters['with_posts'], 'true');
    });

    test('troopTrackerUploadUri is a valid URI', () {
      final uri = api.troopTrackerUploadUri();
      expect(uri, isA<Uri>());
    });
  });
}

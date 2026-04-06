import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/models/site_status.dart';

void main() {
  group('SiteStatus.fromUserStatusJson', () {
    test('parses canAccess true and isBanned false', () {
      final status = SiteStatus.fromUserStatusJson({
        'canAccess': true,
        'isBanned': false,
        'message': 'Welcome!',
      });
      expect(status.canAccess, isTrue);
      expect(status.isBanned, isFalse);
      expect(status.message, 'Welcome!');
      expect(status.isClosed, isFalse);
    });

    test('parses isBanned as integer 1', () {
      final status = SiteStatus.fromUserStatusJson({
        'canAccess': 0,
        'isBanned': 1,
      });
      expect(status.isBanned, isTrue);
      expect(status.canAccess, isFalse);
    });

    test('parses isBanned as string "1"', () {
      final status = SiteStatus.fromUserStatusJson({
        'canAccess': '1',
        'isBanned': '1',
      });
      expect(status.isBanned, isTrue);
      expect(status.canAccess, isTrue);
    });

    test('parses isBanned as string "true"', () {
      final status = SiteStatus.fromUserStatusJson({
        'canAccess': 'false',
        'isBanned': 'true',
      });
      expect(status.isBanned, isTrue);
    });

    test('falls back to ban message when isBanned and no message', () {
      final status = SiteStatus.fromUserStatusJson({
        'canAccess': false,
        'isBanned': true,
      });
      expect(status.message, 'Your forum account is banned.');
    });

    test('falls back to generic message when not banned and no message', () {
      final status = SiteStatus.fromUserStatusJson({
        'canAccess': false,
        'isBanned': false,
      });
      expect(status.message, 'You do not have access at this time.');
    });

    test('uses error field when message is absent', () {
      final status = SiteStatus.fromUserStatusJson({
        'canAccess': false,
        'isBanned': false,
        'error': 'Account suspended.',
      });
      expect(status.message, 'Account suspended.');
    });

    test('explicit message takes precedence over error', () {
      final status = SiteStatus.fromUserStatusJson({
        'canAccess': true,
        'isBanned': false,
        'message': 'Hello',
        'error': 'Should not be used',
      });
      expect(status.message, 'Hello');
    });
  });

  group('SiteStatus.fromClosedJson', () {
    test('isClosed true when isWebsiteClosed is 1', () {
      final status = SiteStatus.fromClosedJson({
        'isWebsiteClosed': 1,
        'siteMessage': 'Down for maintenance.',
      });
      expect(status.isClosed, isTrue);
      expect(status.canAccess, isFalse);
      expect(status.isBanned, isFalse);
      expect(status.message, 'Down for maintenance.');
    });

    test('isClosed true when isWebsiteClosed is true', () {
      final status = SiteStatus.fromClosedJson({'isWebsiteClosed': true});
      expect(status.isClosed, isTrue);
      expect(status.canAccess, isFalse);
    });

    test('isClosed false when isWebsiteClosed is 0', () {
      final status = SiteStatus.fromClosedJson({
        'isWebsiteClosed': 0,
        'siteMessage': '',
      });
      expect(status.isClosed, isFalse);
      expect(status.canAccess, isTrue);
    });

    test('isClosed false when isWebsiteClosed is false', () {
      final status = SiteStatus.fromClosedJson({'isWebsiteClosed': false});
      expect(status.isClosed, isFalse);
      expect(status.canAccess, isTrue);
    });

    test('message is null when siteMessage is absent', () {
      final status = SiteStatus.fromClosedJson({'isWebsiteClosed': 0});
      expect(status.message, isNull);
    });
  });
}

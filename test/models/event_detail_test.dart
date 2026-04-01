import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/models/event_detail.dart';

void main() {
  group('EventDetail', () {
    test('parses typed boolean getters', () {
      final event = EventDetail.fromJson({
        'secureChanging': 1,
        'blasters': 0,
        'lightsabers': 1,
        'parking': 1,
        'mobility': 0,
      });
      expect(event.secureChanging, isTrue);
      expect(event.blasters, isFalse);
      expect(event.lightsabers, isTrue);
      expect(event.parking, isTrue);
      expect(event.mobility, isFalse);
    });

    test('isClosed is true for closed values 2, 3, 4', () {
      for (final v in [2, 3, 4]) {
        expect(EventDetail.fromJson({'closed': v}).isClosed, isTrue,
            reason: 'closed=$v should be closed');
      }
    });

    test('isClosed is false for open values', () {
      expect(EventDetail.fromJson({'closed': 0}).isClosed, isFalse);
      expect(EventDetail.fromJson({}).isClosed, isFalse);
    });

    test('isManualSelection detects manualselection string', () {
      expect(
        EventDetail.fromJson({'closed': 'manualselection'}).isManualSelection,
        isTrue,
      );
      expect(
        EventDetail.fromJson({'closed': 'MANUALSELECTION'}).isManualSelection,
        isTrue,
      );
      expect(
        EventDetail.fromJson({'closed': 0}).isManualSelection,
        isFalse,
      );
    });

    test('guestsAllowed is true when null (unlimited)', () {
      expect(EventDetail.fromJson({}).guestsAllowed, isTrue);
    });

    test('guestsAllowed is false when 0', () {
      expect(EventDetail.fromJson({'guests_allowed': 0}).guestsAllowed, isFalse);
    });

    test('shifts defaults to empty list', () {
      expect(EventDetail.fromJson({}).shifts, isEmpty);
    });

    test('isInFuture returns false for past date', () {
      final event = EventDetail.fromJson({'dateEnd': '2000-01-01 00:00:00'});
      expect(event.isInFuture, isFalse);
    });

    test('isInFuture returns true for future date', () {
      final event = EventDetail.fromJson({'dateEnd': '2099-12-31 23:59:59'});
      expect(event.isInFuture, isTrue);
    });
  });
}

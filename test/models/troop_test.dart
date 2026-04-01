import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/models/troop.dart';

void main() {
  group('Troop.fromJson', () {
    test('parses all fields', () {
      final json = {
        'troopid': 123,
        'name': 'Holiday Parade',
        'dateStart': '2025-12-01 09:00:00',
        'dateEnd': '2025-12-01 14:00:00',
        'squad': 2,
        'link': 1,
        'notice': 'Limited slots',
        'trooper_count': 12,
        'my_shifts': [
          {'display': 'Morning', 'status': 'going'},
        ],
      };
      final troop = Troop.fromJson(json);
      expect(troop.id, 123);
      expect(troop.name, 'Holiday Parade');
      expect(troop.squad, 2);
      expect(troop.hasLink, isTrue);
      expect(troop.notice, 'Limited slots');
      expect(troop.trooperCount, 12);
      expect(troop.myShifts.length, 1);
      expect(troop.myShifts.first['display'], 'Morning');
    });

    test('hasLink is false when link is 0', () {
      final troop = Troop.fromJson({'troopid': 1, 'name': 'Test', 'link': 0});
      expect(troop.hasLink, isFalse);
    });

    test('hasLink is false when link is null', () {
      final troop = Troop.fromJson({'troopid': 1, 'name': 'Test'});
      expect(troop.hasLink, isFalse);
    });

    test('my_shifts defaults to empty list', () {
      final troop = Troop.fromJson({'troopid': 1, 'name': 'Test'});
      expect(troop.myShifts, isEmpty);
    });
  });
}

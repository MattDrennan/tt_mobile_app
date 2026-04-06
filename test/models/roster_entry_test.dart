import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/models/roster_entry.dart';

Map<String, dynamic> _fullJson({int? shiftId = 1}) => {
      'status_formatted': 'Going',
      'trooper_name': 'Luke Skywalker',
      'tkid_formatted': 'TK-12345',
      'costume_name': 'Stormtrooper',
      'backup_costume_name': 'Scout Trooper',
      'signuptime': '2024-06-01 10:00:00',
      'shift_id': shiftId,
    };

void main() {
  group('RosterEntry.fromJson', () {
    test('parses all fields correctly', () {
      final entry = RosterEntry.fromJson(_fullJson());
      expect(entry.statusFormatted, 'Going');
      expect(entry.trooperName, 'Luke Skywalker');
      expect(entry.tkidFormatted, 'TK-12345');
      expect(entry.costumeName, 'Stormtrooper');
      expect(entry.backupCostumeName, 'Scout Trooper');
      expect(entry.signupTime, '2024-06-01 10:00:00');
      expect(entry.shiftId, 1);
    });

    test('shiftId is null when missing', () {
      final entry = RosterEntry.fromJson(_fullJson(shiftId: null));
      expect(entry.shiftId, isNull);
    });

    test('falls back to empty strings on missing fields', () {
      final entry = RosterEntry.fromJson({});
      expect(entry.statusFormatted, '');
      expect(entry.trooperName, '');
      expect(entry.tkidFormatted, '');
      expect(entry.costumeName, '');
      expect(entry.backupCostumeName, '');
      expect(entry.signupTime, '');
      expect(entry.shiftId, isNull);
    });

    test('handles null values gracefully', () {
      final entry = RosterEntry.fromJson({
        'status_formatted': null,
        'trooper_name': null,
        'tkid_formatted': null,
        'costume_name': null,
        'backup_costume_name': null,
        'signuptime': null,
        'shift_id': null,
      });
      expect(entry.statusFormatted, '');
      expect(entry.shiftId, isNull);
    });

    test('handles shiftId as double', () {
      final entry = RosterEntry.fromJson({..._fullJson(), 'shift_id': 3.0});
      expect(entry.shiftId, 3);
    });
  });
}

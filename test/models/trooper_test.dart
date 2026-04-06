import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/models/trooper.dart';

void main() {
  group('Trooper.fromJson', () {
    test('parses all fields', () {
      final trooper = Trooper.fromJson({
        'id': 42,
        'display_name': 'Han Solo',
        'tkid_formatted': 'TK-42000',
      });
      expect(trooper.id, 42);
      expect(trooper.name, 'Han Solo');
      expect(trooper.tkid, 'TK-42000');
    });

    test('handles numeric id as double', () {
      final trooper = Trooper.fromJson({
        'id': 7.0,
        'display_name': 'Leia',
        'tkid_formatted': 'TK-7',
      });
      expect(trooper.id, 7);
    });

    test('falls back to empty strings on missing fields', () {
      final trooper = Trooper.fromJson({'id': 1});
      expect(trooper.name, '');
      expect(trooper.tkid, '');
    });

    test('handles null display_name and tkid', () {
      final trooper = Trooper.fromJson({
        'id': 1,
        'display_name': null,
        'tkid_formatted': null,
      });
      expect(trooper.name, '');
      expect(trooper.tkid, '');
    });
  });

  group('Trooper.toString', () {
    test('returns name and tkid separated by " - "', () {
      final trooper = Trooper(id: 1, name: 'Luke', tkid: 'TK-1138');
      expect(trooper.toString(), 'Luke - TK-1138');
    });

    test('handles empty fields gracefully', () {
      final trooper = Trooper(id: 0, name: '', tkid: '');
      expect(trooper.toString(), ' - ');
    });
  });
}

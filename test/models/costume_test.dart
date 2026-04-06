import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/models/costume.dart';

void main() {
  group('Costume.fromJson', () {
    test('parses id and concatenates abbreviation with name', () {
      final costume = Costume.fromJson({
        'id': 5,
        'abbreviation': 'TK-',
        'name': 'Stormtrooper',
      });
      expect(costume.id, 5);
      expect(costume.name, 'TK-Stormtrooper');
    });

    test('handles missing abbreviation', () {
      final costume = Costume.fromJson({
        'id': 1,
        'abbreviation': null,
        'name': 'Vader',
      });
      expect(costume.name, 'Vader');
    });

    test('handles missing name', () {
      final costume = Costume.fromJson({
        'id': 2,
        'abbreviation': 'DT-',
        'name': null,
      });
      expect(costume.name, 'DT-');
    });

    test('handles both abbreviation and name missing', () {
      final costume = Costume.fromJson({'id': 3});
      expect(costume.name, '');
    });

    test('handles numeric id as double', () {
      final costume = Costume.fromJson({
        'id': 7.0,
        'abbreviation': '',
        'name': 'Scout',
      });
      expect(costume.id, 7);
    });
  });

  group('Costume.toString', () {
    test('returns the name', () {
      final costume = Costume(id: 1, name: 'Stormtrooper');
      expect(costume.toString(), 'Stormtrooper');
    });

    test('returns empty string when name is empty', () {
      final costume = Costume(id: 1, name: '');
      expect(costume.toString(), '');
    });
  });
}

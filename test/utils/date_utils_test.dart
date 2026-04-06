import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/utils/date_utils.dart';

void main() {
  group('formatDate', () {
    test('formats a valid ISO date string', () {
      final result = formatDate('2024-06-15');
      expect(result, 'Jun 15, 2024');
    });

    test('formats a date with time component', () {
      final result = formatDate('2024-01-01 00:00:00');
      expect(result, 'Jan 1, 2024');
    });

    test('formats a date at end of year', () {
      final result = formatDate('2024-12-31');
      expect(result, 'Dec 31, 2024');
    });

    test('returns original string on invalid input', () {
      final result = formatDate('not-a-date');
      expect(result, 'not-a-date');
    });

    test('returns original string on empty input', () {
      final result = formatDate('');
      // Empty string throws a FormatException → returns ''
      expect(result, '');
    });
  });

  group('formatDateWithTime', () {
    test('formats a valid start/end datetime pair', () {
      final result = formatDateWithTime(
        '2024-06-15 09:00:00',
        '2024-06-15 17:30:00',
      );
      // Expected: "Jun 15, 2024 9:00 AM to 5:30 PM"
      expect(result, contains('Jun 15, 2024'));
      expect(result, contains('9:00 AM'));
      expect(result, contains('5:30 PM'));
      expect(result, contains(' to '));
    });

    test('formats midnight correctly', () {
      final result = formatDateWithTime(
        '2024-03-01 00:00:00',
        '2024-03-01 12:00:00',
      );
      expect(result, contains('12:00 AM'));
      expect(result, contains('12:00 PM'));
    });

    test('returns start string on invalid start date', () {
      final result = formatDateWithTime('bad-start', '2024-01-01');
      expect(result, 'bad-start');
    });

    test('returns "Invalid date" when start is empty and dates are invalid',
        () {
      final result = formatDateWithTime('', 'also-bad');
      expect(result, 'Invalid date');
    });

    test('returns start string when end is invalid but start is not empty', () {
      final result = formatDateWithTime('some-start', 'bad-end');
      expect(result, 'some-start');
    });
  });
}

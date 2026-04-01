import 'package:intl/intl.dart';

/// Formats a date string to 'MMM d, y' (e.g., "Mar 15, 2025").
String formatDate(String dateStr) {
  try {
    final parsedDate = DateTime.parse(dateStr);
    return DateFormat('MMM d, y').format(parsedDate);
  } catch (e) {
    return dateStr;
  }
}

/// Formats a start/end datetime pair to 'MMM d, y h:mm a to h:mm a'.
String formatDateWithTime(String start, String end) {
  try {
    final startDate = DateTime.parse(start);
    final endDate = DateTime.parse(end);
    final formattedStart = DateFormat('MMM d, y h:mm a').format(startDate);
    final formattedEnd = DateFormat('h:mm a').format(endDate);
    return '$formattedStart to $formattedEnd';
  } catch (e) {
    return start.isNotEmpty ? start : 'Invalid date';
  }
}

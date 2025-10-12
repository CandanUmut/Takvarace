import 'package:intl/intl.dart';

class TimeUtils {
  static String formatDuration(Duration duration, String locale) {
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    final buffer = StringBuffer();
    if (days > 0) {
      buffer.write('$days ');
      buffer.write(_localizedUnit('days', locale));
    }
    if (hours > 0) {
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write('$hours ');
      buffer.write(_localizedUnit('hours', locale));
    }
    if (minutes >= 0) {
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write('$minutes ');
      buffer.write(_localizedUnit('minutes', locale));
    }
    return buffer.toString().trim();
  }

  static String formatDate(DateTime date, String locale) {
    return DateFormat.yMMMMd(locale).format(date);
  }

  static String _localizedUnit(String unit, String locale) {
    if (locale.startsWith('tr')) {
      switch (unit) {
        case 'days':
          return 'gün';
        case 'hours':
          return 'saat';
        case 'minutes':
          return 'dakika';
      }
    }
    switch (unit) {
      case 'days':
        return 'days';
      case 'hours':
        return 'hours';
      case 'minutes':
        return 'minutes';
      default:
        return unit;
    }
  }
}

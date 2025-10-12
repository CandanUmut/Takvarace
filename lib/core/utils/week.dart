class WeekUtils {
  static DateTime weekStart(DateTime date) {
    final day = date.weekday;
    final diff = day == DateTime.monday ? 0 : day - DateTime.monday;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: diff));
  }

  static String formatWeekKey(DateTime date) {
    final start = weekStart(date);
    return '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
  }
}

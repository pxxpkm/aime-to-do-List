class DateUtils {
  static int daysUntil(DateTime deadline) {
    final now = DateTime.now();
    final deadlineDate = DateTime(deadline.year, deadline.month, deadline.day);
    final nowDate = DateTime(now.year, now.month, now.day);
    return deadlineDate.difference(nowDate).inDays;
  }

  static String formatCountdown(DateTime deadline) {
    final days = daysUntil(deadline);
    if (days < 0) return '已逾期';
    if (days == 0) return '今天';
    if (days == 1) return '明天';
    return '還有 $days 天';
  }

  static String formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}

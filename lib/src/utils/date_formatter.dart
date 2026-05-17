/// Formats a `DateTime` as `yyMMddHHmmssSSS` in UTC, matching the format the
/// Moamalat PayLink gateway expects for `DateTimeLocalTrxn`.
class DateFormatter {
  const DateFormatter._();

  static String now() => format(DateTime.now().toUtc());

  static String format(DateTime dateTime) {
    final utc = dateTime.toUtc();
    return '${_two(utc.year % 100)}'
        '${_two(utc.month)}'
        '${_two(utc.day)}'
        '${_two(utc.hour)}'
        '${_two(utc.minute)}'
        '${_two(utc.second)}'
        '${utc.millisecond.toString().padLeft(3, '0')}';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}

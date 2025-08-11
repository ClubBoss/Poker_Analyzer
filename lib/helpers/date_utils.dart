import 'package:intl/intl.dart';

String? _locale;
DateFormat? _dateTimeFmt;
DateFormat? _dateFmt;
DateFormat? _longDateFmt;

String _currentLocale() {
  final locale = Intl.getCurrentLocale();
  if (_locale != locale) {
    _locale = locale;
    _dateTimeFmt = null;
    _dateFmt = null;
    _longDateFmt = null;
  }
  return locale;
}

DateFormat get _dateTimeFormat =>
    _dateTimeFmt ??= DateFormat('dd.MM.yyyy HH:mm', _currentLocale());
DateFormat get _dateFormat =>
    _dateFmt ??= DateFormat('dd.MM.yyyy', _currentLocale());
DateFormat get _longDateFormat =>
    _longDateFmt ??= DateFormat('d MMMM y', _currentLocale());

String formatDateTime(DateTime date) {
  return _dateTimeFormat.format(date);
}

String formatDate(DateTime date) {
  return _dateFormat.format(date);
}

String formatLongDate(DateTime date) {
  return _longDateFormat.format(date);
}

String formatDuration(Duration d) {
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60);
  final parts = <String>[];
  if (hours > 0) parts.add('$hoursч');
  parts.add('$minutesм');
  return parts.join(' ');
}

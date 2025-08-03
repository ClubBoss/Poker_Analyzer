import 'package:intl/intl.dart';

String? _locale;

String _currentLocale() => _locale ??= Intl.getCurrentLocale();

late final DateFormat _dateTimeFmt =
    DateFormat('dd.MM.yyyy HH:mm', _currentLocale());
late final DateFormat _dateFmt =
    DateFormat('dd.MM.yyyy', _currentLocale());
late final DateFormat _longDateFmt =
    DateFormat('d MMMM y', _currentLocale());

String formatDateTime(DateTime date) {
  return _dateTimeFmt.format(date);
}

String formatDate(DateTime date) {
  return _dateFmt.format(date);
}

String formatLongDate(DateTime date) {
  return _longDateFmt.format(date);
}

String formatDuration(Duration d) {
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60);
  final parts = <String>[];
  if (hours > 0) parts.add('${hours}ч');
  parts.add('${minutes}м');
  return parts.join(' ');
}

import 'package:intl/intl.dart';

String? _locale;

String _currentLocale() => _locale ??= Intl.getCurrentLocale();

String formatDateTime(DateTime date) {
  return DateFormat('dd.MM.yyyy HH:mm', _currentLocale()).format(date);
}

String formatDate(DateTime date) {
  return DateFormat('dd.MM.yyyy', _currentLocale()).format(date);
}

String formatLongDate(DateTime date) {
  return DateFormat('d MMMM y', _currentLocale()).format(date);
}

String formatDuration(Duration d) {
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60);
  final parts = <String>[];
  if (hours > 0) parts.add('${hours}ч');
  parts.add('${minutes}м');
  return parts.join(' ');
}

String shortTime(DateTime date) {
  return DateFormat('HH:mm', _currentLocale()).format(date);
}

String timeDiff(DateTime prev, DateTime next) {
  final diffMs = next.difference(prev).inMilliseconds;
  final diffSec = diffMs / 1000;
  final value = diffSec % 1 == 0
      ? diffSec.toInt().toString()
      : diffSec.toStringAsFixed(1);
  return '+$value';
}

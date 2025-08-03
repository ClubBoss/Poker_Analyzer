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

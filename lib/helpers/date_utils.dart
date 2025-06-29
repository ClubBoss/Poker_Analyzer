import 'package:intl/intl.dart';

String formatDateTime(DateTime date) {
  final locale = Intl.getCurrentLocale();
  return DateFormat('dd.MM.yyyy HH:mm', locale).format(date);
}

String formatDate(DateTime date) {
  final locale = Intl.getCurrentLocale();
  return DateFormat('dd.MM.yyyy', locale).format(date);
}

String formatLongDate(DateTime date) {
  final locale = Intl.getCurrentLocale();
  return DateFormat('d MMMM y', locale).format(date);
}

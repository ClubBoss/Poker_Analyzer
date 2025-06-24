import 'package:intl/intl.dart';

String formatDateTime(DateTime date) {
  return DateFormat('dd.MM.yyyy HH:mm').format(date);
}

String formatDate(DateTime date) {
  return DateFormat('dd.MM.yyyy').format(date);
}

String formatLongDate(DateTime date) {
  return DateFormat('d MMMM y', 'ru').format(date);
}

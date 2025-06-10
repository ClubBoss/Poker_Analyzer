import 'package:intl/intl.dart';

String formatDateTime(DateTime date) {
  return DateFormat('dd.MM.yyyy HH:mm').format(date);
}

String formatDate(DateTime date) {
  return DateFormat('dd.MM.yyyy').format(date);
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String _locale(BuildContext? context) {
  return context != null
      ? Localizations.localeOf(context).toLanguageTag()
      : Intl.getCurrentLocale();
}

String formatDateTime(DateTime date, {BuildContext? context}) {
  return DateFormat('dd.MM.yyyy HH:mm', _locale(context)).format(date);
}

String formatDate(DateTime date, {BuildContext? context}) {
  return DateFormat('dd.MM.yyyy', _locale(context)).format(date);
}

String formatLongDate(DateTime date, {BuildContext? context}) {
  return DateFormat('d MMMM y', _locale(context)).format(date);
}

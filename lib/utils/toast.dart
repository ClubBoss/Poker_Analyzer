import 'package:flutter/material.dart';

void showToast(
  BuildContext context,
  String msg, {
  Duration duration = const Duration(seconds: 2),
}) {
  final m = ScaffoldMessenger.of(context);
  m.clearSnackBars();
  m.showSnackBar(SnackBar(content: Text(msg), duration: duration));
}

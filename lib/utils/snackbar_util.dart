import 'package:flutter/material.dart';

class SnackbarUtil {
  const SnackbarUtil._();

  static void showMessage(BuildContext ctx, String text, {SnackBarAction? action}) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(content: Text(text), action: action),
    );
  }
}

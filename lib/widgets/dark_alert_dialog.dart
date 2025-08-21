import 'package:flutter/material.dart';

class DarkAlertDialog extends StatelessWidget {
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? contentPadding;
  final EdgeInsetsGeometry? insetPadding;
  final ShapeBorder? shape;
  final Color? backgroundColor;

  const DarkAlertDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.contentPadding,
    this.insetPadding,
    this.shape,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: backgroundColor ?? Colors.grey[900],
      titleTextStyle: const TextStyle(color: Colors.white),
      contentTextStyle: const TextStyle(color: Colors.white70),
      shape: shape ??
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding:
          contentPadding ?? const EdgeInsets.fromLTRB(24, 20, 24, 24),
      insetPadding: insetPadding,
      title: title,
      content: content,
      actions: actions,
    );
  }
}

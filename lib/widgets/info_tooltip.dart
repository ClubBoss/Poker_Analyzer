import 'package:flutter/material.dart';

class InfoTooltip extends StatelessWidget {
  final Widget child;
  final String message;
  const InfoTooltip({required this.child, required this.message, super.key});

  @override
  Widget build(BuildContext context) => Tooltip(message: message, child: child);
}

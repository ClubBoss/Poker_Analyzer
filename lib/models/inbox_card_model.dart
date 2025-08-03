import 'package:flutter/widgets.dart';

/// Represents a simple card entry in the user's inbox.
class InboxCardModel {
  final String id;
  final String title;
  final String subtitle;
  final void Function(BuildContext) onTap;

  InboxCardModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}


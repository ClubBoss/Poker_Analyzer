import 'package:flutter/material.dart';

class CurrentHandContextService {
  String? _currentHandName;
  String? get currentHandName => _currentHandName;
  set currentHandName(String? value) => _currentHandName = value;

  final TextEditingController commentController = TextEditingController();
  final TextEditingController tagsController = TextEditingController();
  final Map<int, String?> actionTags = {};

  void clear() {
    _currentHandName = null;
    commentController.clear();
    tagsController.clear();
    actionTags.clear();
  }

  void dispose() {
    commentController.dispose();
    tagsController.dispose();
  }
}

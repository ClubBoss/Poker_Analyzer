import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'saved_hand_manager_service.dart';

/// Handles importing external hand history files using available converters.
class HandHistoryFileService {
  HandHistoryFileService._(this._handManager);

  static Future<HandHistoryFileService> create(
      SavedHandManagerService manager) async {
    return HandHistoryFileService._(manager);
  }

  final SavedHandManagerService _handManager;

  /// Prompts the user to select hand history files and imports them.
  Future<int> importFromFiles(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null || result.files.isEmpty) return 0;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Не удалось импортировать файлы")),
      );
    }
    return 0;
  }
}

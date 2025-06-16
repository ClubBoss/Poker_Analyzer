import 'package:flutter/material.dart';

class CurrentHandContextService {
  String? _currentHandName;

  /// Name of the currently loaded hand. `null` when no hand is loaded.
  String? get currentHandName => _currentHandName;
  set currentHandName(String? value) => _currentHandName = value;

  /// Text field controllers shared with the UI.
  final TextEditingController commentController = TextEditingController();
  final TextEditingController tagsController = TextEditingController();

  /// Current comment text or `null` if empty.
  String? get comment =>
      commentController.text.isNotEmpty ? commentController.text : null;

  set comment(String? value) => commentController.text = value ?? '';

  /// Cursor position inside the comment field.
  int? get commentCursor => commentController.selection.baseOffset >= 0
      ? commentController.selection.baseOffset
      : null;

  set commentCursor(int? offset) {
    commentController.selection = TextSelection.collapsed(
      offset: offset != null && offset <= commentController.text.length
          ? offset
          : commentController.text.length,
    );
  }

  /// Tags entered by the user.
  List<String> get tags => tagsController.text
      .split(',')
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toList();

  set tags(List<String> value) => tagsController.text = value.join(', ');

  /// Cursor offset inside the tag field.
  int? get tagsCursor => tagsController.selection.baseOffset >= 0
      ? tagsController.selection.baseOffset
      : null;

  set tagsCursor(int? offset) {
    tagsController.selection = TextSelection.collapsed(
      offset:
          offset != null && offset <= tagsController.text.length ? offset : tagsController.text.length,
    );
  }

  /// Reset all fields to their initial state.
  void clear() {
    _currentHandName = null;
    commentController.clear();
    tagsController.clear();
  }

  /// Restore context from persisted data.
  void restore({
    String? name,
    String? comment,
    int? commentCursor,
    List<String>? tags,
    int? tagsCursor,
  }) {
    _currentHandName = name;
    this.comment = comment;
    this.tags = tags ?? <String>[];
    this.commentCursor = commentCursor;
    this.tagsCursor = tagsCursor;
  }

  void dispose() {
    commentController.dispose();
    tagsController.dispose();
  }
}

import 'package:flutter/material.dart';

import '../models/saved_hand.dart';

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

  /// Restore context directly from a [SavedHand].
  void restoreFromHand(SavedHand hand) {
    restore(
      name: hand.name,
      comment: hand.comment,
      commentCursor: hand.commentCursor,
      tags: hand.tags,
      tagsCursor: hand.tagsCursor,
    );
  }

  /// Apply the current context values to an existing [SavedHand].
  SavedHand applyTo(SavedHand hand) {
    return hand.copyWith(
      name: _currentHandName ?? hand.name,
      comment: comment,
      tags: tags,
      commentCursor: commentCursor,
      tagsCursor: tagsCursor,
    );
  }

  /// Clear only the name of the current hand.
  void clearName() {
    _currentHandName = null;
  }

  void dispose() {
    commentController.dispose();
    tagsController.dispose();
  }
}

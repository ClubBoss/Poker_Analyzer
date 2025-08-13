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
  final TextEditingController tournamentIdController = TextEditingController();
  final TextEditingController buyInController = TextEditingController();
  final TextEditingController totalPrizePoolController =
      TextEditingController();
  final TextEditingController numberOfEntrantsController =
      TextEditingController();
  final TextEditingController gameTypeController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();

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

  String? get tournamentId => tournamentIdController.text.isNotEmpty
      ? tournamentIdController.text
      : null;
  set tournamentId(String? value) => tournamentIdController.text = value ?? '';

  int? get buyIn => int.tryParse(buyInController.text);
  set buyIn(int? value) => buyInController.text = value?.toString() ?? '';

  int? get totalPrizePool => int.tryParse(totalPrizePoolController.text);
  set totalPrizePool(int? value) =>
      totalPrizePoolController.text = value?.toString() ?? '';

  int? get numberOfEntrants => int.tryParse(numberOfEntrantsController.text);
  set numberOfEntrants(int? value) =>
      numberOfEntrantsController.text = value?.toString() ?? '';

  String? get gameType =>
      gameTypeController.text.isNotEmpty ? gameTypeController.text : null;
  set gameType(String? value) => gameTypeController.text = value ?? '';

  String? get category =>
      categoryController.text.isNotEmpty ? categoryController.text : null;
  set category(String? value) => categoryController.text = value ?? '';

  /// Cursor offset inside the tag field.
  int? get tagsCursor => tagsController.selection.baseOffset >= 0
      ? tagsController.selection.baseOffset
      : null;

  set tagsCursor(int? offset) {
    tagsController.selection = TextSelection.collapsed(
      offset: offset != null && offset <= tagsController.text.length
          ? offset
          : tagsController.text.length,
    );
  }

  /// Reset all fields to their initial state.
  void clear() {
    _currentHandName = null;
    commentController.clear();
    tagsController.clear();
    tournamentIdController.clear();
    buyInController.clear();
    totalPrizePoolController.clear();
    numberOfEntrantsController.clear();
    gameTypeController.clear();
    categoryController.clear();
  }

  /// Restore context from persisted data.
  void restore({
    String? name,
    String? comment,
    int? commentCursor,
    List<String>? tags,
    int? tagsCursor,
    String? tournamentId,
    int? buyIn,
    int? totalPrizePool,
    int? numberOfEntrants,
    String? gameType,
    String? category,
  }) {
    _currentHandName = name;
    this.comment = comment;
    this.tags = tags ?? <String>[];
    this.commentCursor = commentCursor;
    this.tagsCursor = tagsCursor;
    this.tournamentId = tournamentId;
    this.buyIn = buyIn;
    this.totalPrizePool = totalPrizePool;
    this.numberOfEntrants = numberOfEntrants;
    this.gameType = gameType;
    this.category = category;
  }

  /// Restore context directly from a [SavedHand].
  void restoreFromHand(SavedHand hand) {
    restore(
      name: hand.name,
      comment: hand.comment,
      commentCursor: hand.commentCursor,
      tags: hand.tags,
      tagsCursor: hand.tagsCursor,
      tournamentId: hand.tournamentId,
      buyIn: hand.buyIn,
      totalPrizePool: hand.totalPrizePool,
      numberOfEntrants: hand.numberOfEntrants,
      gameType: hand.gameType,
      category: hand.category,
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
      tournamentId: tournamentId,
      buyIn: buyIn,
      totalPrizePool: totalPrizePool,
      numberOfEntrants: numberOfEntrants,
      gameType: gameType,
      category: category,
    );
  }

  /// Clear only the name of the current hand.
  void clearName() {
    _currentHandName = null;
  }

  void dispose() {
    commentController.dispose();
    tagsController.dispose();
    tournamentIdController.dispose();
    buyInController.dispose();
    totalPrizePoolController.dispose();
    numberOfEntrantsController.dispose();
    gameTypeController.dispose();
    categoryController.dispose();
  }
}

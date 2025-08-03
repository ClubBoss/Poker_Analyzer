import 'package:flutter/material.dart';

import '../models/card_model.dart';
import '../services/dynamic_board_tagger_service.dart';

/// Renders a horizontal list of board texture tags.
class BoardTagPreviewRenderer extends StatelessWidget {
  const BoardTagPreviewRenderer({super.key, required this.board});

  /// The board cards to analyse.
  final List<CardModel> board;

  static const _highlighted = {'paired', 'wet', 'aceHigh', 'rainbow'};

  @override
  Widget build(BuildContext context) {
    final tags = DynamicBoardTaggerService().tag(board).toList()..sort();
    if (tags.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final t in tags)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Chip(
                label: Text(t),
                backgroundColor: _highlighted.contains(t)
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}

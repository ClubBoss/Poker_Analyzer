import 'dart:async';

import 'package:flutter/material.dart';

import '../models/training_spot.dart';
import '../models/action_entry.dart';
import 'board_cards_widget.dart';
import 'playback_progress_bar.dart';
import 'poker_table_painter.dart';
import 'training_spot_diagram.dart';

/// Simple hand replay widget for [TrainingSpot].
class ReplaySpotWidget extends StatefulWidget {
  final TrainingSpot spot;
  const ReplaySpotWidget({super.key, required this.spot});

  @override
  State<ReplaySpotWidget> createState() => _ReplaySpotWidgetState();
}

class _ReplaySpotWidgetState extends State<ReplaySpotWidget> {
  late int _index;
  bool _isPlaying = false;
  Timer? _timer;

  List<ActionEntry> get _currentActions =>
      widget.spot.actions.take(_index).toList();

  @override
  void initState() {
    super.initState();
    _index = 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _play() {
    _timer?.cancel();
    setState(() => _isPlaying = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_index < widget.spot.actions.length) {
        setState(() => _index++);
      } else {
        _pause();
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _isPlaying = false);
  }

  void _toggle() {
    if (_isPlaying) {
      _pause();
    } else {
      _play();
    }
  }

  void _seek(int value) {
    _timer?.cancel();
    setState(() {
      _index = value.clamp(0, widget.spot.actions.length);
      _isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final street = _currentActions.isNotEmpty ? _currentActions.last.street : 0;

    // Build a copy of spot with subset of actions.
    final json = widget.spot.toJson();
    json['actions'] = [
      for (final a in _currentActions)
        {
          'street': a.street,
          'playerIndex': a.playerIndex,
          'action': a.action,
          if (a.amount != null) 'amount': a.amount,
          if (a.manualEvaluation != null) 'manualEvaluation': a.manualEvaluation,
        }
    ];
    final subset = TrainingSpot.fromJson(json);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 260,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: PokerTablePainter(),
                  ),
                ),
                TrainingSpotDiagram(
                  spot: subset,
                  size: 220,
                ),
                Positioned.fill(
                  child: BoardCardsWidget(
                    currentStreet: street,
                    boardCards: widget.spot.boardCards,
                    onCardSelected: (_, __) {},
                    usedCards: const {},
                    editingDisabled: true,
                  ),
                ),
              ],
            ),
          ),
          PlaybackProgressBar(
            playbackIndex: _index,
            actionCount: widget.spot.actions.length,
            onSeek: _seek,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Chip(
              label: Text(widget.spot.positions[widget.spot.heroIndex]),
              backgroundColor:
                  Theme.of(context).colorScheme.secondary,
              labelStyle: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _toggle,
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              ),
              IconButton(
                onPressed: () => _seek(0),
                icon: const Icon(Icons.restart_alt),
              ),
            ],
          )
        ],
      ),
    );
  }
}

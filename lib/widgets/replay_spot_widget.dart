import 'dart:async';

import 'package:flutter/material.dart';
import 'package:poker_analyzer/ui/padding_constants.dart';

import '../models/training_spot.dart';
import '../models/action_entry.dart';
import 'board_cards_widget.dart';
import 'playback_progress_bar.dart';
import 'poker_table_painter.dart';
import 'training_spot_diagram.dart';
import 'ev_loss_bar.dart';

/// Simple hand replay widget for [TrainingSpot].
class ReplaySpotWidget extends StatefulWidget {
  final TrainingSpot spot;
  final String? expectedAction;
  final String? gtoAction;
  final double? evLoss;
  final String? feedbackText;

  const ReplaySpotWidget({
    super.key,
    required this.spot,
    this.expectedAction,
    this.gtoAction,
    this.evLoss,
    this.feedbackText,
  });

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

  Future<void> _showGto() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Оптимальное действие'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.gtoAction != null)
              Text(
                widget.gtoAction!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            if (widget.feedbackText != null) ...[
              const SizedBox(height: 8),
              Text(widget.feedbackText!),
            ],
            if ((widget.evLoss ?? 0) > 0.5) ...[
              const SizedBox(height: 8),
              Text('Потеря EV: -${widget.evLoss!.toStringAsFixed(1)} bb'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildComparison() {
    if (widget.expectedAction == null && widget.gtoAction == null) {
      return const SizedBox.shrink();
    }
    final highlight = (widget.evLoss ?? 0) > 0.5;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: kCardPadding,
      decoration: BoxDecoration(
        color: highlight
            ? Colors.redAccent.withValues(alpha: 0.2)
            : Colors.white10,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Вы выбрали',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.expectedAction ?? '-',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Оптимально',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.gtoAction ?? '-',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
          if (a.manualEvaluation != null)
            'manualEvaluation': a.manualEvaluation,
        },
    ];
    final subset = TrainingSpot.fromJson(json);

    return Padding(
      padding: kScreenPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildComparison(),
          SizedBox(
            height: 260,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: PokerTablePainter()),
                ),
                TrainingSpotDiagram(spot: subset, size: 220),
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
          EvLossBar(
            spot: widget.spot,
            playbackIndex: _index,
            totalEvLoss: widget.evLoss,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Chip(
              label: Text(widget.spot.positions[widget.spot.heroIndex]),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              labelStyle: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
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
          ),
          if (widget.gtoAction != null || widget.feedbackText != null) ...[
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _showGto,
              child: const Text('Показать GTO'),
            ),
          ],
        ],
      ),
    );
  }
}

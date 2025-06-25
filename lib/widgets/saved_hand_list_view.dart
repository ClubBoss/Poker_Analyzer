/// Displays a scrollable list of [SavedHand] items with optional filtering and summary counts.
///
/// The widget filters [hands] by [tags], [positions] and [accuracy] before
/// displaying them. [title] is shown above the list, and [onTap] is invoked
/// when a hand is tapped. If [onFavoriteToggle] is provided, each tile will
/// show a star button.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_hand.dart';
import '../models/mistake_severity.dart';
import '../theme/constants.dart';
import '../services/evaluation_executor_service.dart';
import '../helpers/mistake_advice.dart';
import 'saved_hand_tile.dart';

/// Internal enum for accuracy filter options.
enum _AccuracyFilter { all, errors, correct }

const _prefsAccuracyKey = 'saved_hand_accuracy_filter';

class SavedHandListView extends StatefulWidget {
  final List<SavedHand> hands;
  final Iterable<String>? tags;
  final Iterable<String>? positions;
  final String? initialAccuracy; // 'correct' or 'errors'
  final bool showAccuracyToggle;
  final String title;
  final ValueChanged<SavedHand> onTap;
  final ValueChanged<SavedHand>? onFavoriteToggle;
  final String? filterKey;

  const SavedHandListView({
    super.key,
    required this.hands,
    required this.title,
    required this.onTap,
    this.tags,
    this.positions,
    this.initialAccuracy,
    this.showAccuracyToggle = true,
    this.onFavoriteToggle,
    this.filterKey,
  });

  @override
  State<SavedHandListView> createState() => _SavedHandListViewState();
}

class _SavedHandListViewState extends State<SavedHandListView> {
  late _AccuracyFilter _accuracy;

  String _accuracyToString(_AccuracyFilter value) {
    switch (value) {
      case _AccuracyFilter.errors:
        return 'errors';
      case _AccuracyFilter.correct:
        return 'correct';
      case _AccuracyFilter.all:
      default:
        return 'all';
    }
  }

  Future<void> _loadAccuracy() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsAccuracyKey);
    if (stored != null && mounted) {
      setState(() => _accuracy = _parseAccuracy(stored));
    }
  }

  Future<void> _saveAccuracy(_AccuracyFilter value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsAccuracyKey, _accuracyToString(value));
  }

  @override
  void initState() {
    super.initState();
    _accuracy = _parseAccuracy(widget.initialAccuracy);
    _loadAccuracy();
  }

  @override
  void didUpdateWidget(covariant SavedHandListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialAccuracy != oldWidget.initialAccuracy) {
      _accuracy = _parseAccuracy(widget.initialAccuracy);
    }
    _loadAccuracy();
  }

  _AccuracyFilter _parseAccuracy(String? value) {
    switch (value) {
      case 'errors':
        return _AccuracyFilter.errors;
      case 'correct':
        return _AccuracyFilter.correct;
      default:
        return _AccuracyFilter.all;
    }
  }

  bool _matchesAccuracy(SavedHand h) {
    if (_accuracy == _AccuracyFilter.all) return true;
    final expected = h.expectedAction?.trim().toLowerCase();
    final gto = h.gtoAction?.trim().toLowerCase();
    if (expected == null || gto == null) return false;
    final equal = expected == gto;
    if (_accuracy == _AccuracyFilter.correct) return equal;
    if (_accuracy == _AccuracyFilter.errors) return !equal;
    return true;
  }

  List<SavedHand> _filtered() {
    return [
      for (final h in widget.hands)
        if ((widget.tags == null || widget.tags!.any(h.tags.contains)) &&
            (widget.positions == null ||
                widget.positions!.contains(h.heroPosition)) &&
            _matchesAccuracy(h))
          h
    ]..sort((a, b) => b.date.compareTo(a.date));
  }

  Map<String, int> _summary(List<SavedHand> list) {
    var correct = 0;
    var mistakes = 0;
    for (final h in list) {
      final expected = h.expectedAction?.trim().toLowerCase();
      final gto = h.gtoAction?.trim().toLowerCase();
      if (expected != null && gto != null) {
        if (expected == gto) {
          correct++;
        } else {
          mistakes++;
        }
      }
    }
    return {'correct': correct, 'mistakes': mistakes};
  }

  Widget _buildSummaryCard(BuildContext context, int mistakes) {
    final service = context.read<EvaluationExecutorService>();
    final severity = service.classifySeverity(mistakes);
    final advice =
        widget.filterKey != null ? kMistakeAdvice[widget.filterKey!] : null;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.padding16,
        vertical: 4,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(AppConstants.radius8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Colors.amberAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ошибок: $mistakes',
                    style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 2),
                Text('Уровень: ${severity.label}',
                    style: TextStyle(color: severity.color)),
                if (advice != null) ...[
                  const SizedBox(height: 4),
                  Text(advice,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyToggle() {
    if (!widget.showAccuracyToggle) return const SizedBox.shrink();
    const labels = {
      _AccuracyFilter.all: 'Все',
      _AccuracyFilter.errors: 'Только ошибки',
      _AccuracyFilter.correct: 'Только верные',
    };

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.padding16),
        children: [
          for (final entry in labels.entries)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(entry.value),
                selected: _accuracy == entry.key,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _accuracy = entry.key);
                    _saveAccuracy(entry.key);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered();
    final counts = _summary(filtered);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppConstants.padding16),
          child: Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: AppConstants.fontSize20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppConstants.padding16),
          child: Text(
            'Раздач: ${filtered.length} • Верно: ${counts['correct']} • Ошибки: ${counts['mistakes']}',
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        _buildAccuracyToggle(),
        if (widget.filterKey != null)
          _buildSummaryCard(context, counts['mistakes'] ?? 0),
        const SizedBox(height: 8),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text(
                    'Нет раздач',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.padding16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final hand = filtered[index];
                    return SavedHandTile(
                      hand: hand,
                      onTap: () => widget.onTap(hand),
                      onFavoriteToggle: widget.onFavoriteToggle == null
                          ? null
                          : () => widget.onFavoriteToggle!(hand),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

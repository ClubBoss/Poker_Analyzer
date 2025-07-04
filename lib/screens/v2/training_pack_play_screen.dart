import 'dart:convert';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/hand_utils.dart';
import '../../helpers/hand_type_utils.dart';

import '../../models/v2/training_pack_template.dart';
import '../../models/v2/training_pack_spot.dart';
import '../../widgets/spot_quiz_widget.dart';
import '../../widgets/common/explanation_text.dart';
import '../../theme/app_colors.dart';
import 'training_pack_result_screen.dart';
import '../../services/streak_service.dart';
import '../../services/notification_service.dart';

enum PlayOrder { sequential, random, mistakes }

class TrainingPackPlayScreen extends StatefulWidget {
  final TrainingPackTemplate template;
  final TrainingPackTemplate original;
  const TrainingPackPlayScreen({super.key, required this.template, TrainingPackTemplate? original})
      : original = original ?? template;

  @override
  State<TrainingPackPlayScreen> createState() => _TrainingPackPlayScreenState();
}

class _TrainingPackPlayScreenState extends State<TrainingPackPlayScreen> {
  late List<TrainingPackSpot> _spots;
  Map<String, String> _results = {};
  int _index = 0;
  bool _loading = true;
  PlayOrder _order = PlayOrder.sequential;
  int _streetCount = 0;
  final Map<String, int> _handCounts = {};
  final Map<String, int> _handTotals = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final seqKey = 'tpl_seq_${widget.template.id}';
    final progKey = 'tpl_prog_${widget.template.id}';
    final resKey = 'tpl_res_${widget.template.id}';
    final streetKey = 'tpl_street_${widget.template.id}';
    final handKey = 'tpl_hand_${widget.template.id}';
    final seq = prefs.getStringList(seqKey);
    var spots = List<TrainingPackSpot>.from(widget.template.spots);
    if (seq != null && seq.length == spots.length) {
      final map = {for (final s in spots) s.id: s};
      final ordered = <TrainingPackSpot>[];
      for (final id in seq) {
        final s = map[id];
        if (s != null) ordered.add(s);
      }
      if (ordered.length == spots.length) spots = ordered;
    }
    final resStr = prefs.getString(resKey);
    Map<String, String> results = {};
    if (resStr != null) {
      final data = jsonDecode(resStr);
      if (data is Map) {
        results = {for (final e in data.entries) e.key as String: e.value.toString()};
      }
    }
    int streetCount = 0;
    final handCounts = <String, int>{};
    _handTotals.clear();
    if (widget.template.targetStreet != null) {
      for (final id in results.keys) {
        final s = spots.firstWhereOrNull((e) => e.id == id);
        if (s != null && _matchStreet(s)) streetCount++;
      }
      streetCount = max(streetCount, prefs.getInt(streetKey) ?? 0);
    }
    if (widget.template.focusHandTypes.isNotEmpty) {
      for (final g in widget.template.focusHandTypes) {
        handCounts[g.label] = 0;
        for (final s in spots) {
          final code = handCode(s.hand.heroCards);
          if (code != null && matchHandTypeLabel(g.label, code)) {
            _handTotals[g.label] = (_handTotals[g.label] ?? 0) + 1;
          }
        }
      }
      for (final id in results.keys) {
        final s = spots.firstWhereOrNull((e) => e.id == id);
        if (s != null) {
          for (final g in widget.template.focusHandTypes) {
            final code = handCode(s.hand.heroCards);
            if (code != null && matchHandTypeLabel(g.label, code)) {
              handCounts[g.label] = (handCounts[g.label] ?? 0) + 1;
            }
          }
        }
      }
      final saved = prefs.getString(handKey);
      if (saved != null) {
        final data = jsonDecode(saved);
        if (data is Map) {
          for (final e in data.entries) {
            final k = e.key as String;
            final v = (e.value as num).toInt();
            if (handCounts.containsKey(k)) {
              handCounts[k] = max(handCounts[k] ?? 0, v);
            }
          }
        } else if (data is int && widget.template.focusHandTypes.isNotEmpty) {
          final k = widget.template.focusHandTypes.first.label;
          handCounts[k] = max(handCounts[k] ?? 0, data);
        }
      }
    }
    setState(() {
      _spots = spots;
      _results = results;
      _index = prefs.getInt(progKey)?.clamp(0, spots.length - 1) ?? 0;
      _streetCount = streetCount;
      _handCounts
        ..clear()
        ..addAll(handCounts);
      _loading = false;
    });
  }

  Future<void> _save({bool ts = true}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('tpl_seq_${widget.template.id}', [for (final s in _spots) s.id]);
    await prefs.setInt('tpl_prog_${widget.template.id}', _index);
    await prefs.setString('tpl_res_${widget.template.id}', jsonEncode(_results));
    if (widget.template.targetStreet != null) {
      await prefs.setInt('tpl_street_${widget.template.id}', _streetCount);
    }
    if (widget.template.focusHandTypes.isNotEmpty) {
      await prefs.setString('tpl_hand_${widget.template.id}', jsonEncode(_handCounts));
    }
    if (ts) {
      await prefs.setInt('tpl_ts_${widget.template.id}', DateTime.now().millisecondsSinceEpoch);
    }
  }

  void _startNew() {
    var spots = List<TrainingPackSpot>.from(widget.template.spots);
    if (_order == PlayOrder.random) {
      spots.shuffle();
    } else if (_order == PlayOrder.mistakes) {
      spots = spots.where((s) {
        final exp = _expected(s);
        final ans = _results[s.id];
        return exp != null &&
            ans != null &&
            ans != 'false' &&
            exp.toLowerCase() != ans.toLowerCase();
      }).toList();
      if (spots.isEmpty) spots = List<TrainingPackSpot>.from(widget.template.spots);
    }
    setState(() {
      _spots = spots;
      _index = 0;
      _streetCount = 0;
      _handCounts
        ..clear()
        ..addEntries(widget.template.focusHandTypes.map((e) => MapEntry(e.label, 0)));
    });
    _save();
  }

  String? _expected(TrainingPackSpot spot) {
    final acts = spot.hand.actions[0] ?? [];
    for (final a in acts) {
      if (a.playerIndex == spot.hand.heroIndex) return a.action;
    }
    return null;
  }

  List<String> _heroActions(TrainingPackSpot spot) {
    final acts = spot.hand.actions[0] ?? [];
    final hero = spot.hand.heroIndex;
    final res = <String>[];
    for (final a in acts) {
      if (a.playerIndex == hero) {
        final name = a.action.toLowerCase();
        if (!res.contains(name)) res.add(name);
      }
    }
    return res;
  }

  bool _matchHandTypeLabel(TrainingPackSpot spot, String label) {
    final code = handCode(spot.hand.heroCards);
    if (code == null) return false;
    return matchHandTypeLabel(label, code);
  }

  bool _matchHandType(TrainingPackSpot spot) {
    for (final g in widget.template.focusHandTypes) {
      if (_matchHandTypeLabel(spot, g.label)) return true;
    }
    return false;
  }

  bool _matchStreet(TrainingPackSpot spot) {
    final len = spot.hand.board.length;
    switch (widget.template.targetStreet) {
      case 'flop':
        return len == 3;
      case 'turn':
        return len == 4;
      case 'river':
        return len == 5;
      default:
        return false;
    }
  }

  Future<bool> _confirmStartOver(BuildContext context) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Start over?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('OK')),
        ],
      ),
    );
    return context.mounted && res == true;
  }

  Future<void> _choose(String? act) async {
    final spot = _spots[_index];
    if (act != null) {
      final first = !_results.containsKey(spot.id);
      _results[spot.id] = act.toLowerCase();
      if (first && _matchStreet(spot)) _streetCount++;
      if (first) {
        for (final g in widget.template.focusHandTypes) {
          if (_matchHandTypeLabel(spot, g.label)) {
            _handCounts[g.label] = (_handCounts[g.label] ?? 0) + 1;
          }
        }
      }

      final expected =
          spot.evalResult?.expectedAction ?? _expected(spot) ?? '-';
      final explanation = spot.note.trim().isNotEmpty
          ? spot.note.trim()
          : (spot.evalResult?.hint ?? '');

      await showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.grey[900],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExplanationText(
                selectedAction: act,
                correctAction: expected,
                explanation: explanation,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      );

      if (!mounted) return;
    }
    if (_index + 1 < _spots.length) {
      setState(() => _index++);
      _save();
    } else {
      _index = _spots.length - 1;
      _save();
      await context.read<StreakService>().onFinish();
      await NotificationService.cancel(101);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_training_day', DateTime.now().toIso8601String().split('T').first);
      await NotificationService.scheduleDailyReminder();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TrainingPackResultScreen(
            template: widget.template,
            results: _results,
            original: widget.original,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final spot = _spots[_index];
    final progress = (_index + 1) / _spots.length;
    final actions = _heroActions(spot);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Exit training? Your progress will be saved.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Exit'),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              _save();
              Navigator.pop(context);
            }
          },
        ),
        title: Text(widget.template.name),
        actions: [
          PopupMenuButton<dynamic>(
            initialValue: _order,
            onSelected: (choice) async {
              if (choice == 'start') {
                final ok = await _confirmStartOver(context);
                if (ok) {
                  setState(() {
                    _index = 0;
                    _results.clear();
                  });
                  final prefs = await SharedPreferences.getInstance();
                  prefs
                    ..remove('tpl_seq_${widget.template.id}')
                    ..remove('tpl_res_${widget.template.id}');
                  if (widget.template.targetStreet != null) {
                    prefs.remove('tpl_street_${widget.template.id}');
                  }
                  if (widget.template.focusHandTypes.isNotEmpty) {
                    prefs.remove('tpl_hand_${widget.template.id}');
                  }
                  _save(ts: false);
                }
              } else if (choice is PlayOrder) {
                setState(() => _order = choice);
                _startNew();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'start', child: Text('Start over')),
              PopupMenuDivider(),
              PopupMenuItem(value: PlayOrder.sequential, child: Text('Sequential')),
              PopupMenuItem(value: PlayOrder.random, child: Text('Random')),
              PopupMenuItem(value: PlayOrder.mistakes, child: Text('Mistakes')),
            ],
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1B1C1E),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 8),
            if (widget.template.focusTags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '🎯 Focus: ${widget.template.focusTags.join(', ')}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            if (widget.template.focusHandTypes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🎯 Hand Goals',
                        style: TextStyle(color: Colors.white70)),
                    for (final g in widget.template.focusHandTypes)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: _handTotals[g.label] != null && _handTotals[g.label]! > 0
                                    ? (_handCounts[g.label]?.clamp(0, _handTotals[g.label]!) ?? 0) /
                                        _handTotals[g.label]!
                                    : 0,
                                color: Colors.purpleAccent,
                                backgroundColor:
                                    Colors.purpleAccent.withOpacity(0.3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${g.label}: ${_handCounts[g.label] ?? 0}/${_handTotals[g.label] ?? 0}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            if (widget.template.heroRange != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  widget.template.handTypeSummary(),
                  style: const TextStyle(color: Colors.white54),
                ),
              ),
            Text('Spot ${_index + 1} of ${_spots.length}',
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (d) {
                  if (d.primaryVelocity != null &&
                      d.primaryVelocity! < -100 &&
                      _results[spot.id] == null) {
                    _choose(null);
                  }
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.1, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: Column(
                  key: ValueKey(_index),
                  children: [
                    SpotQuizWidget(spot: spot),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final a in actions.isEmpty
                            ? ['fold', 'push', 'call']
                            : (actions.length == 1 && !actions.contains('fold')
                                ? [...actions, 'fold']
                                : actions))
                          _results[spot.id]?.toLowerCase() == a.toLowerCase()
                              ? ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accent),
                                  onPressed: () => _choose(a),
                                  child: Text(a.toUpperCase()),
                                )
                              : OutlinedButton(
                                  onPressed: () => _choose(a),
                                  child: Text(a.toUpperCase()),
                                ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }
}

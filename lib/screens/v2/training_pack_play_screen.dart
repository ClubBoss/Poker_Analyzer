import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/v2/training_pack_template.dart';
import '../../models/v2/training_pack_spot.dart';
import '../../widgets/spot_quiz_widget.dart';
import 'training_pack_result_screen.dart';

enum PlayOrder { sequential, random, mistakes }

class TrainingPackPlayScreen extends StatefulWidget {
  final TrainingPackTemplate template;
  const TrainingPackPlayScreen({super.key, required this.template});

  @override
  State<TrainingPackPlayScreen> createState() => _TrainingPackPlayScreenState();
}

class _TrainingPackPlayScreenState extends State<TrainingPackPlayScreen> {
  late List<TrainingPackSpot> _spots;
  Map<String, bool> _results = {};
  int _index = 0;
  bool _loading = true;
  PlayOrder _order = PlayOrder.sequential;

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
    Map<String, bool> results = {};
    if (resStr != null) {
      final data = jsonDecode(resStr);
      if (data is Map) {
        results = {for (final e in data.entries) e.key as String: e.value == true};
      }
    }
    setState(() {
      _spots = spots;
      _results = results;
      _index = prefs.getInt(progKey)?.clamp(0, spots.length - 1) ?? 0;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('tpl_seq_${widget.template.id}', [for (final s in _spots) s.id]);
    await prefs.setInt('tpl_prog_${widget.template.id}', _index);
    await prefs.setString('tpl_res_${widget.template.id}', jsonEncode(_results));
  }

  void _startNew() {
    var spots = List<TrainingPackSpot>.from(widget.template.spots);
    if (_order == PlayOrder.random) {
      spots.shuffle();
    } else if (_order == PlayOrder.mistakes) {
      spots = [for (final s in spots) if (_results[s.id] == false) s];
      if (spots.isEmpty) spots = List<TrainingPackSpot>.from(widget.template.spots);
    }
    setState(() {
      _spots = spots;
      _index = 0;
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

  void _choose(String act) {
    final spot = _spots[_index];
    final exp = _expected(spot);
    final ok = exp != null && act.toLowerCase() == exp.toLowerCase();
    _results[spot.id] = ok;
    if (_index + 1 < _spots.length) {
      setState(() => _index++);
      _save();
    } else {
      _index = _spots.length - 1;
      _save();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TrainingPackResultScreen(
            template: widget.template,
            results: _results,
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template.name),
        actions: [
          PopupMenuButton<PlayOrder>(
            initialValue: _order,
            onSelected: (v) {
              setState(() => _order = v);
              _startNew();
            },
            itemBuilder: (_) => const [
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
            Text('${_index + 1} / ${_spots.length}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Expanded(child: SpotQuizWidget(spot: spot)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final a in ['fold', 'check', 'call', 'bet', 'raise'])
                  ElevatedButton(onPressed: () => _choose(a), child: Text(a.toUpperCase())),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

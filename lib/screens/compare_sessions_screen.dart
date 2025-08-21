import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../helpers/date_utils.dart';
import '../models/v2/training_session.dart';

class CompareSessionsScreen extends StatefulWidget {
  final String firstId;
  final String secondId;
  const CompareSessionsScreen({
    super.key,
    required this.firstId,
    required this.secondId,
  });

  @override
  State<CompareSessionsScreen> createState() => _CompareSessionsScreenState();
}

class _CompareSessionsScreenState extends State<CompareSessionsScreen> {
  TrainingSession? _first;
  TrainingSession? _second;
  Box<dynamic>? _box;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!Hive.isBoxOpen('sessions')) {
      await Hive.initFlutter();
      _box = await Hive.openBox('sessions');
    } else {
      _box = Hive.box('sessions');
    }
    final f = _box!.get(widget.firstId);
    final s = _box!.get(widget.secondId);
    if (f is Map) {
      _first = TrainingSession.fromJson(Map<String, dynamic>.from(f));
    }
    if (s is Map) {
      _second = TrainingSession.fromJson(Map<String, dynamic>.from(s));
    }
    setState(() {});
  }

  Widget _buildRow(String label, String left, String right) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
          Expanded(
            child: Text(
              left,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          Expanded(
            child: Text(
              right,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotRow(_SpotComparison c) {
    Color leftColor;
    Color rightColor;
    if (c.firstCorrect == c.secondCorrect) {
      leftColor =
          rightColor = c.firstCorrect ? Colors.greenAccent : Colors.white;
    } else {
      leftColor = c.firstCorrect ? Colors.greenAccent : Colors.redAccent;
      rightColor = c.secondCorrect ? Colors.greenAccent : Colors.redAccent;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(c.id, style: const TextStyle(color: Colors.white70)),
          ),
          Expanded(
            child: Icon(
              c.firstCorrect ? Icons.check : Icons.close,
              color: leftColor,
            ),
          ),
          Expanded(
            child: Icon(
              c.secondCorrect ? Icons.check : Icons.close,
              color: rightColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_first == null || _second == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF1B1C1E),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final firstCorrect = _first!.results.values.where((e) => e).length;
    final secondCorrect = _second!.results.values.where((e) => e).length;
    final firstMistakes = _first!.results.length - firstCorrect;
    final secondMistakes = _second!.results.length - secondCorrect;
    final firstDuration = (_first!.completedAt ?? DateTime.now()).difference(
      _first!.startedAt,
    );
    final secondDuration = (_second!.completedAt ?? DateTime.now()).difference(
      _second!.startedAt,
    );
    final overlap = _first!.results.keys.toSet().intersection(
          _second!.results.keys.toSet(),
        );
    final spots = [
      for (final id in overlap)
        _SpotComparison(
          id: id,
          firstCorrect: _first!.results[id] ?? false,
          secondCorrect: _second!.results[id] ?? false,
        ),
    ]..sort((a, b) => a.id.compareTo(b.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Сравнение сессий'), centerTitle: true),
      backgroundColor: const Color(0xFF1B1C1E),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Expanded(child: SizedBox()),
              Expanded(
                child: Text(
                  'Сессия ${_first!.id}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              Expanded(
                child: Text(
                  'Сессия ${_second!.id}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildRow(
            'Старт',
            formatDateTime(_first!.startedAt),
            formatDateTime(_second!.startedAt),
          ),
          _buildRow(
            'Финиш',
            _first!.completedAt != null
                ? formatDateTime(_first!.completedAt!)
                : '-',
            _second!.completedAt != null
                ? formatDateTime(_second!.completedAt!)
                : '-',
          ),
          _buildRow(
            'Споты',
            _first!.results.length.toString(),
            _second!.results.length.toString(),
          ),
          _buildRow('Верно', firstCorrect.toString(), secondCorrect.toString()),
          _buildRow(
            'Ошибки',
            firstMistakes.toString(),
            secondMistakes.toString(),
          ),
          _buildRow(
            'Длительность',
            formatDuration(firstDuration),
            formatDuration(secondDuration),
          ),
          if (spots.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Совпадающие споты',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Expanded(child: SizedBox()),
                Expanded(
                  child: Text(
                    'Первая',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Вторая',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final s in spots) _buildSpotRow(s),
          ],
        ],
      ),
    );
  }
}

class _SpotComparison {
  final String id;
  final bool firstCorrect;
  final bool secondCorrect;
  _SpotComparison({
    required this.id,
    required this.firstCorrect,
    required this.secondCorrect,
  });
}

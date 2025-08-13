import 'package:flutter/material.dart';

import '../../models/theory_pack_model.dart';

class TheoryPackQuickView extends StatelessWidget {
  final TheoryPackModel pack;
  const TheoryPackQuickView({super.key, required this.pack});

  static Future<void> launch(BuildContext context, TheoryPackModel pack) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TheoryPackQuickView(pack: pack),
      ),
    );
  }

  int _wordCount(String text) {
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    return words.length;
  }

  String _estimateReadTime() {
    const wpm = 150; // average words per minute
    final words =
        pack.sections.fold<int>(0, (sum, s) => sum + _wordCount(s.text));
    if (words == 0) return '1 мин';
    final minutes = words / wpm;
    final min = minutes.ceil();
    final max = (minutes * 1.5).ceil();
    return '$min–$max мин';
  }

  String _summary(String text) {
    final firstLine = text.split('\n').first.trim();
    if (firstLine.length <= 80) return firstLine;
    return '${firstLine.substring(0, 77)}...';
  }

  String _iconFor(String type) {
    switch (type) {
      case 'warning':
        return '⚠️';
      case 'tip':
        return '💡';
      default:
        return '📘';
    }
  }

  @override
  Widget build(BuildContext context) {
    final readTime = _estimateReadTime();
    return Scaffold(
      appBar: AppBar(title: Text(pack.title)),
      backgroundColor: const Color(0xFF121212),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: pack.sections.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          if (i == 0) {
            return Text('⏱ $readTime',
                style: const TextStyle(color: Colors.white70));
          }
          final section = pack.sections[i - 1];
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_iconFor(section.type)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (section.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _summary(section.text),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

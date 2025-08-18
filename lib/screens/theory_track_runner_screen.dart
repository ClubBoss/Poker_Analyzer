import 'package:flutter/material.dart';

import '../models/theory_track.dart';
import '../services/theory_content_service.dart';

/// Simple UI to present theory blocks sequentially from a [TheoryTrack].
class TheoryTrackRunnerScreen extends StatefulWidget {
  final TheoryTrack track;
  const TheoryTrackRunnerScreen({super.key, required this.track});

  @override
  State<TheoryTrackRunnerScreen> createState() =>
      _TheoryTrackRunnerScreenState();
}

class _TheoryTrackRunnerScreenState extends State<TheoryTrackRunnerScreen> {
  int _index = 0;

  void _next() {
    if (_index < widget.track.blockIds.length - 1) {
      setState(() => _index++);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final blockId = widget.track.blockIds[_index];
    final block = TheoryContentService.instance.get(blockId);
    final title = block?.title.isNotEmpty == true ? block!.title : blockId;
    final content = block?.content ?? '';
    return Scaffold(
      appBar: AppBar(title: Text(widget.track.title)),
      backgroundColor: const Color(0xFF121212),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(child: SingleChildScrollView(child: Text(content))),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _next,
                child: Text(
                  _index < widget.track.blockIds.length - 1
                      ? 'Продолжить'
                      : 'Завершить',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

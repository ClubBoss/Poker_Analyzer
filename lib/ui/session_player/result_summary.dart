import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'session_export.dart';
import 'spot_review_sheet.dart';

class ResultSummaryView extends StatefulWidget {
  final List<UiSpot> spots;
  final List<UiAnswer> answers;
  final VoidCallback onReplayErrors;
  final VoidCallback onRestart;
  final ValueChanged<int>? onReplayOne; // index in [0..spots.length)
  final void Function(List<int> indices)?
      onReplayMarked; // indices in [0..spots.length)

  const ResultSummaryView({
    super.key,
    required this.spots,
    required this.answers,
    required this.onReplayErrors,
    required this.onRestart,
    this.onReplayOne,
    this.onReplayMarked,
  });

  @override
  State<ResultSummaryView> createState() => _ResultSummaryViewState();
}

class _ResultSummaryViewState extends State<ResultSummaryView> {
  bool _errorsOnly = false;
  final Set<int> _marked = <int>{};

  @override
  Widget build(BuildContext context) {
    final spots = widget.spots;
    final answers = widget.answers;
    final total = answers.length;
    final correct = answers.where((a) => a.correct).length;
    final acc = total == 0 ? 0.0 : correct / total;
    final totalMs =
        answers.fold<int>(0, (sum, a) => sum + a.elapsed.inMilliseconds);
    final totalSecs = totalMs / 1000.0;
    final avgSecs = total == 0 ? 0.0 : totalSecs / total;

    final indices = <int>[];
    for (var i = 0; i < answers.length && i < spots.length; i++) {
      if (!_errorsOnly || !answers[i].correct) indices.add(i);
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Accuracy ${(acc * 100).toStringAsFixed(0)}% ($correct/$total) - '
                '${totalSecs.toStringAsFixed(1)}s total - ${avgSecs.toStringAsFixed(1)}s avg',
              ),
              Row(
                children: [
                  const Text('Only errors'),
                  Switch(
                    value: _errorsOnly,
                    onChanged: (v) => setState(() => _errorsOnly = v),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: _marked.isEmpty || widget.onReplayMarked == null
                    ? null
                    : () => widget.onReplayMarked!(_marked.toList()..sort()),
                child: const Text('Replay marked'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: widget.onReplayErrors,
                child: const Text('Replay errors'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () async {
                  final json = buildSessionJson(spots: spots, answers: answers);
                  final path = await saveSessionJson(json);
                  await Clipboard.setData(ClipboardData(text: path));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Saved to $path')));
                  }
                },
                child: const Text('Export JSON'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () async {
                  final json = buildSessionJson(spots: spots, answers: answers);
                  await Clipboard.setData(ClipboardData(text: json));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Summary copied')));
                  }
                },
                child: const Text('Copy JSON'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: indices.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, idx) {
                final i = indices[idx];
                final s = spots[i];
                final a = answers[i];
                final marked = _marked.contains(i);
                return ListTile(
                  leading: Icon(
                    a.correct ? Icons.check_circle : Icons.cancel,
                    color: a.correct ? Colors.green : Colors.red,
                  ),
                  title: Text('Spot ${i + 1} - ${s.hand}'),
                  subtitle: Text(
                    'Expected: ${a.expected} | Chosen: ${a.chosen} | ${a.elapsed.inMilliseconds} ms',
                  ),
                  onTap: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.black87
                              : null,
                      builder: (_) => SpotReviewSheet(
                        index: i + 1,
                        spot: s,
                        answer: a,
                      ),
                    );
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: marked ? 'Unmark' : 'Mark',
                        icon: Icon(
                            marked ? Icons.bookmark : Icons.bookmark_border),
                        onPressed: () {
                          setState(() {
                            if (marked) {
                              _marked.remove(i);
                            } else {
                              _marked.add(i);
                            }
                          });
                        },
                      ),
                      IconButton(
                        tooltip: 'Replay',
                        icon: const Icon(Icons.play_arrow),
                        onPressed: widget.onReplayOne == null
                            ? null
                            : () => widget.onReplayOne!(i),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: widget.onRestart,
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }
}

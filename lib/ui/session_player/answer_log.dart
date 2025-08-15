import 'models.dart';

class AnswerLogItem {
  final String kind;
  final String hand;
  final String pos;
  final String? vsPos;
  final String? limpers;
  final String stack;
  final String expected;
  final String chosen;
  final bool correct;
  final int elapsedMs;

  const AnswerLogItem({
    required this.kind,
    required this.hand,
    required this.pos,
    required this.vsPos,
    required this.limpers,
    required this.stack,
    required this.expected,
    required this.chosen,
    required this.correct,
    required this.elapsedMs,
  });

  Map<String, dynamic> toJson() => {
        'kind': kind,
        'hand': hand,
        'pos': pos,
        'vsPos': vsPos,
        'limpers': limpers,
        'stack': stack,
        'expected': expected,
        'chosen': chosen,
        'correct': correct,
        'elapsedMs': elapsedMs,
      };
}

class AnswerLog {
  final String version;
  final int total;
  final int correct;
  final List<AnswerLogItem> items;

  const AnswerLog({
    this.version = 'v1',
    required this.total,
    required this.correct,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'total': total,
        'correct': correct,
        'items': items.map((e) => e.toJson()).toList(),
      };
}

AnswerLog buildAnswerLog(List<UiSpot> spots, List<UiAnswer> answers) {
  final items = <AnswerLogItem>[];
  var correct = 0;
  for (var i = 0; i < answers.length; i++) {
    final spot = spots[i];
    final ans = answers[i];
    if (ans.correct) correct++;
    items.add(AnswerLogItem(
      kind: spot.kind.name,
      hand: spot.hand,
      pos: spot.pos,
      vsPos: spot.vsPos,
      limpers: spot.limpers,
      stack: spot.stack,
      expected: ans.expected,
      chosen: ans.chosen,
      correct: ans.correct,
      elapsedMs: ans.elapsed.inMilliseconds,
    ));
  }
  return AnswerLog(total: answers.length, correct: correct, items: items);
}

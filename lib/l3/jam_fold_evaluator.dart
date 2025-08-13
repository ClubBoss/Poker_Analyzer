import 'dart:convert';

class FlopBoard {
  final List<String> cards; // e.g. ['As','Kd','Th']

  FlopBoard(this.cards) : assert(cards.length == 3);

  factory FlopBoard.fromString(String board) {
    return FlopBoard([
      board.substring(0, 2),
      board.substring(2, 4),
      board.substring(4, 6),
    ]);
  }

  bool get isPaired {
    final ranks = cards.map((c) => c[0]).toList();
    return ranks[0] == ranks[1] ||
        ranks[0] == ranks[2] ||
        ranks[1] == ranks[2];
  }

  bool get isAceHigh => cards.any((c) => c[0] == 'A');

  bool get isBroadway {
    const broadway = {'A', 'K', 'Q', 'J', 'T'};
    return cards.where((c) => broadway.contains(c[0])).length >= 2;
  }

  String get texture {
    final suits = cards.map((c) => c[1]).toSet();
    if (suits.length == 1) return 'monotone';
    if (suits.length == 2) return 'twoTone';
    return 'rainbow';
  }

  List<String> get tags {
    final list = <String>[texture];
    list.add(isPaired ? 'paired' : 'unpaired');
    if (isAceHigh) list.add('ace-high');
    if (isBroadway) list.add('broadway');
    return list;
  }
}

class JamFoldOutcome {
  final double jamEV;
  final double foldEV;
  final String decision; // 'jam' or 'fold'

  JamFoldOutcome({required this.jamEV, required this.foldEV, required this.decision});

  Map<String, dynamic> toJson() => {
        'jamEV': jamEV,
        'foldEV': foldEV,
        'decision': decision,
      };
}

class JamFoldEvaluator {
  final Map<String, double> weights;

  JamFoldEvaluator({Map<String, double>? weights})
      : weights = weights ?? _defaultWeights;

  factory JamFoldEvaluator.fromJson(String jsonStr) {
    final decoded = json.decode(jsonStr) as Map<String, dynamic>;
    return JamFoldEvaluator(
      weights: decoded.map((k, v) => MapEntry(k, (v as num).toDouble())),
    );
  }

  JamFoldOutcome evaluate({
    required FlopBoard board,
    required double spr,
    Map<String, double>? priors,
  }) {
    final bucket = spr < 1
        ? 'spr_low'
        : spr < 2
            ? 'spr_mid'
            : 'spr_high';

    double score = 0;
    for (final tag in board.tags) {
      score += weights[tag] ?? 0;
    }
    score += weights[bucket] ?? 0;

    final jamPrior = priors?['jam'] ?? 0.5;
    final foldPrior = priors?['fold'] ?? 0.5;

    final jamEV = jamPrior + score;
    final foldEV = foldPrior - score;
    final decision = jamEV >= foldEV ? 'jam' : 'fold';

    return JamFoldOutcome(jamEV: jamEV, foldEV: foldEV, decision: decision);
  }
}

const Map<String, double> _defaultWeights = {
  'paired': -0.2,
  'unpaired': 0.2,
  'monotone': -0.3,
  'twoTone': 0.1,
  'rainbow': 0.2,
  'ace-high': 0.1,
  'broadway': 0.05,
  'spr_low': 0.3,
  'spr_mid': 0.0,
  'spr_high': -0.3,
};


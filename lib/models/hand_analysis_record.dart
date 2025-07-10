import 'card_model.dart';

class HandAnalysisRecord {
  final String card1;
  final String card2;
  final int stack;
  final int playerCount;
  final int heroIndex;
  final double ev;
  final double icm;
  final String action;
  final String hint;
  final DateTime date;

  HandAnalysisRecord({
    required this.card1,
    required this.card2,
    required this.stack,
    required this.playerCount,
    required this.heroIndex,
    required this.ev,
    required this.icm,
    required this.action,
    required this.hint,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  List<CardModel> get cards => [
        CardModel(rank: card1[0], suit: card1.substring(1)),
        CardModel(rank: card2[0], suit: card2.substring(1)),
      ];

  Map<String, dynamic> toJson() => {
        'card1': card1,
        'card2': card2,
        'stack': stack,
        'playerCount': playerCount,
        'heroIndex': heroIndex,
        'ev': ev,
        'icm': icm,
        'action': action,
        'hint': hint,
        'date': date.toIso8601String(),
      };

  factory HandAnalysisRecord.fromJson(Map<String, dynamic> j) => HandAnalysisRecord(
        card1: j['card1'] as String? ?? '',
        card2: j['card2'] as String? ?? '',
        stack: j['stack'] as int? ?? 0,
        playerCount: j['playerCount'] as int? ?? 0,
        heroIndex: j['heroIndex'] as int? ?? 0,
        ev: (j['ev'] as num?)?.toDouble() ?? 0,
        icm: (j['icm'] as num?)?.toDouble() ?? 0,
        action: j['action'] as String? ?? '',
        hint: j['hint'] as String? ?? '',
        date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
      );
}

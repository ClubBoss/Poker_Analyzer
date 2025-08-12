import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/card_model.dart';
import '../models/player_model.dart';
import '../models/training_spot.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'daily_challenge_streak_service.dart';
import 'daily_challenge_history_service.dart';

/// Singleton service managing the Daily Challenge spot logic.
class DailyChallengeService extends ChangeNotifier {
  DailyChallengeService._();

  /// The single instance of [DailyChallengeService].
  static final DailyChallengeService instance = DailyChallengeService._();

  factory DailyChallengeService() => instance;

  static const String _dateKey = 'lastDailyChallengeDate';
  static const String _spotKey = 'lastDailyChallengeSpot';
  static const String _completedKey = 'lastDailyChallengeCompleted';

  TrainingSpot? _spot;
  DateTime? _date;
  bool _completed = false;

  /// Returns cached spot if available.
  TrainingSpot? get spot => _spot;

  /// Whether today's challenge was already completed.
  bool get completed => isCompletedToday();

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Loads or generates today's challenge spot.
  Future<TrainingSpot?> getTodayChallenge() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    if (_spot != null && _date != null && _sameDay(_date!, now)) {
      return _spot;
    }

    final dateStr = prefs.getString(_dateKey);
    final spotStr = prefs.getString(_spotKey);
    final storedCompleted = prefs.getBool(_completedKey) ?? false;
    if (dateStr != null && spotStr != null) {
      final storedDate = DateTime.tryParse(dateStr);
      if (storedDate != null && _sameDay(storedDate, now)) {
        try {
          final map = jsonDecode(spotStr);
          if (map is Map<String, dynamic>) {
            _spot = TrainingSpot.fromJson(Map<String, dynamic>.from(map));
            _date = storedDate;
            _completed = storedCompleted;
            return _spot;
          }
        } catch (_) {}
      }
    }

    _spot = await _loadSpot();
    _date = DateTime(now.year, now.month, now.day);
    _completed = false;
    await prefs.setString(_dateKey, _date!.toIso8601String());
    if (_spot != null) {
      await prefs.setString(_spotKey, jsonEncode(_spot!.toJson()));
    } else {
      await prefs.remove(_spotKey);
    }
    await prefs.setBool(_completedKey, false);
    notifyListeners();
    return _spot;
  }

  /// Marks today's challenge as completed.
  Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day);
    _completed = true;
    await prefs.setString(_dateKey, _date!.toIso8601String());
    await prefs.setBool(_completedKey, true);
    await DailyChallengeStreakService.instance.updateStreak();
    await DailyChallengeHistoryService.instance.addToday();
    notifyListeners();
  }

  /// Returns `true` if today's challenge is completed.
  bool isCompletedToday() {
    final now = DateTime.now();
    if (_date == null || !_sameDay(_date!, now)) return false;
    return _completed;
  }

  Future<TrainingSpot?> _loadSpot() async {
    // Try loading from bundled YAML pack first.
    try {
      final yaml = await rootBundle.loadString('assets/master_daily.yaml');
      final tpl = TrainingPackTemplateV2.fromYamlAuto(yaml);
      if (tpl.spots.isNotEmpty) {
        return _fromPackSpot(tpl.spots.first);
      }
    } catch (_) {}

    // Fallback to the first bundled spot as a placeholder.
    try {
      final data = await rootBundle.loadString('assets/spots/spots.json');
      final list = jsonDecode(data);
      if (list is List && list.isNotEmpty) {
        final map = Map<String, dynamic>.from(list.first as Map);
        return TrainingSpot.fromJson(map);
      }
    } catch (_) {}

    return null;
  }

  TrainingSpot _fromPackSpot(TrainingPackSpot spot) {
    final hand = spot.hand;
    final heroCards = hand.heroCards
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .map((e) => CardModel(rank: e[0], suit: e.substring(1)))
        .toList();
    final playerCards = [
      for (int i = 0; i < hand.playerCount; i++) <CardModel>[]
    ];
    if (heroCards.length >= 2 && hand.heroIndex < playerCards.length) {
      playerCards[hand.heroIndex] = heroCards;
    }
    final boardCards = [
      for (final c in hand.board) CardModel(rank: c[0], suit: c.substring(1))
    ];
    final actions = hand.actions.values.expand((l) => l).toList();
    final stacks = [
      for (var i = 0; i < hand.playerCount; i++) hand.stacks['$i']?.round() ?? 0
    ];
    final positions = List.generate(hand.playerCount, (_) => '');
    if (hand.heroIndex < positions.length) {
      positions[hand.heroIndex] = hand.position.label;
    }
    return TrainingSpot(
      playerCards: playerCards,
      boardCards: boardCards,
      actions: actions,
      heroIndex: hand.heroIndex,
      numberOfPlayers: hand.playerCount,
      playerTypes: List.generate(hand.playerCount, (_) => PlayerType.unknown),
      positions: positions,
      stacks: stacks,
      tags: List<String>.from(spot.tags),
      recommendedAction: spot.correctAction,
      difficulty: 3,
      rating: 0,
      createdAt: DateTime.now(),
    );
  }
}

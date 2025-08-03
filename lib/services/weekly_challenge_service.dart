import 'dart:async';
import 'package:poker_analyzer/services/preferences_service.dart';
import 'package:flutter/material.dart';

import '../models/training_pack.dart';
import 'training_pack_storage_service.dart';

import 'training_stats_service.dart';
import 'xp_tracker_service.dart';
import '../main.dart';

class WeeklyChallenge {
  final String title;
  final String type;
  final int target;
  const WeeklyChallenge(this.title, this.type, this.target);
}

class WeeklyChallengeService extends ChangeNotifier {
  static const _indexKey = 'weekly_challenge_index';
  static const _startKey = 'weekly_challenge_start';
  static const _handsKey = 'weekly_challenge_base_hands';
  static const _mistakesKey = 'weekly_challenge_base_mistakes';

  final TrainingStatsService stats;
  final XPTrackerService xp;
  final TrainingPackStorageService packs;

  static const _rewardXp = 50;

  WeeklyChallengeService({required this.stats, required this.xp, required this.packs});

  static const _challenges = [
    WeeklyChallenge('Tag 5 mistakes', 'mistakes', 5),
    WeeklyChallenge('Play 100 hands', 'hands', 100),
  ];

  int _index = 0;
  DateTime _start = DateTime.now();
  int _baseHands = 0;
  int _baseMistakes = 0;

  StreamSubscription<int>? _handsSub;
  StreamSubscription<int>? _mistakeSub;

  WeeklyChallenge get current => _challenges[_index];

  Future<void> load() async {
    final prefs = await PreferencesService.getInstance();
    _index = prefs.getInt(_indexKey) ?? 0;
    final startStr = prefs.getString(_startKey);
    _start = startStr != null ? DateTime.tryParse(startStr) ?? DateTime.now() : DateTime.now();
    _baseHands = prefs.getInt(_handsKey) ?? stats.handsReviewed;
    _baseMistakes = prefs.getInt(_mistakesKey) ?? stats.mistakesFixed;
    _rotate();
    _handsSub = stats.handsStream.listen((_) => _onStats());
    _mistakeSub = stats.mistakesStream.listen((_) => _onStats());
    notifyListeners();
  }

  int get progressValue {
    _rotate();
    switch (current.type) {
      case 'hands':
        final val = stats.handsReviewed - _baseHands;
        return val.clamp(0, current.target);
      default:
        final val = stats.mistakesFixed - _baseMistakes;
        return val.clamp(0, current.target);
    }
  }

  double get progress => (progressValue / current.target).clamp(0.0, 1.0);

  int get daysLeft =>
      (7 - DateTime.now().difference(_start).inDays).clamp(0, 7);

  TrainingPack get currentPack =>
      packs.packs.isNotEmpty
          ? packs.packs.first
          : TrainingPack(
              name: current.title,
              description: '',
              tags: const [],
              hands: [],
              spots: const [],
              difficulty: 1,
            );

  Future<void> _onStats() async {
    if (progressValue >= current.target) {
      await xp.add(xp: _rewardXp, source: 'weekly_challenge');
      if (navigatorKey.currentState?.context.mounted ?? false) {
        ScaffoldMessenger.of(navigatorKey.currentState!.context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Challenge completed!'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _rotate(force: true);
    }
    _rotate();
    notifyListeners();
  }

  bool _rotate({bool force = false}) {
    final now = DateTime.now();
    if (force || now.difference(_start).inDays >= 7) {
      _index = (_index + 1) % _challenges.length;
      _start = DateTime(now.year, now.month, now.day);
      _baseHands = stats.handsReviewed;
      _baseMistakes = stats.mistakesFixed;
      _save();
      return true;
    }
    return false;
  }

  Future<void> _save() async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setInt(_indexKey, _index);
    await prefs.setString(_startKey, _start.toIso8601String());
    await prefs.setInt(_handsKey, _baseHands);
    await prefs.setInt(_mistakesKey, _baseMistakes);
  }

  @override
  void dispose() {
    _handsSub?.cancel();
    _mistakeSub?.cancel();
    super.dispose();
  }
}

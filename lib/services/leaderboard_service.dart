import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'training_stats_service.dart';

class LeaderboardEntry {
  final String uuid;
  final int handsReviewed;
  final int mistakesFixed;

  LeaderboardEntry({
    required this.uuid,
    required this.handsReviewed,
    required this.mistakesFixed,
  });

  factory LeaderboardEntry.fromMap(Map<dynamic, dynamic> map) => LeaderboardEntry(
        uuid: map['uuid'] as String? ?? '',
        handsReviewed: map['handsReviewed'] as int? ?? 0,
        mistakesFixed: map['mistakesFixed'] as int? ?? 0,
      );
}

class LeaderboardService extends ChangeNotifier {
  static const _idKey = 'leaderboard_user_id';
  final TrainingStatsService stats;
  late final DatabaseReference _ref;
  late final String _id;
  List<LeaderboardEntry> _entries = [];
  List<LeaderboardEntry> get entries => List.unmodifiable(_entries);
  StreamSubscription<DatabaseEvent>? _sub;

  LeaderboardService({required this.stats});

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_idKey);
    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString(_idKey, id);
    }
    _id = id;
    _ref = FirebaseDatabase.instance.ref('leaderboard');
    await _push();
    _listen();
    stats.handsStream.listen((_) => _push());
    stats.mistakesStream.listen((_) => _push());
  }

  Future<void> _push() async {
    final data = {
      'uuid': _id,
      'handsReviewed': stats.handsReviewed,
      'mistakesFixed': stats.mistakesFixed,
    };
    await _ref.child(_id).set(data);
  }

  void _listen() {
    _sub = _ref
        .orderByChild('handsReviewed')
        .limitToLast(50)
        .onValue
        .listen((event) {
      final value = event.snapshot.value;
      if (value is Map) {
        final list = <LeaderboardEntry>[];
        value.forEach((key, val) {
          if (val is Map) list.add(LeaderboardEntry.fromMap(val));
        });
        list.sort((a, b) => b.handsReviewed.compareTo(a.handsReviewed));
        _entries = list;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

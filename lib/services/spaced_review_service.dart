import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_spot.dart';
import 'template_storage_service.dart';
import 'user_error_rate_service.dart';
import 'notification_service.dart';
import 'analytics_service.dart';

class _SRItem {
  String packId;
  int box;
  int due; // epoch day
  int last; // epoch seconds
  _SRItem({
    required this.packId,
    required this.box,
    required this.due,
    required this.last,
  });

  Map<String, dynamic> toJson() => {'p': packId, 'b': box, 'd': due, 'l': last};

  static _SRItem fromJson(Map<String, dynamic> json) => _SRItem(
    packId: json['p'] as String,
    box: json['b'] as int,
    due: json['d'] as int,
    last: json['l'] as int,
  );
}

class SpacedReviewService extends ChangeNotifier {
  SpacedReviewService({required this.templates});

  static const String dueTemplateId = 'sr_due_pack';
  static const _prefsKey = 'sr_v1';
  static const _intervals = [1, 3, 7, 14, 30];
  static const _notifId = 104;

  final TemplateStorageService templates;
  final Map<String, _SRItem> _data = {};
  bool _loaded = false;

  Future<void> init() async {
    await _load();
    await _scheduleNotification();
  }

  Future<void> _load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_prefsKey);
    if (str != null) {
      final raw = jsonDecode(str) as Map<String, dynamic>;
      raw.forEach((k, v) {
        _data[k] = _SRItem.fromJson(Map<String, dynamic>.from(v));
      });
    }
    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, dynamic>{};
    _data.forEach((k, v) => map[k] = v.toJson());
    await prefs.setString(_prefsKey, jsonEncode(map));
  }

  int _epochDay(DateTime d) => d.toUtc().millisecondsSinceEpoch ~/ 86400000;
  int _epochSec(DateTime d) => d.toUtc().millisecondsSinceEpoch ~/ 1000;

  Future<void> recordMistake(String spotId, String packId) async {
    await _load();
    final now = DateTime.now();
    _data[spotId] = _SRItem(
      packId: packId,
      box: 1,
      due: _epochDay(now) + 1,
      last: _epochSec(now),
    );
    await _save();
    unawaited(
      AnalyticsService.instance.logEvent('sr_enqueued', {
        'spotId': spotId,
        'packId': packId,
      }),
    );
    await _scheduleNotification();
    notifyListeners();
  }

  Future<void> recordReviewOutcome(
    String spotId,
    String packId,
    bool correct,
  ) async {
    await _load();
    final entry = _data[spotId];
    if (entry == null) return;
    final now = DateTime.now();
    final boxFrom = entry.box;
    double avg = 0.0;
    if (correct) {
      final tags = _spotTags(packId, spotId).toSet();
      final rates = await UserErrorRateService.instance.getRates(
        packId: packId,
        tags: tags,
      );
      if (rates.isNotEmpty) {
        avg = rates.values.reduce((a, b) => a + b) / rates.length;
      }
      var nextBox = entry.box + 1;
      if (avg < 0.15) nextBox += 1;
      final maxBox = avg > 0.5 ? 3 : 5;
      if (nextBox > maxBox) nextBox = maxBox;
      entry.box = nextBox;
      entry.due = _epochDay(now) + _intervals[entry.box - 1];
    } else {
      entry.box = 1;
      entry.due = _epochDay(now) + 1;
    }
    entry.last = _epochSec(now);
    await _save();
    unawaited(
      AnalyticsService.instance.logEvent('sr_review_outcome', {
        'spotId': spotId,
        'packId': packId,
        'boxFrom': boxFrom,
        'boxTo': entry.box,
        'ewmaBefore': avg,
        'correct': correct,
      }),
    );
    await _scheduleNotification();
    notifyListeners();
  }

  List<String> dueSpotIds(DateTime today, {int limit = 10}) {
    final day = _epochDay(today);
    final entries = _data.entries.where((e) => e.value.due <= day).toList()
      ..sort((a, b) => a.value.due.compareTo(b.value.due));
    return entries.take(limit).map((e) => e.key).toList();
  }

  int dueCount(DateTime today) {
    final day = _epochDay(today);
    return _data.values.where((e) => e.due <= day).length;
  }

  Future<TrainingPackTemplate?> duePack({
    int limit = 10,
    bool log = true,
  }) async {
    await _load();
    final ids = dueSpotIds(DateTime.now(), limit: limit);
    if (ids.isEmpty) return null;
    final map = <String, TrainingPackSpot>{};
    for (final t in templates.templates) {
      for (final s in t.spots) {
        map[s.id] = s;
      }
    }
    final spots = <TrainingPackSpot>[];
    for (final id in ids) {
      final s = map[id];
      if (s != null) {
        spots.add(TrainingPackSpot.fromJson(s.toJson()));
      }
    }
    if (spots.isEmpty) return null;
    if (log) {
      unawaited(
        AnalyticsService.instance.logEvent('sr_due_opened', {
          'count': spots.length,
        }),
      );
    }
    return TrainingPackTemplate(
      id: dueTemplateId,
      name: 'Review Mistakes',
      createdAt: DateTime.now(),
      spots: spots,
    );
  }

  Future<void> logDueOpened() async {
    await _load();
    unawaited(
      AnalyticsService.instance.logEvent('sr_due_opened', {
        'count': dueCount(DateTime.now()),
      }),
    );
  }

  Future<void> _scheduleNotification() async {
    try {
      final now = DateTime.now();
      var when = DateTime(now.year, now.month, now.day, 10);
      var dayFor = now;
      if (when.isBefore(now)) {
        when = when.add(const Duration(days: 1));
        dayFor = dayFor.add(const Duration(days: 1));
      }
      final count = dueCount(dayFor);
      if (count > 0) {
        await NotificationService.schedule(
          id: _notifId,
          when: when,
          body: 'You have $count reviews due',
        );
      } else {
        await NotificationService.cancel(_notifId);
      }
    } catch (_) {}
  }

  String? packIdForSpot(String spotId) => _data[spotId]?.packId;

  List<String> _spotTags(String packId, String spotId) {
    final tpl = templates.templates.firstWhereOrNull((t) => t.id == packId);
    final spot = tpl?.spots.firstWhereOrNull((s) => s.id == spotId);
    return spot?.tags ?? const <String>[];
  }

  @visibleForTesting
  _SRItem? debugEntry(String spotId) => _data[spotId];

  @visibleForTesting
  int debugEpochDay(DateTime d) => _epochDay(d);
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/training_pack.dart';
import '../models/saved_hand.dart';
import '../models/mistake_pack.dart';
import 'saved_hand_manager_service.dart';
import 'mistake_pack_cloud_service.dart';

class MistakeReviewPackService extends ChangeNotifier {
  static const _progressKey = 'mistake_review_progress';
  static const _dateKey = 'mistake_review_date';
  static const _packsKey = 'mistake_packs';

  final SavedHandManagerService hands;
  final MistakePackCloudService? cloud;

  final List<MistakePack> _packs = [];
  List<MistakePack> get packs => List.unmodifiable(_packs);

  TrainingPack? _pack;
  int _progress = 0;
  DateTime? _date;
  Timer? _timer;

  TrainingPack? get pack => _pack;
  int get progress => _progress;

  MistakeReviewPackService({required this.hands, this.cloud});

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _progress = prefs.getInt(_progressKey) ?? 0;
    final str = prefs.getString(_dateKey);
    _date = str != null ? DateTime.tryParse(str) : null;
    final list = prefs.getStringList(_packsKey) ?? [];
    _packs
      ..clear()
      ..addAll(list.map((e) =>
          MistakePack.fromJson(jsonDecode(e) as Map<String, dynamic>)));
    _generate();
    _schedule();
    unawaited(syncDown());
  }

  List<SavedHand> _mistakes() {
    final list = <SavedHand>[];
    for (final h in hands.hands.reversed) {
      final exp = h.expectedAction?.trim().toLowerCase();
      final gto = h.gtoAction?.trim().toLowerCase();
      if (exp != null && gto != null && exp.isNotEmpty && gto.isNotEmpty && exp != gto) {
        list.add(h);
        if (list.length >= 10) break;
      }
    }
    return list.reversed.toList();
  }

  void _generate() {
    final today = DateTime.now();
    if (_pack != null && _date != null && _sameDay(_date!, today)) return;
    final hs = _mistakes();
    _pack = TrainingPack(
      name: 'Repeat Mistakes',
      description: '',
      isBuiltIn: true,
      tags: const [],
      hands: hs,
      spots: const [],
      difficulty: 1,
    );
    _date = today;
    _progress = 0;
    _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_progressKey, _progress);
    await prefs.setString(_dateKey, _date!.toIso8601String());
    await prefs.setStringList(
      _packsKey,
      [for (final p in _packs) jsonEncode(p.toJson())],
    );
  }

  Future<void> setProgress(int value) async {
    _progress = value.clamp(0, _pack?.hands.length ?? 0);
    await _save();
    notifyListeners();
  }

  Future<void> addPack(List<String> spotIds, {String note = ''}) async {
    _packs.add(MistakePack(spotIds: spotIds, note: note));
    await _save();
    await syncUp();
    _generate();
  }

  Future<void> syncDown() async {
    if (cloud == null) return;
    final remote = await cloud!.loadPacks();
    _packs
      ..clear()
      ..addAll(remote);
    await _save();
    _generate();
  }

  Future<void> syncUp() async {
    if (cloud == null) return;
    for (final p in _packs) {
      await cloud!.savePack(p);
    }
  }

  void _schedule() {
    _timer?.cancel();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    _timer = Timer(next.difference(now), () {
      _generate();
      _schedule();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

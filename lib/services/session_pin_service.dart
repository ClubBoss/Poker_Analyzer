import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cloud_sync_service.dart';

class SessionPinService extends ChangeNotifier {
  static const _prefsKey = 'pinned_sessions';
  static const _timeKey = 'pinned_sessions_updated';

  SessionPinService({this.cloud});

  final CloudSyncService? cloud;

  final Set<int> _pinned = {};

  Set<int> get pinned => _pinned;

  bool isPinned(int id) => _pinned.contains(id);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_prefsKey) ?? [];
    _pinned
      ..clear()
      ..addAll(stored.map(int.parse));
    if (cloud != null) {
      final remote = cloud!.getCached('pinned_sessions');
      if (remote != null) {
        final remoteAt =
            DateTime.tryParse(remote['updatedAt'] as String? ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0);
        final localAt = DateTime.tryParse(prefs.getString(_timeKey) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        if (remoteAt.isAfter(localAt)) {
          final list = remote['ids'];
          if (list is List) {
            _pinned
              ..clear()
              ..addAll(list.map((e) => (e as num).toInt()));
            await _persist();
          }
        } else if (localAt.isAfter(remoteAt)) {
          await cloud!.uploadPinned(_pinned);
        }
      }
    }
    notifyListeners();
  }

  Future<void> setPinned(int id, bool value) async {
    if (value) {
      _pinned.add(id);
    } else {
      _pinned.remove(id);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _prefsKey, _pinned.map((e) => e.toString()).toList());
    await prefs.setString(_timeKey, DateTime.now().toIso8601String());
    if (cloud != null) {
      await cloud!.uploadPinned(_pinned);
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _prefsKey, _pinned.map((e) => e.toString()).toList());
    await prefs.setString(_timeKey, DateTime.now().toIso8601String());
    if (cloud != null) {
      await cloud!.uploadPinned(_pinned);
    }
  }
}

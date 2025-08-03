import 'dart:convert';
import 'package:poker_analyzer/services/preferences_service.dart';


import '../models/v3/track_meta.dart';

class LessonTrackMetaService {
  LessonTrackMetaService._();
  static final instance = LessonTrackMetaService._();

  static String _key(String id) => 'lesson_track_meta_$id';

  Future<void> markStarted(String trackId) async {
    final prefs = await PreferencesService.getInstance();
    final raw = prefs.getString(_key(trackId));
    TrackMeta meta;
    if (raw != null) {
      try {
        final data = jsonDecode(raw);
        if (data is Map<String, dynamic>) {
          meta = TrackMeta.fromJson(data);
        } else {
          meta = TrackMeta();
        }
      } catch (_) {
        meta = TrackMeta();
      }
    } else {
      meta = TrackMeta();
    }
    if (meta.startedAt != null) return;
    meta = TrackMeta(
      startedAt: DateTime.now(),
      completedAt: meta.completedAt,
      timesCompleted: meta.timesCompleted,
    );
    await prefs.setString(_key(trackId), jsonEncode(meta.toJson()));
  }

  Future<void> markCompleted(String trackId) async {
    final prefs = await PreferencesService.getInstance();
    final raw = prefs.getString(_key(trackId));
    TrackMeta meta;
    if (raw != null) {
      try {
        final data = jsonDecode(raw);
        if (data is Map<String, dynamic>) {
          meta = TrackMeta.fromJson(data);
        } else {
          meta = TrackMeta();
        }
      } catch (_) {
        meta = TrackMeta();
      }
    } else {
      meta = TrackMeta();
    }
    meta = TrackMeta(
      startedAt: meta.startedAt ?? DateTime.now(),
      completedAt: DateTime.now(),
      timesCompleted: meta.timesCompleted + 1,
    );
    await prefs.setString(_key(trackId), jsonEncode(meta.toJson()));
  }

  Future<TrackMeta?> load(String trackId) async {
    final prefs = await PreferencesService.getInstance();
    final raw = prefs.getString(_key(trackId));
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw);
      if (data is Map<String, dynamic>) {
        return TrackMeta.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (_) {}
    return null;
  }
}

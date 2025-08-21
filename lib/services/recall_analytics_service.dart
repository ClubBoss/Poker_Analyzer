import 'package:flutter/foundation.dart';
import 'user_action_logger.dart';

class RecallEvent {
  final String trigger;
  final String? lessonId;
  final List<String>? tags;
  final String action;
  final DateTime timestamp;
  final Duration? viewDuration;

  const RecallEvent({
    required this.trigger,
    this.lessonId,
    this.tags,
    required this.action,
    required this.timestamp,
    this.viewDuration,
  });

  Map<String, dynamic> toJson() => {
        'trigger': trigger,
        if (lessonId != null) 'lessonId': lessonId,
        if (tags != null && tags!.isNotEmpty) 'tags': tags,
        'action': action,
        'timestamp': timestamp.toIso8601String(),
        if (viewDuration != null) 'viewDuration': viewDuration!.inMilliseconds,
      };
}

class RecallAnalyticsService extends ChangeNotifier {
  RecallAnalyticsService._();
  static final instance = RecallAnalyticsService._();

  final List<RecallEvent> _events = [];
  DateTime? _openedAt;
  String? _openedTrigger;
  String? _openedLessonId;
  List<String>? _openedTags;

  void logPrompt({
    required String trigger,
    String? lessonId,
    List<String>? tags,
    required bool dismissed,
  }) {
    final event = RecallEvent(
      trigger: trigger,
      lessonId: lessonId,
      tags: tags,
      action: dismissed ? 'dismissed' : 'opened',
      timestamp: DateTime.now(),
    );
    _events.add(event);
    UserActionLogger.instance.logEvent(event.toJson());
    notifyListeners();
  }

  void recapOpened({
    required String trigger,
    String? lessonId,
    List<String>? tags,
  }) {
    _openedAt = DateTime.now();
    _openedTrigger = trigger;
    _openedLessonId = lessonId;
    _openedTags = tags;
    logPrompt(
      trigger: trigger,
      lessonId: lessonId,
      tags: tags,
      dismissed: false,
    );
  }

  void recapClosed() {
    if (_openedAt == null || _openedTrigger == null) return;
    final duration = DateTime.now().difference(_openedAt!);
    final event = RecallEvent(
      trigger: _openedTrigger!,
      lessonId: _openedLessonId,
      tags: _openedTags,
      action: duration >= const Duration(seconds: 15) ? 'completed' : 'closed',
      timestamp: DateTime.now(),
      viewDuration: duration,
    );
    _events.add(event);
    UserActionLogger.instance.logEvent(event.toJson());
    _openedAt = null;
    _openedTrigger = null;
    _openedLessonId = null;
    _openedTags = null;
    notifyListeners();
  }

  List<RecallEvent> getRecent({int limit = 50}) {
    return _events.reversed.take(limit).toList();
  }
}

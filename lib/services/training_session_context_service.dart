import 'dart:async';

import 'package:uuid/uuid.dart';

import '../models/training_session_fingerprint.dart';
import 'user_action_logger.dart';

class TrainingSessionContextService {
  TrainingSessionContextService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;
  TrainingSessionFingerprint? _current;

  TrainingSessionFingerprint start({
    required String packId,
    required String trainingType,
    List<String> includedTags = const [],
    List<String> involvedLines = const [],
    String source = 'manual',
  }) {
    final fp = TrainingSessionFingerprint(
      sessionId: _uuid.v4(),
      startedAt: DateTime.now(),
      packId: packId,
      trainingType: trainingType,
      includedTags: includedTags,
      involvedLines: involvedLines,
      source: source,
    );
    _current = fp;
    unawaited(UserActionLogger.instance.logEvent({
      'event': 'trainingSessionStart',
      ...fp.toJson(),
    }));
    return fp;
  }

  TrainingSessionFingerprint? getCurrentSessionFingerprint() => _current;
}


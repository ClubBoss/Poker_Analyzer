import '../models/action_evaluation_request.dart';
import 'package:uuid/uuid.dart';

/// Handles encoding and decoding of evaluation queue requests.
class EvaluationQueueSerializer {
  EvaluationQueueSerializer();

  /// Encodes lists of requests into a JSON-friendly map.
  Map<String, dynamic> encodeQueues({
    required List<ActionEvaluationRequest> pending,
    required List<ActionEvaluationRequest> failed,
    required List<ActionEvaluationRequest> completed,
  }) {
    return {
      'pending': [for (final e in pending) e.toJson()],
      'failed': [for (final e in failed) e.toJson()],
      'completed': [for (final e in completed) e.toJson()],
    };
  }

  /// Decodes a JSON representation into request queues.
  Map<String, List<ActionEvaluationRequest>> decodeQueues(dynamic json) {
    if (json is List) {
      return {
        'pending': decodeList(json),
        'failed': <ActionEvaluationRequest>[],
        'completed': <ActionEvaluationRequest>[],
      };
    } else if (json is Map) {
      return {
        'pending': decodeList(json['pending']),
        'failed': decodeList(json['failed']),
        'completed': decodeList(json['completed']),
      };
    }
    throw const FormatException();
  }

  ActionEvaluationRequest _decodeRequest(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    if (map['id'] == null ||
        map['id'] is! String ||
        (map['id'] as String).isEmpty) {
      map['id'] = const Uuid().v4();
    }
    return ActionEvaluationRequest.fromJson(map);
  }

  List<ActionEvaluationRequest> decodeList(dynamic list) {
    final items = <ActionEvaluationRequest>[];
    if (list is List) {
      for (final item in list) {
        if (item is Map) {
          try {
            items.add(_decodeRequest(Map<String, dynamic>.from(item)));
          } catch (_) {}
        }
      }
    }
    return items;
  }
}

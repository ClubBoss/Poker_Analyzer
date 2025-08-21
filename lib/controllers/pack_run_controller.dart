import '../models/pack_run_session_state.dart';
import '../models/recall_snippet_result.dart';
import '../models/theory_snippet.dart';
import '../services/theory_index_service.dart';
import '../services/learning_path_telemetry.dart';

class PackRunController {
  static const int _tagCooldown = 10;
  static const int _globalCooldown = 3;

  final TheoryIndexService _theoryIndex;
  final PackRunSessionState _state;
  final LearningPathTelemetry _telemetry;
  final String packId;
  final String sessionId;

  PackRunController({
    required this.packId,
    required this.sessionId,
    TheoryIndexService? theoryIndex,
    PackRunSessionState? state,
    LearningPathTelemetry? telemetry,
  })  : _theoryIndex = theoryIndex ?? TheoryIndexService(),
        _state = state ?? PackRunSessionState(),
        _telemetry = telemetry ?? LearningPathTelemetry.instance;

  Future<RecallSnippetResult?> onResult(
    String spotId,
    bool correct,
    List<String> tags,
  ) async {
    _state.handCounter++;
    RecallSnippetResult? result;

    if (!correct) {
      final attempt = (_state.attemptsBySpot[spotId] ?? 0) + 1;
      _state.attemptsBySpot[spotId] = attempt;

      final canShow = attempt == 1 &&
          _state.recallShownBySpot[spotId] != true &&
          _state.handCounter - _state.lastShownAt >= _globalCooldown &&
          tags.isNotEmpty;

      if (canShow) {
        for (final tag in tags) {
          final last = _state.tagLastShown[tag];
          if (last != null && _state.handCounter - last < _tagCooldown) {
            final remaining = _tagCooldown - (_state.handCounter - last);
            _telemetry.log('inline_theory_skipped_cooldown', {
              'packId': packId,
              'sessionId': sessionId,
              'tagId': tag,
              'cooldownRemaining': remaining,
            });
            continue;
          }
          final snippets = await _theoryIndex.snippetsForTag(tag);
          if (snippets.isEmpty) continue;
          final history = _state.recallHistory[tag] ?? <String>[];
          TheorySnippet snippet;
          try {
            snippet = snippets.firstWhere((s) => !history.contains(s.id));
          } catch (_) {
            snippet = snippets.first; // fallback
            history.clear();
          }
          history.add(snippet.id);
          _state.recallHistory[tag] = history;
          _state.recallShownBySpot[spotId] = true;
          _state.tagLastShown[tag] = _state.handCounter;
          _state.lastShownAt = _state.handCounter;
          _telemetry.log('inline_theory_shown', {
            'packId': packId,
            'sessionId': sessionId,
            'spotIndex': _state.handCounter,
            'tagId': tag,
            'snippetId': snippet.id,
          });
          result = RecallSnippetResult(
            tagId: tag,
            snippet: snippet,
            allSnippets: snippets,
          );
          break;
        }
      }
    }

    await _state.save();
    return result;
  }

  // Telemetry handled via [LearningPathTelemetry].
}

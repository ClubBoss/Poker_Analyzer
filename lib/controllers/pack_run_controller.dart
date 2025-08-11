import '../models/pack_run_session_state.dart';
import '../models/recall_snippet_result.dart';
import '../models/theory_snippet.dart';
import '../services/theory_index_service.dart';

class PackRunController {
  static const int _tagCooldown = 10;
  static const int _globalCooldown = 3;

  final TheoryIndexService _theoryIndex;
  final PackRunSessionState _state;

  PackRunController({TheoryIndexService? theoryIndex, PackRunSessionState? state})
      : _theoryIndex = theoryIndex ?? TheoryIndexService(),
        _state = state ?? PackRunSessionState();

  Future<RecallSnippetResult?> onResult(
      String spotId, bool correct, List<String> tags) async {
    _state.handCounter++;
    if (correct) {
      await _state.save();
      return null;
    }
    final attempt = (_state.attemptsBySpot[spotId] ?? 0) + 1;
    _state.attemptsBySpot[spotId] = attempt;
    if (attempt > 1) {
      await _state.save();
      return null;
    }
    if (_state.recallShownBySpot[spotId] == true) {
      await _state.save();
      return null;
    }
    if (_state.handCounter - _state.lastShownAt < _globalCooldown) {
      await _state.save();
      return null;
    }
    if (tags.isEmpty) {
      await _state.save();
      return null;
    }

    for (final tag in tags) {
      final last = _state.tagLastShown[tag];
      if (last != null && _state.handCounter - last < _tagCooldown) {
        _logTelemetry(tag, '', true);
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
      await _state.save();
      _logTelemetry(tag, snippet.id, false);
      return RecallSnippetResult(
        tagId: tag,
        snippet: snippet,
        allSnippets: snippets,
      );
    }
    await _state.save();
    return null;
  }

  void _logTelemetry(String tagId, String snippetId, bool cooldownSkipped) {
    // Placeholder for analytics integration.
    // ignore: avoid_print
    print(
        'recall:{tag:$tagId,snippet:$snippetId,cooldownSkipped:$cooldownSkipped}');
  }
}


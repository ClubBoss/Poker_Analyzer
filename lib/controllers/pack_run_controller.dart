import '../models/theory_snippet.dart';
import '../services/theory_index_service.dart';

class PackRunController {
  final TheoryIndexService _theoryIndex;
  final Map<String, bool> _recallShown = {};
  final Map<String, int> _attempts = {};
  final Set<String> _shownTheory = {};
  int _handCounter = 0;
  int _lastShownAt = -3;

  PackRunController({TheoryIndexService? theoryIndex})
      : _theoryIndex = theoryIndex ?? TheoryIndexService();

  Future<TheorySnippet?> onResult(
      String spotId, bool correct, List<String> tags) async {
    _handCounter++;
    if (correct) return null;
    final attempt = (_attempts[spotId] ?? 0) + 1;
    _attempts[spotId] = attempt;
    if (attempt > 1) return null;
    if (_recallShown[spotId] == true) return null;
    if (_handCounter - _lastShownAt < 3) return null;
    if (tags.isEmpty) return null;
    final snippet =
        await _theoryIndex.matchSnippet(tags, exclude: _shownTheory) ??
            const TheorySnippet.generic();
    _recallShown[spotId] = true;
    _shownTheory.add(snippet.id);
    _lastShownAt = _handCounter;
    return snippet;
  }
}

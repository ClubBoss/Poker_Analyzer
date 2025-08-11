import 'package:meta/meta.dart';
import 'theory_snippet.dart';

/// Result returned when a recall snippet should be shown.
@immutable
class RecallSnippetResult {
  final String tagId;
  final TheorySnippet snippet;
  final List<TheorySnippet> allSnippets;

  const RecallSnippetResult({
    required this.tagId,
    required this.snippet,
    required this.allSnippets,
  });
}

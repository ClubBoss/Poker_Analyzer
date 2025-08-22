import '../models/inline_theory_entry.dart';
import '../models/line_graph_result.dart';

class InlineTheoryNodeLinker {
  InlineTheoryNodeLinker();

  LineGraphResult link(
    LineGraphResult result,
    Map<String, InlineTheoryEntry> theoryIndex,
  ) {
    for (final streetNodes in result.streets.values) {
      for (final node in streetNodes) {
        _attachTheory(node, theoryIndex);
      }
    }
    return result;
  }

  void _attachTheory(
    HandActionNode node,
    Map<String, InlineTheoryEntry> theoryIndex,
  ) {
    final tag = node.tag;
    if (tag != null) {
      final entry = _findTheory(tag, theoryIndex);
      if (entry != null) {
        node.theory = entry;
      }
    }
    for (final child in node.next) {
      _attachTheory(child, theoryIndex);
    }
  }

  InlineTheoryEntry? _findTheory(
    String tag,
    Map<String, InlineTheoryEntry> index,
  ) {
    if (index.containsKey(tag)) return index[tag];
    final street = tag.replaceAll(RegExp(r'[A-Z].*'), '');
    if (street != tag && index.containsKey(street)) return index[street];
    return index['global'];
  }
}

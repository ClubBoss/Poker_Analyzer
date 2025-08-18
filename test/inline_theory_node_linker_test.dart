import 'package:test/test.dart';
import 'package:poker_analyzer/models/line_graph_result.dart';
import 'package:poker_analyzer/models/inline_theory_entry.dart';
import 'package:poker_analyzer/services/inline_theory_node_linker.dart';

void main() {
  test('links theory entry to matching action tag', () {
    final node = HandActionNode(actor: 'hero', action: 'cbet', tag: 'flopCbet');
    final result = LineGraphResult(
      heroPosition: 'btn',
      streets: {
        'flop': [node],
      },
      tags: ['flopCbet'],
    );

    const linker = InlineTheoryNodeLinker();
    final theoryMap = {
      'flopCbet': const InlineTheoryEntry(
        tag: 'flopCbet',
        htmlSnippet: '<p>C-bet theory</p>',
      ),
    };

    linker.link(result, theoryMap);

    expect(node.theory, isNotNull);
    expect(node.theory!.htmlSnippet, contains('C-bet'));
  });

  test('falls back to street-level theory when exact tag missing', () {
    final node = HandActionNode(
      actor: 'hero',
      action: 'call',
      tag: 'riverCall',
    );
    final result = LineGraphResult(
      heroPosition: 'bb',
      streets: {
        'river': [node],
      },
      tags: ['riverCall'],
    );

    const linker = InlineTheoryNodeLinker();
    final theoryMap = {
      'river': const InlineTheoryEntry(
        tag: 'river',
        htmlSnippet: '<p>River theory</p>',
      ),
    };

    linker.link(result, theoryMap);

    expect(node.theory, isNotNull);
    expect(node.theory!.htmlSnippet, contains('River theory'));
  });
}

import 'package:test/test.dart';
import 'package:poker_analyzer/tooling/generate_research_prompts.dart' as gen;

void main() {
  test('parseQueue returns first module', () {
    final ids = gen.parseQueue();
    expect(ids, isNotEmpty);
    expect(ids.first, 'core_rules_and_setup');
  });

  test('renderPrompt replaces placeholders', () {
    const tpl = '{{MODULE_ID}} {{SHORT_SCOPE}} {{SPOTKIND_ALLOWLIST}} {{TARGET_TOKENS_ALLOWLIST}}';
    final out = gen.renderPrompt(tpl, 'm1', 'scope', 'spot', 'token');
    expect(out, 'm1 scope spot token');
  });
}

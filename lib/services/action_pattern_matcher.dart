class ActionPatternMatcher {
  ActionPatternMatcher();

  bool matches(List<String> actions, List<String> pattern) {
    if (pattern.isEmpty) return true;
    if (actions.length != pattern.length) return false;
    for (var i = 0; i < pattern.length; i++) {
      final actual = actions[i].split(' ').first.toLowerCase();
      final expected = pattern[i].split(' ').first.toLowerCase();
      if (actual != expected) {
        return false;
      }
    }
    return true;
  }
}

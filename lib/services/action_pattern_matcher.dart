class ActionPatternMatcher {
  const ActionPatternMatcher();

  bool matches(List<String> actions, List<String> pattern) {
    if (pattern.isEmpty) return true;
    if (actions.length != pattern.length) return false;
    for (var i = 0; i < pattern.length; i++) {
      if (actions[i].toLowerCase() != pattern[i].toLowerCase()) {
        return false;
      }
    }
    return true;
  }
}

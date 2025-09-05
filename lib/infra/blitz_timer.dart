// ASCII-only; pure Dart.

/// Feature flag for Blitz timer instrumentation (prod default: disabled).
const bool kEnableBlitz = false;

/// Returns true if a decision exceeded the provided hint time.
///
/// When [hintMs] is null, returns false.
bool isTimedOut({required int decisionMs, required int? hintMs}) {
  return hintMs != null && decisionMs > hintMs;
}

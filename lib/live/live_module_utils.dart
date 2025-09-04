// ASCII-only; pure Dart (no imports)

/// Returns true if [id] refers to a Live overlay module.
///
/// Append-only. Checks for the canonical `live_` prefix.
bool isLiveModuleId(String id) => id.startsWith('live_');

/// Returns true if [id] refers to a practice module (cash or MTT).
///
/// Append-only. Checks for the canonical `cash_` or `mtt_` prefixes.
bool isPracticeModuleId(String id) =>
    id.startsWith('cash_') || id.startsWith('mtt_');

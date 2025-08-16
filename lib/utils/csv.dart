/// Utility helpers for working with CSV data.
///
/// Wraps [v] in quotes and doubles any existing quotes so the value can be
/// safely included in a CSV file.
String csvEscape(String v) {
  final escaped = v.replaceAll('"', '""');
  return '"$escaped"';
}


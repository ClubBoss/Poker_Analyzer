// Builds CSV for run history rows passed from UI (list of maps).
String buildHistoryCsv(List<Map<String, String?>> rows) {
  String _csv(String v) => '"${v.replaceAll('"', '""')}"';
  final b = StringBuffer()..writeln('timestamp,args,outPath,logPath');
  for (final r in rows) {
    b.writeln(
      '${_csv(r['ts'] ?? '-')},${_csv(r['args'] ?? '-')},${_csv(r['out'] ?? '-')},${_csv(r['log'] ?? '-')}',
    );
  }
  return b.toString();
}

import 'dart:io';

Future<void> writeCsv(File file, StringBuffer buffer) async {
  var csv = buffer.toString();
  if (Platform.isWindows) {
    csv = '\uFEFF' + csv.replaceAll('\n', '\r\n');
  }
  await file.writeAsString(csv);
}

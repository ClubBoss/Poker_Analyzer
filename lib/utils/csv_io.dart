import 'dart:io';

Future<void> writeCsv(File file, StringBuffer buffer, {bool? isWindows}) async {
  var csv = buffer.toString();
  final win = isWindows ?? Platform.isWindows;
  if (win) {
    csv = '\uFEFF' + csv.replaceAll('\n', '\r\n');
  }
  await file.writeAsString(csv);
}

import 'dart:io';
import 'dart:typed_data';

/// 32-bit FNV-1a hash, returns 8-char lowercase hex.
String fnv32Hex(Uint8List bytes) {
  const int prime = 0x01000193;
  var hash = 0x811c9dc5;
  for (final b in bytes) {
    hash ^= b;
    hash = (hash * prime) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

/// Reads [f] and returns its FNV-1a hash as hex.
String fnv32HexOfFile(File f) {
  final bytes = f.readAsBytesSync();
  return fnv32Hex(bytes);
}

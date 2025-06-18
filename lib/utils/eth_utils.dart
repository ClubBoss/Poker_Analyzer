// Utility functions for Ethereum address handling.

import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';

/// Checks if [address] is a valid Ethereum address in 0x-prefixed
/// hexadecimal form.
bool isValidAddress(String address) {
  final regex = RegExp(r'^0x[a-fA-F0-9]{40}\$');
  return regex.hasMatch(address);
}

/// Converts [address] to its EIP-55 checksum representation.
/// Throws an [ArgumentError] if [address] is not valid.
String toChecksumAddress(String address) {
  if (!isValidAddress(address)) {
    throw ArgumentError('Invalid Ethereum address');
  }
  final lower = address.toLowerCase().replaceFirst('0x', '');
  final hash = _keccak256(Uint8List.fromList(utf8.encode(lower)));
  final hashHex = _bytesToHex(hash);

  final buffer = StringBuffer('0x');
  for (var i = 0; i < lower.length; i++) {
    final char = lower[i];
    final hexDigit = int.parse(hashHex[i], radix: 16);
    buffer.write(hexDigit >= 8 ? char.toUpperCase() : char);
  }
  return buffer.toString();
}

/// Generates a random 20-byte Ethereum address in hex form.
String generateRandomAddress() {
  final rnd = Random.secure();
  final bytes = List<int>.generate(20, (_) => rnd.nextInt(256));
  return '0x${_bytesToHex(Uint8List.fromList(bytes))}';
}

String _bytesToHex(Uint8List bytes) {
  final buffer = StringBuffer();
  for (final b in bytes) {
    buffer.write(b.toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}
Uint8List _keccak256(Uint8List message) {
  const int rateInBytes = 136; // 1088 / 8
  final List<int> state = List<int>.filled(25, 0);
  var offset = 0;

  while (offset < message.length) {
    final length = (message.length - offset).clamp(0, rateInBytes);
    for (var i = 0; i < length; i++) {
      state[i >> 3] ^= message[offset + i] << ((i & 7) * 8);
    }
    offset += length;
    if (length == rateInBytes) {
      _keccakf(state);
    }
  }

  final padIndex = message.length % rateInBytes;
  state[padIndex >> 3] ^= 1 << ((padIndex & 7) * 8);
  state[(rateInBytes - 1) >> 3] ^= 0x80 << (((rateInBytes - 1) & 7) * 8);
  _keccakf(state);

  final out = Uint8List(32);
  for (var i = 0; i < 32; i++) {
    out[i] = (state[i >> 3] >> ((i & 7) * 8)) & 0xff;
  }
  return out;
}

int _rotl64(int x, int n) {
  n &= 63;
  return ((x << n) | (x >> (64 - n))) & 0xFFFFFFFFFFFFFFFF;
}

const List<int> _keccakfRndc = [
  0x0000000000000001,
  0x0000000000008082,
  0x800000000000808a,
  0x8000000080008000,
  0x000000000000808b,
  0x0000000080000001,
  0x8000000080008081,
  0x8000000000008009,
  0x000000000000008a,
  0x0000000000000088,
  0x0000000080008009,
  0x000000008000000a,
  0x000000008000808b,
  0x800000000000008b,
  0x8000000000008089,
  0x8000000000008003,
  0x8000000000008002,
  0x8000000000000080,
  0x000000000000800a,
  0x800000008000000a,
  0x8000000080008081,
  0x8000000000008080,
  0x0000000080000001,
  0x8000000080008008,
];

const List<int> _keccakfRotc = [
  1, 3, 6, 10, 15, 21, 28, 36, 45, 55,
  2, 14, 27, 41, 56, 8, 25, 43, 62, 18,
  39, 61, 20, 44,
];

const List<int> _keccakfPiln = [
  10, 7, 11, 17, 18, 3, 5, 16, 8, 21,
  24, 4, 15, 23, 19, 13, 12, 2, 20, 14,
  22, 9, 6, 1,
];
void _keccakf(List<int> state) {
  final List<int> temp = List<int>.filled(25, 0);
  for (var round = 0; round < 24; round++) {
    // Theta
    final List<int> bc = List<int>.filled(5, 0);
    for (var i = 0; i < 5; i++) {
      bc[i] = state[i] ^ state[i + 5] ^ state[i + 10] ^ state[i + 15] ^ state[i + 20];
    }
    for (var i = 0; i < 5; i++) {
      final t = bc[(i + 4) % 5] ^ _rotl64(bc[(i + 1) % 5], 1);
      for (var j = 0; j < 25; j += 5) {
        state[j + i] ^= t;
      }
    }

    // Rho and Pi
    var t = state[1];
    for (var i = 0; i < 24; i++) {
      final j = _keccakfPiln[i];
      temp[0] = state[j];
      state[j] = _rotl64(t, _keccakfRotc[i]);
      t = temp[0];
    }

    // Chi
    for (var j = 0; j < 25; j += 5) {
      final x0 = state[j];
      final x1 = state[j + 1];
      final x2 = state[j + 2];
      final x3 = state[j + 3];
      final x4 = state[j + 4];
      state[j] ^= (~x1) & x2;
      state[j + 1] ^= (~x2) & x3;
      state[j + 2] ^= (~x3) & x4;
      state[j + 3] ^= (~x4) & x0;
      state[j + 4] ^= (~x0) & x1;
    }

    // Iota
    state[0] ^= _keccakfRndc[round];
  }
}

import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Offline PIN hashing for employee login (SHA-256, not for online auth).
abstract final class PinAuth {
  static String hash(String pin) {
    final normalized = pin.trim();
    final digest = sha256.convert(utf8.encode(normalized));
    return digest.toString();
  }

  static bool verify(String pin, String storedHash) {
    if (storedHash.isEmpty) return false;
    return hash(pin) == storedHash;
  }
}

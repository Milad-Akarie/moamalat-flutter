import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../errors.dart';

/// Computes the Moamalat secure-hash for a request: `HMAC-SHA-256(key, message)`,
/// returned as an upper-case hex string. The key is supplied as a hex string
/// (the format the gateway provisions to merchants).
String secureHashHex(String message, String hexKey) {
  final keyBytes = _hexDecode(hexKey.toUpperCase());
  final mac = Hmac(sha256, keyBytes).convert(utf8.encode(message));
  return mac.toString().toUpperCase();
}

Uint8List _hexDecode(String hex) {
  if (hex.length.isOdd) {
    throw const MoamalatPaymentError(
      'Secure hash key must be an even-length hexadecimal string',
    );
  }
  final bytes = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < bytes.length; i++) {
    final value = int.tryParse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    if (value == null) {
      throw const MoamalatPaymentError(
        'Secure hash key contains non-hexadecimal characters',
      );
    }
    bytes[i] = value;
  }
  return bytes;
}

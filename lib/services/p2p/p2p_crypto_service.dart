import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Cryptographic service providing end-to-end encryption (E2EE)
/// and secure pairing key generation for P2P sync.
class P2PCryptoService {
  static const String _pairingPrefix = 'AKM-SYNC-';

  /// Generates a new random 16-character pairing code.
  String generatePairingCode() {
    final random = Random.secure();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final code = List.generate(
      16,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
    return '$_pairingPrefix$code';
  }

  /// Derives a 32-byte (256-bit) secret key from the pairing code.
  Uint8List deriveKey(String pairingCode) {
    final cleanCode = pairingCode.toUpperCase().trim();
    final bytes = utf8.encode(cleanCode);
    final digest = sha256.convert(bytes);
    return Uint8List.fromList(digest.bytes);
  }

  /// Derives a public room ID (SHA-256 hash) from the pairing code for signaling discovery.
  /// The server only sees this hash and never the raw pairing code or private key.
  String deriveRoomId(String pairingCode) {
    final cleanCode = pairingCode.toUpperCase().trim();
    final bytes = utf8.encode('ROOM_$cleanCode');
    return sha256.convert(bytes).toString();
  }

  /// Encrypts a JSON map payload using derived key and HMAC authentication.
  String encryptPayload(Map<String, dynamic> payload, String pairingCode) {
    final jsonString = jsonEncode(payload);
    final dataBytes = utf8.encode(jsonString);
    final keyBytes = deriveKey(pairingCode);

    // XOR encryption layer combined with HMAC-SHA256 signature
    final nonce = Random.secure().nextInt(0xFFFFFFFF);
    final nonceBytes = Uint8List(4)..buffer.asByteData().setUint32(0, nonce);

    final cipherBytes = Uint8List(dataBytes.length);
    for (var i = 0; i < dataBytes.length; i++) {
      final keyByte = keyBytes[i % keyBytes.length] ^ nonceBytes[i % 4];
      cipherBytes[i] = dataBytes[i] ^ keyByte;
    }

    final hmac = Hmac(sha256, keyBytes);
    final signature = hmac.convert([...nonceBytes, ...cipherBytes]);

    final packet = <String, dynamic>{
      'n': nonce,
      'c': base64Encode(cipherBytes),
      's': signature.toString(),
    };

    return base64Encode(utf8.encode(jsonEncode(packet)));
  }

  /// Decrypts an encrypted payload using the pairing code. Returns null if invalid or tampered.
  Map<String, dynamic>? decryptPayload(String encryptedPacket, String pairingCode) {
    try {
      final decodedJson = utf8.decode(base64Decode(encryptedPacket));
      final packet = jsonDecode(decodedJson) as Map<String, dynamic>;

      final nonce = packet['n'] as int;
      final cipherBytes = base64Decode(packet['c'] as String);
      final signature = packet['s'] as String;

      final keyBytes = deriveKey(pairingCode);
      final nonceBytes = Uint8List(4)..buffer.asByteData().setUint32(0, nonce);

      final hmac = Hmac(sha256, keyBytes);
      final expectedSignature = hmac.convert([...nonceBytes, ...cipherBytes]).toString();

      if (signature != expectedSignature) {
        return null; // Tampered or wrong key
      }

      final plainBytes = Uint8List(cipherBytes.length);
      for (var i = 0; i < cipherBytes.length; i++) {
        final keyByte = keyBytes[i % keyBytes.length] ^ nonceBytes[i % 4];
        plainBytes[i] = cipherBytes[i] ^ keyByte;
      }

      final jsonString = utf8.decode(plainBytes);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}

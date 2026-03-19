import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:crypto/crypto.dart';

/// AES-256-CBC encryption service.
/// The key is derived from the user's UID by hashing it with SHA-256.
class EncryptionService {
  EncryptionService._();
  static final EncryptionService instance = EncryptionService._();

  enc.Key _keyFromUid(String uid) {
    final bytes = sha256.convert(utf8.encode(uid)).bytes;
    return enc.Key(Uint8List.fromList(bytes));
  }

  /// Encrypts [plainText] using the given [uid] as the key seed.
  /// Returns a base64-encoded string: IV (16 bytes) + ciphertext.
  String encrypt(String plainText, String uid) {
    final key = _keyFromUid(uid);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    // Combine IV + ciphertext into one base64 string
    final combined = Uint8List.fromList([...iv.bytes, ...encrypted.bytes]);
    return base64Encode(combined);
  }

  /// Decrypts a base64-encoded string that was encrypted with [encrypt].
  String decrypt(String encoded, String uid) {
    try {
      final combined = base64Decode(encoded);
      final ivBytes = combined.sublist(0, 16);
      final cipherBytes = combined.sublist(16);
      final key = _keyFromUid(uid);
      final iv = enc.IV(Uint8List.fromList(ivBytes));
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      return encrypter.decrypt(
        enc.Encrypted(Uint8List.fromList(cipherBytes)),
        iv: iv,
      );
    } catch (_) {
      // If decryption fails (e.g. data was already plain text), return as-is
      return encoded;
    }
  }

  /// Returns true if [text] looks like an AES-encrypted base64 blob.
  bool isEncrypted(String text) {
    try {
      final decoded = base64Decode(text);
      return decoded.length >= 32; // At least IV + 1 block
    } catch (_) {
      return false;
    }
  }
}

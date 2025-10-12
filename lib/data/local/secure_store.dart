import 'dart:convert';
import 'dart:math';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStore {
  SecureStore({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  static const _masterKey = 'takva_master_key';
  final FlutterSecureStorage _storage;

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<String?> readEncrypted(String key) async {
    final encrypted = await _storage.read(key: key);
    if (encrypted == null) return null;
    final keyBytes = await _obtainKey();
    final iv = encrypt.IV.fromBase64(encrypted.split(':').first);
    final cipherText = encrypted.split(':').last;
    final encrypter = encrypt.Encrypter(encrypt.AES(keyBytes, mode: encrypt.AESMode.cbc));
    final decrypted = encrypter.decrypt(encrypt.Encrypted.fromBase64(cipherText), iv: iv);
    return decrypted;
  }

  Future<void> writeEncrypted(String key, String value) async {
    final keyBytes = await _obtainKey();
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(keyBytes, mode: encrypt.AESMode.cbc));
    final encrypted = encrypter.encrypt(value, iv: iv);
    final payload = '${iv.base64}:${encrypted.base64}';
    await _storage.write(key: key, value: payload);
  }

  Future<encrypt.Key> _obtainKey() async {
    final existing = await _storage.read(key: _masterKey);
    if (existing != null) {
      return encrypt.Key.fromBase64(existing);
    }
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final base64Key = base64Encode(bytes);
    await _storage.write(key: _masterKey, value: base64Key);
    return encrypt.Key(bytes);
  }
}

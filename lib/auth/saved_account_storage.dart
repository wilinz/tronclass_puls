import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:tronclass/data/get_storage.dart';

class SavedAccount {
  final String username;
  final String encryptedPassword;
  final String iv;
  final DateTime updatedAt;

  SavedAccount({
    required this.username,
    required this.encryptedPassword,
    required this.iv,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'encryptedPassword': encryptedPassword,
      'iv': iv,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SavedAccount.fromMap(Map<String, dynamic> map) {
    return SavedAccount(
      username: map['username'] as String,
      encryptedPassword: map['encryptedPassword'] as String,
      iv: map['iv'] as String,
      updatedAt:
          DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class SavedAccountStorage {
  static const _ivLength = 16;

  static final Random _random = Random.secure();

  static encrypt.Encrypter _buildEncrypter() {
    final keyBytes = _loadOrCreateKey();
    final key = encrypt.Key(keyBytes);
    return encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
    );
  }

  static Uint8List _loadOrCreateKey() {
    final stored = getStorage.read<String>(GetStorageKeys.accountEncryptionKey);
    if (stored != null && stored.isNotEmpty) {
      return Uint8List.fromList(base64Decode(stored));
    }
    final keyBytes = _randomBytes(32);
    getStorage.write(
      GetStorageKeys.accountEncryptionKey,
      base64Encode(keyBytes),
    );
    return keyBytes;
  }

  static List<SavedAccount> loadAccounts() {
    final rawList =
        getStorage.read<List<dynamic>>(GetStorageKeys.savedAccounts) ?? [];
    return rawList
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .map(SavedAccount.fromMap)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  static Future<void> _persist(List<SavedAccount> accounts) async {
    await getStorage.write(
      GetStorageKeys.savedAccounts,
      accounts.map((e) => e.toMap()).toList(),
    );
  }

  static Future<void> upsertAccount({
    required String username,
    required String password,
  }) async {
    final accounts = loadAccounts();
    final ivBytes = _randomBytes(_ivLength);
    final iv = encrypt.IV(ivBytes);
    final encrypted = _buildEncrypter().encrypt(password, iv: iv);

    final updated = SavedAccount(
      username: username,
      encryptedPassword: encrypted.base64,
      iv: base64Encode(ivBytes),
      updatedAt: DateTime.now(),
    );

    accounts.removeWhere((element) => element.username == username);
    accounts.insert(0, updated);
    await _persist(accounts);
  }

  static Future<void> removeAccount(String username) async {
    final accounts = loadAccounts()..removeWhere((e) => e.username == username);
    await _persist(accounts);
  }

  static String? decryptPassword(SavedAccount account) {
    try {
      final iv = encrypt.IV(base64Decode(account.iv));
      final encrypted = encrypt.Encrypted.from64(account.encryptedPassword);
      return _buildEncrypter().decrypt(encrypted, iv: iv);
    } catch (_) {
      return null;
    }
  }

  static Uint8List _randomBytes(int length) {
    final bytes = List<int>.generate(length, (_) => _random.nextInt(256));
    return Uint8List.fromList(bytes);
  }
}

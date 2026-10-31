import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Login secrets kept out of the SQLite database, in the platform's secure
/// storage (Android Keystore, iOS Keychain).
///
/// The `users` table then holds empty strings in these columns. Accounts
/// stored by older versions are moved over on the next load. If the secure
/// storage fails on a device, the secrets simply stay in the database, so
/// nobody gets logged out by this.
class TokenVault {
  /// Columns of the `users` table that hold login secrets.
  static const secretColumns = [
    "access_token",
    "refresh_token",
    "idp_application",
    "idp_remember_browser",
  ];

  static SecretStore store = _PlatformStore();

  static String _key(String userId) => "tinta_login_$userId";

  /// Moves the secrets of [row] into secure storage and returns the row to
  /// write to the database (secrets blanked). On failure [row] is returned
  /// unchanged.
  static Future<Map<String, dynamic>> stash(
      String userId, Map<String, dynamic> row) async {
    final secrets = {for (final c in secretColumns) c: row[c] ?? ""};
    try {
      await store.write(_key(userId), jsonEncode(secrets));
    } catch (e) {
      debugPrint("TokenVault: secure storage write failed (${e.runtimeType})");
      return row;
    }
    return {...row, for (final c in secretColumns) c: ""};
  }

  /// Fills the secrets of a database [row] from secure storage. A row that
  /// still has secrets in it (older version) is returned as is, and
  /// `needsMigration` tells whether the caller should re-store it.
  static Future<({Map<String, dynamic> row, bool needsMigration})> restore(
      String userId, Map<String, dynamic> row) async {
    final hasInlineSecrets =
        secretColumns.any((c) => (row[c] ?? "").toString().isNotEmpty);
    if (hasInlineSecrets) return (row: row, needsMigration: true);
    try {
      final raw = await store.read(_key(userId));
      if (raw == null) return (row: row, needsMigration: false);
      final secrets = (jsonDecode(raw) as Map).cast<String, dynamic>();
      return (
        row: {...row, for (final c in secretColumns) c: secrets[c] ?? ""},
        needsMigration: false,
      );
    } catch (e) {
      debugPrint("TokenVault: secure storage read failed (${e.runtimeType})");
      return (row: row, needsMigration: false);
    }
  }

  static Future<void> remove(String userId) async {
    try {
      await store.delete(_key(userId));
    } catch (_) {}
  }
}

/// Storage backend, replaceable in tests.
abstract class SecretStore {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
}

class _PlatformStore implements SecretStore {
  // resetOnError: false, so a Keystore problem surfaces as an error (and the
  // database fallback kicks in) instead of silently wiping the secrets.
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: false),
  );

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

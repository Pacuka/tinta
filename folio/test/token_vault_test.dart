import 'package:flutter_test/flutter_test.dart';
import 'package:folio/database/token_vault.dart';

class FakeStore implements SecretStore {
  final data = <String, String>{};
  bool broken = false;
  @override
  Future<void> write(String key, String value) async {
    if (broken) throw Exception("keystore");
    data[key] = value;
  }

  @override
  Future<String?> read(String key) async {
    if (broken) throw Exception("keystore");
    return data[key];
  }

  @override
  Future<void> delete(String key) async => data.remove(key);
}

void main() {
  late FakeStore fake;
  setUp(() => TokenVault.store = fake = FakeStore());

  final row = {
    "id": "u1",
    "name": "Diák",
    "access_token": "AT",
    "refresh_token": "RT",
    "idp_application": "IDP",
    "idp_remember_browser": "",
  };

  test('stash blanks the secrets in the database row', () async {
    final out = await TokenVault.stash("u1", row);
    expect(out["access_token"], "");
    expect(out["refresh_token"], "");
    expect(out["idp_application"], "");
    expect(out["name"], "Diák");
    expect(fake.data.keys, ["tinta_login_u1"]);
  });

  test('restore puts the secrets back', () async {
    final blank = await TokenVault.stash("u1", row);
    final r = await TokenVault.restore("u1", blank);
    expect(r.needsMigration, isFalse);
    expect(r.row["access_token"], "AT");
    expect(r.row["refresh_token"], "RT");
    expect(r.row["idp_application"], "IDP");
  });

  test('a row from an older version asks for migration', () async {
    final r = await TokenVault.restore("u1", row);
    expect(r.needsMigration, isTrue);
    expect(r.row["access_token"], "AT");
  });

  test('broken secure storage keeps the tokens in the database', () async {
    fake.broken = true;
    final out = await TokenVault.stash("u1", row);
    expect(out["access_token"], "AT");
  });

  test('remove deletes the secrets', () async {
    await TokenVault.stash("u1", row);
    await TokenVault.remove("u1");
    expect(fake.data, isEmpty);
  });
}

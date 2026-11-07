import 'package:flutter_test/flutter_test.dart';
import 'package:folio_kreta_api/models/message.dart';
import 'package:folio_mobile_ui/pages/messages/messages_page.dart';

SendRecipient _r(int id) => SendRecipient.fromJson({
      'oktatasiAzonosito': '$id',
      'kretaAzonosito': id,
      'nev': 'Tanár $id',
    }, SendRecipientType.fromJson(
        {'azonosito': 1, 'kod': 'TANAR', 'leiras': '', 'nev': '', 'rovidNev': ''}));

void main() {
  test('offline with a saved list still opens compose', () async {
    final result = await loadComposeRecipients(
      () => throw 'offline',
      () => [_r(1), _r(2)],
    );
    expect(result?.length, 2);
  });

  test('offline without a saved list returns null', () async {
    final result = await loadComposeRecipients(
      () => throw 'offline',
      () => const [],
    );
    expect(result, isNull);
  });

  test('online with no recipients still opens compose', () async {
    final result = await loadComposeRecipients(
      () async {},
      () => const [],
    );
    expect(result, isEmpty);
  });

  test('duplicates are removed', () async {
    final result = await loadComposeRecipients(
      () async {},
      () => [_r(1), _r(1), _r(2)],
    );
    expect(result?.length, 2);
  });
}

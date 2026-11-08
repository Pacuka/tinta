import 'package:flutter_test/flutter_test.dart';
import 'package:folio_kreta_api/client/api.dart';
import 'package:folio_kreta_api/client/client.dart';

void main() {
  const api = "https://kamu.e-kreta.hu/ellenorzo/V3/Sajat/Ertekelesek";

  AuthRetry retry({
    String url = api,
    bool autoHeader = true,
    int attempt = 0,
    String? sentAuth = "Bearer old",
    String? currentToken = "old",
  }) =>
      unauthorizedRetry(
        url: url,
        autoHeader: autoHeader,
        attempt: attempt,
        sentAuth: sentAuth,
        currentToken: currentToken,
      );

  test('expired token: refresh, then retry', () {
    expect(retry(), AuthRetry.refresh);
  });

  test('another request already refreshed: resend with the new token', () {
    expect(retry(currentToken: "new"), AuthRetry.resend);
  });

  test('only one retry', () {
    expect(retry(attempt: 1), AuthRetry.none);
    expect(retry(attempt: 1, currentToken: "new"), AuthRetry.none);
  });

  test('never for the IDP: the refresh itself goes there', () {
    expect(retry(url: KretaAPI.login), AuthRetry.none);
  });

  test('caller-managed headers are left alone', () {
    expect(retry(autoHeader: false), AuthRetry.none);
  });

  test('no token at all: refresh', () {
    expect(retry(sentAuth: null, currentToken: null), AuthRetry.refresh);
    expect(retry(sentAuth: null, currentToken: ""), AuthRetry.refresh);
  });
}

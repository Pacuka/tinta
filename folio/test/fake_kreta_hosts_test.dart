import 'package:flutter_test/flutter_test.dart';
import 'package:folio_kreta_api/client/api.dart';

void main() {
  tearDown(() => BaseKreta.fakeHost = null);

  test('real KRÉTA hosts by default', () {
    expect(KretaAPI.grades('abc'),
        'https://abc.e-kreta.hu/ellenorzo/V3/Sajat/Ertekelesek');
    expect(KretaAPI.login, 'https://idp.e-kreta.hu/connect/token');
    expect(KretaAPI.sendMessage,
        'https://eugyintezes.e-kreta.hu/api/v1/kommunikacio/uzenetek');
    expect(BaseKreta.isIdpUrl('https://idp.e-kreta.hu/connect/token'), isTrue);
    expect(BaseKreta.isIdpUrl('https://abc.e-kreta.hu/ellenorzo/V3/x'), isFalse);
  });

  test('fake KRÉTA sends everything to the local server', () {
    BaseKreta.fakeHost = 'http://127.0.0.1:8765';
    expect(KretaAPI.grades('abc'),
        'http://127.0.0.1:8765/ellenorzo/V3/Sajat/Ertekelesek');
    expect(KretaAPI.login, 'http://127.0.0.1:8765/connect/token');
    expect(KretaAPI.sendMessage,
        'http://127.0.0.1:8765/api/v1/kommunikacio/uzenetek');
    expect(KretaAPI.uploadAttachment, 'http://127.0.0.1:8765/ideiglenesfajlok');
    expect(BaseKreta.isIdpUrl('http://127.0.0.1:8765/connect/token'), isTrue);
    expect(BaseKreta.isIdpUrl('http://127.0.0.1:8765/ellenorzo/V3/x'), isFalse);
  });
}

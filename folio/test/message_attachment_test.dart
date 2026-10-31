import 'package:flutter_test/flutter_test.dart';
import 'package:folio/helpers/attachment_helper.dart';
import 'package:folio_kreta_api/models/justification.dart';
import 'package:folio_kreta_api/providers/message_provider.dart';

void main() {
  test('upload response keeps the temp id and the path', () {
    final f = parseTempFile(
        {"fajlAzonosito": "abc", "fajlMeretByteLength": 12, "utvonal": "tmp/abc"},
        "orvosi.pdf")!;
    expect(f.tempId, "abc");
    expect(f.path, "tmp/abc");
  });

  test('message attachment matches the official AttachmentDto', () {
    const f = UploadedFile(name: "kep.jpg", tempId: "abc", path: "tmp/abc");
    expect(messageAttachmentJson(f), {
      "azonosito": "0",
      "fajlNev": "kep.jpg",
      "fajl": {
        "fileHandler": "Local",
        "ideiglenesFajlAzonosito": "abc",
        "utvonal": "tmp/abc",
      },
    });
  });

  test('path is left out when KRÉTA did not return one', () {
    const f = UploadedFile(name: "a.pdf", tempId: "x");
    expect((messageAttachmentJson(f)["fajl"] as Map).containsKey("utvonal"),
        isFalse);
  });

  test('send result: empty 200 body is a success', () {
    expect(sendResult(200, ""), 'successfully_sent');
    expect(sendResult(null, null), 'send_failed');
    expect(sendResult(500, "{}"), 'send_failed');
    expect(sendResult(400, '{"hibakod":"UzenetKuldesEngedelyRule"}'),
        'send_permission_error');
  });

  test('attachment names cannot escape the cache folder', () {
    expect(safeAttachmentName("../../etc/passwd"), "_.._etc_passwd");
    expect(safeAttachmentName("kep.jpg"), "kep.jpg");
    expect(safeAttachmentName(".."), "csatolmany");
    expect(safeAttachmentName("a/b\\c.pdf"), "a_b_c.pdf");
  });
}

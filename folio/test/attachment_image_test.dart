import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio_kreta_api/client/client.dart';
import 'package:folio_kreta_api/models/attachment.dart';
import 'package:folio_kreta_api/models/homework.dart';
import 'package:folio_mobile_ui/common/widgets/message/attachment_image.dart';
import 'package:http/http.dart' as http;

void main() {
  test('an error page is never treated as the downloaded file', () {
    expect(downloadedBytes(http.Response('kep', 200)), isNotEmpty);
    expect(downloadedBytes(http.Response('{"Message":"nincs"}', 404)), isNull);
    expect(downloadedBytes(http.Response('hiba', 500)), isNull);
  });

  test('image names are recognised in any case', () {
    for (final name in ['a.jpg', 'FOTO.JPG', 'Kep.Jpeg', 'b.PNG']) {
      expect(HomeworkAttachment(id: '1', name: name).isImage, isTrue);
      expect(
          Attachment(id: 1, name: name, kretaFilePath: '').isImage, isTrue);
    }
    expect(HomeworkAttachment(id: '1', name: 'lap.pdf').isImage, isFalse);
  });

  testWidgets('failed download shows a retry row and tapping it retries',
      (tester) async {
    int calls = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AttachmentImage(
          name: 'hianyzo.jpg',
          download: () async {
            calls++;
            return '';
          },
          onOpen: (_) {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.broken_image_rounded), findsOneWidget);
    expect(find.text('hianyzo.jpg'), findsOneWidget);
    expect(calls, 1);

    await tester.tap(find.text('hianyzo.jpg'));
    await tester.pumpAndSettle();
    expect(calls, 2);
  });
}

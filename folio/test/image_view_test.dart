import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio_mobile_ui/common/widgets/message/image_view.dart';
import 'package:photo_view/photo_view.dart';

void main() {
  testWidgets('image fills the screen with no bar across it', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ImageView('nincs.png')));
    await tester.pump();

    expect(find.byType(AppBar), findsNothing);
    expect(tester.getRect(find.byType(PhotoView)),
        Offset.zero & tester.view.physicalSize / tester.view.devicePixelRatio);
    expect(find.byType(BackButton), findsOneWidget);
  });

  // Message attachments open the picture in a bottom sheet, whose loose
  // constraints let a bare Stack shrink to a strip at the bottom.
  testWidgets('image fills the screen in a bottom sheet too', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => showModalBottomSheet(
            isScrollControlled: true,
            context: context,
            builder: (context) => const ImageView('nincs.png'),
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Sheets are width-capped on wide test screens, so check the height.
    final rect = tester.getRect(find.byType(PhotoView));
    expect(rect.top, 0.0);
    expect(rect.height,
        tester.view.physicalSize.height / tester.view.devicePixelRatio);
  });
}

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
}

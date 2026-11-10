import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio/helpers/reduce_transparency.dart';

const _channel = MethodChannel('app.zan1456.folio/accessibility');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    ReduceTransparency.enabled.value = false;
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(_channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('no native side: stays off and does not throw', () async {
    await ReduceTransparency.init();
    expect(ReduceTransparency.enabled.value, isFalse);
  });

  test('reads the iOS setting at start', () async {
    messenger.setMockMethodCallHandler(_channel, (call) async {
      expect(call.method, 'reduceTransparency');
      return true;
    });
    await ReduceTransparency.init();
    expect(ReduceTransparency.enabled.value, isTrue);
  });

  test('follows changes sent from iOS', () async {
    messenger.setMockMethodCallHandler(_channel, (call) async => true);
    await ReduceTransparency.init();
    await messenger.handlePlatformMessage(
      _channel.name,
      _channel.codec.encodeMethodCall(
          const MethodCall('reduceTransparencyChanged', false)),
      (_) {},
    );
    expect(ReduceTransparency.enabled.value, isFalse);
  });

  test('other platforms never ask the channel', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    var asked = false;
    messenger.setMockMethodCallHandler(_channel, (call) async {
      asked = true;
      return true;
    });
    await ReduceTransparency.init();
    expect(asked, isFalse);
    expect(ReduceTransparency.enabled.value, isFalse);
  });
}

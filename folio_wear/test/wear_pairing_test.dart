import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio_wear/providers/wear_data_provider.dart';

const _channel = MethodChannel('app.zan1456.folio.wear/data');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> requests;
  late int syncs;
  late Map<String, Object?> cached;

  setUp(() {
    requests = [];
    syncs = 0;
    cached = {'connected': true, 'isPaired': false, 'pairingCode': ''};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
      if (call.method == 'getCachedData') return cached;
      if (call.method == 'requestSync') syncs++;
      if (call.method == 'sendPairingRequest') {
        requests.add(call.arguments as String);
      }
      return null;
    });
  });

  Future<void> fromNative(String method, Object? args) async {
    final data = const StandardMethodCodec()
        .encodeMethodCall(MethodCall(method, args));
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(_channel.name, data, (_) {});
  }

  testWidgets('first start: a generated code is sent to the phone',
      (tester) async {
    final data = WearDataProvider();
    await tester.pump();
    expect(data.loaded, isTrue);
    expect(data.pairingCode.length, 6);
    expect(requests, [data.pairingCode]);
    data.dispose();
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('keeps asking until the phone confirms the code',
      (tester) async {
    final data = WearDataProvider();
    await tester.pump();
    await tester.pump(WearDataProvider.pairingRetryInterval);
    await tester.pump(WearDataProvider.pairingRetryInterval);
    expect(requests.length, 3);

    await fromNative('onPairConfirmed', data.pairingCode);
    await tester.pump(WearDataProvider.pairingRetryInterval * 3);
    expect(data.isPaired, isTrue);
    expect(requests.length, 3);
    data.dispose();
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('wrong code does not pair', (tester) async {
    final data = WearDataProvider();
    await tester.pump();
    await fromNative('onPairConfirmed', 'nem-jo');
    expect(data.isPaired, isFalse);
    data.dispose();
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('no phone connected: nothing sent until it appears',
      (tester) async {
    cached['connected'] = false;
    final data = WearDataProvider();
    await tester.pump();
    await tester.pump(WearDataProvider.pairingRetryInterval);
    expect(requests, isEmpty);

    await fromNative('onConnectionChanged', true);
    expect(requests, [data.pairingCode]);
    data.dispose();
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('already paired watch never asks', (tester) async {
    cached
      ..['isPaired'] = true
      ..['pairingCode'] = '123456';
    final data = WearDataProvider();
    await tester.pump();
    await tester.pump(WearDataProvider.pairingRetryInterval);
    expect(data.isPaired, isTrue);
    expect(requests, isEmpty);
    data.dispose();
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('saved offline mode is ignored', (tester) async {
    cached['offlineMode'] = true;
    final data = WearDataProvider();
    await tester.pump();
    expect(syncs, 1);
    data.dispose();
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('coming back to the foreground asks the phone for fresh data',
      (tester) async {
    cached
      ..['isPaired'] = true
      ..['pairingCode'] = '123456';
    final data = WearDataProvider();
    await tester.pump();
    expect(syncs, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(syncs, 2);
    data.dispose();
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('pairing requests stop while paused and restart on resume',
      (tester) async {
    final data = WearDataProvider();
    await tester.pump();
    expect(requests.length, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(WearDataProvider.pairingRetryInterval * 3);
    expect(requests.length, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(requests.length, 2);
    data.dispose();
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('after unpair a new code is offered', (tester) async {
    cached
      ..['isPaired'] = true
      ..['pairingCode'] = '123456';
    final data = WearDataProvider();
    await tester.pump();
    await data.unpair();
    await tester.pump();
    expect(data.isPaired, isFalse);
    expect(requests, [data.pairingCode]);
    data.dispose();
    await tester.pump(const Duration(seconds: 5));
  });
}

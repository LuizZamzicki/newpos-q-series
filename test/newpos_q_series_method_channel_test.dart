import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newpos_q_series/newpos_q_series_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelPrinterNewposQ platform = MethodChannelPrinterNewposQ();
  const MethodChannel channel = MethodChannel('newpos_q_series');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return '42';
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}

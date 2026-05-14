import 'package:flutter_test/flutter_test.dart';
import 'package:newpos_q_series/newpos_q_series.dart';
import 'package:newpos_q_series/newpos_q_series_platform_interface.dart';
import 'package:newpos_q_series/newpos_q_series_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPrinterNewposQPlatform
    with MockPlatformInterfaceMixin
    implements PrinterNewposQPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<bool> bind({Duration timeout = const Duration(seconds: 10)}) =>
      Future.value(true);

  @override
  Future<void> unbind() => Future.value();

  @override
  Future<bool> isBound() => Future.value(true);

  @override
  Future<Map<String, Object?>> diagnostics() =>
      Future.value(<String, Object?>{'packageInstalled': true});

  @override
  Future<NewposQPrinterStatus> getPrinterStatus() =>
      Future.value(NewposQPrinterStatus.normal);

  @override
  Stream<NewposQStatusEvent> get statusEvents => const Stream.empty();

  @override
  Future<List<bool>> execute(
    NewposQPrintJob job, {
    Duration timeout = const Duration(seconds: 10),
  }) => Future.value(<bool>[true]);
}

void main() {
  final PrinterNewposQPlatform initialPlatform =
      PrinterNewposQPlatform.instance;

  test('$MethodChannelPrinterNewposQ is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPrinterNewposQ>());
  });

  test('getPlatformVersion', () async {
    final printerNewposQPlugin = PrinterNewposQ();
    final fakePlatform = MockPrinterNewposQPlatform();
    PrinterNewposQPlatform.instance = fakePlatform;

    expect(await printerNewposQPlugin.getPlatformVersion(), '42');
  });
}

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'newpos_q_series_platform_interface.dart';
import 'src/models.dart';
import 'src/print_job.dart';

/// An implementation of [PrinterNewposQPlatform] that uses method channels.
class MethodChannelPrinterNewposQ extends PrinterNewposQPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('newpos_q_series');

  @visibleForTesting
  final statusEventChannel = const EventChannel('newpos_q_series/status');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<bool> bind({Duration timeout = const Duration(seconds: 10)}) async {
    return await methodChannel.invokeMethod<bool>('bind', <String, Object?>{
          'timeoutMs': timeout.inMilliseconds,
        }) ??
        false;
  }

  @override
  Future<void> unbind() async {
    await methodChannel.invokeMethod<void>('unbind');
  }

  @override
  Future<bool> isBound() async {
    return await methodChannel.invokeMethod<bool>('isBound') ?? false;
  }

  @override
  Future<Map<String, Object?>> diagnostics() async {
    final result = await methodChannel.invokeMapMethod<String, Object?>(
      'diagnostics',
    );
    return result ?? <String, Object?>{};
  }

  @override
  Future<NewposQPrinterStatus> getPrinterStatus() async {
    final status = await methodChannel.invokeMethod<int>('getPrinterStatus');
    return NewposQPrinterStatus.fromCode(status ?? 5);
  }

  @override
  Stream<NewposQStatusEvent> get statusEvents {
    return statusEventChannel.receiveBroadcastStream().map((event) {
      return NewposQStatusEvent.fromMap(event as Map<dynamic, dynamic>);
    });
  }

  @override
  Future<List<bool>> execute(
    NewposQPrintJob job, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final result = await methodChannel.invokeListMethod<bool>(
      'execute',
      <String, Object?>{
        'operations': job.toJson(),
        'timeoutMs': timeout.inMilliseconds,
      },
    );
    return result ?? <bool>[];
  }
}

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'newpos_q_series_method_channel.dart';
import 'src/models.dart';
import 'src/print_job.dart';

abstract class PrinterNewposQPlatform extends PlatformInterface {
  /// Constructs a PrinterNewposQPlatform.
  PrinterNewposQPlatform() : super(token: _token);

  static final Object _token = Object();

  static PrinterNewposQPlatform _instance = MethodChannelPrinterNewposQ();

  /// The default instance of [PrinterNewposQPlatform] to use.
  ///
  /// Defaults to [MethodChannelPrinterNewposQ].
  static PrinterNewposQPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PrinterNewposQPlatform] when
  /// they register themselves.
  static set instance(PrinterNewposQPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<bool> bind({Duration timeout = const Duration(seconds: 10)}) {
    throw UnimplementedError('bind() has not been implemented.');
  }

  Future<void> unbind() {
    throw UnimplementedError('unbind() has not been implemented.');
  }

  Future<bool> isBound() {
    throw UnimplementedError('isBound() has not been implemented.');
  }

  Future<Map<String, Object?>> diagnostics() {
    throw UnimplementedError('diagnostics() has not been implemented.');
  }

  Future<NewposQPrinterStatus> getPrinterStatus() {
    throw UnimplementedError('getPrinterStatus() has not been implemented.');
  }

  Stream<NewposQStatusEvent> get statusEvents {
    throw UnimplementedError('statusEvents has not been implemented.');
  }

  Future<List<bool>> execute(
    NewposQPrintJob job, {
    Duration timeout = const Duration(seconds: 10),
  }) {
    throw UnimplementedError('execute() has not been implemented.');
  }
}

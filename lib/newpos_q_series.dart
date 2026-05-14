/// Flutter plugin for Newpos Q-series internal thermal printers.
///
/// Use [PrinterNewposQ] to bind to the vendor printer service, print receipts,
/// send images and barcodes, and listen for printer status events.
library;

import 'newpos_q_series_platform_interface.dart';
import 'src/models.dart';
import 'src/print_job.dart';

export 'src/models.dart';
export 'src/print_job.dart';

/// Main entry point for communicating with a Newpos Q-series printer.
class PrinterNewposQ {
  /// Returns the native platform version reported by the plugin.
  Future<String?> getPlatformVersion() {
    return PrinterNewposQPlatform.instance.getPlatformVersion();
  }

  /// Binds to the Newpos/IPOS printer service.
  ///
  /// Returns `true` when the service is available and the bind succeeds before
  /// [timeout].
  Future<bool> bind({Duration timeout = const Duration(seconds: 10)}) {
    return PrinterNewposQPlatform.instance.bind(timeout: timeout);
  }

  /// Unbinds from the vendor printer service.
  Future<void> unbind() {
    return PrinterNewposQPlatform.instance.unbind();
  }

  /// Returns whether the plugin is currently bound to the printer service.
  Future<bool> isBound() {
    return PrinterNewposQPlatform.instance.isBound();
  }

  /// Returns native diagnostic values useful for troubleshooting service binds.
  Future<Map<String, Object?>> diagnostics() {
    return PrinterNewposQPlatform.instance.diagnostics();
  }

  /// Reads the current printer status from the vendor service.
  Future<NewposQPrinterStatus> getPrinterStatus() {
    return PrinterNewposQPlatform.instance.getPrinterStatus();
  }

  /// Broadcast stream of printer status events emitted by Android.
  Stream<NewposQStatusEvent> get statusEvents {
    return PrinterNewposQPlatform.instance.statusEvents;
  }

  /// Executes all operations in [job].
  ///
  /// The returned list contains the success value reported by each native
  /// operation in order.
  Future<List<bool>> execute(
    NewposQPrintJob job, {
    Duration timeout = const Duration(seconds: 10),
  }) {
    return PrinterNewposQPlatform.instance.execute(job, timeout: timeout);
  }

  /// Convenience helper that prints formatted [text] and feeds paper.
  Future<List<bool>> printText(
    String text, {
    int fontSize = NewposQPrinterDefaults.fontSize,
    NewposQAlignment alignment = NewposQPrinterDefaults.alignment,
    int feedLines = NewposQPrinterDefaults.feedLines,
    Duration timeout = const Duration(seconds: 10),
  }) {
    final job = NewposQPrintJob()
      ..init()
      ..formattedText(text, fontSize: fontSize, alignment: alignment)
      ..performPrint(feedLines: feedLines);
    return execute(job, timeout: timeout);
  }
}

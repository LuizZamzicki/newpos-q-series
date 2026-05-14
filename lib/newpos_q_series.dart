import 'newpos_q_series_platform_interface.dart';
import 'src/models.dart';
import 'src/print_job.dart';

export 'src/models.dart';
export 'src/print_job.dart';

class PrinterNewposQ {
  Future<String?> getPlatformVersion() {
    return PrinterNewposQPlatform.instance.getPlatformVersion();
  }

  Future<bool> bind({Duration timeout = const Duration(seconds: 10)}) {
    return PrinterNewposQPlatform.instance.bind(timeout: timeout);
  }

  Future<void> unbind() {
    return PrinterNewposQPlatform.instance.unbind();
  }

  Future<bool> isBound() {
    return PrinterNewposQPlatform.instance.isBound();
  }

  Future<Map<String, Object?>> diagnostics() {
    return PrinterNewposQPlatform.instance.diagnostics();
  }

  Future<NewposQPrinterStatus> getPrinterStatus() {
    return PrinterNewposQPlatform.instance.getPrinterStatus();
  }

  Stream<NewposQStatusEvent> get statusEvents {
    return PrinterNewposQPlatform.instance.statusEvents;
  }

  Future<List<bool>> execute(
    NewposQPrintJob job, {
    Duration timeout = const Duration(seconds: 10),
  }) {
    return PrinterNewposQPlatform.instance.execute(job, timeout: timeout);
  }

  Future<List<bool>> printText(
    String text, {
    int fontSize = 24,
    NewposQAlignment alignment = NewposQAlignment.left,
    int feedLines = 160,
    Duration timeout = const Duration(seconds: 10),
  }) {
    final job = NewposQPrintJob()
      ..init()
      ..formattedText(text, fontSize: fontSize, alignment: alignment)
      ..performPrint(feedLines: feedLines);
    return execute(job, timeout: timeout);
  }
}

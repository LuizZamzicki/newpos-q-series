import 'dart:typed_data';

import 'models.dart';

/// Builder for a sequence of Newpos printer operations.
///
/// Methods append an operation and return this job, allowing receipt-style
/// chaining before passing the job to `PrinterNewposQ.execute`.
class NewposQPrintJob {
  /// Creates an empty print job.
  NewposQPrintJob();

  final List<Map<String, Object?>> _operations = <Map<String, Object?>>[];

  /// Returns the immutable operation list sent over the platform channel.
  List<Map<String, Object?>> toJson() => List.unmodifiable(_operations);

  /// Adds a printer initialization operation.
  NewposQPrintJob init() => _add(<String, Object?>{'type': 'init'});

  /// Sets the printer depth.
  NewposQPrintJob setDepth([int depth = NewposQPrinterDefaults.depth]) =>
      _add(<String, Object?>{'type': 'setDepth', 'depth': depth});

  /// Sets the current font size for subsequent text operations.
  NewposQPrintJob setFontSize([
    int fontSize = NewposQPrinterDefaults.fontSize,
  ]) => _add(<String, Object?>{'type': 'setFontSize', 'fontSize': fontSize});

  /// Sets the current alignment for subsequent operations.
  NewposQPrintJob setAlignment([
    NewposQAlignment alignment = NewposQPrinterDefaults.alignment,
  ]) => _add(<String, Object?>{
    'type': 'setAlignment',
    'alignment': alignment.value,
  });

  /// Feeds [lines] units of paper.
  NewposQPrintJob feedLines([int lines = NewposQPrinterDefaults.feedLines]) =>
      _add(<String, Object?>{'type': 'feedLines', 'lines': lines});

  /// Prints blank lines with the given line [height].
  NewposQPrintJob blankLines({
    int lines = 1,
    int height = NewposQPrinterDefaults.blankLineHeight,
  }) => _add(<String, Object?>{
    'type': 'blankLines',
    'lines': lines,
    'height': height,
  });

  /// Prints plain [text] using the printer's current settings.
  NewposQPrintJob text(String text) =>
      _add(<String, Object?>{'type': 'text', 'text': text});

  /// Prints [text] with explicit typeface, font size, and alignment.
  NewposQPrintJob formattedText(
    String text, {
    String typeface = 'ST',
    int fontSize = NewposQPrinterDefaults.fontSize,
    NewposQAlignment alignment = NewposQPrinterDefaults.alignment,
  }) => _add(<String, Object?>{
    'type': 'formattedText',
    'text': text,
    'typeface': typeface,
    'fontSize': fontSize,
    'alignment': alignment.value,
  });

  /// Prints table-like column text.
  ///
  /// Set [continuous] to keep the cursor on the same line according to the
  /// behavior exposed by the vendor service.
  NewposQPrintJob columns(
    List<NewposQColumn> columns, {
    bool continuous = false,
  }) {
    if (columns.isEmpty) {
      throw ArgumentError.value(columns, 'columns', 'Must not be empty');
    }

    return _add(<String, Object?>{
      'type': 'columnsText',
      'columns': columns.map((column) => column.text).toList(),
      'widths': columns.map((column) => column.width).toList(),
      'alignments': columns.map((column) => column.alignment.value).toList(),
      'continuous': continuous ? 1 : 0,
    });
  }

  /// Prints bitmap image [bytes].
  ///
  /// PNG and JPEG bytes are decoded on Android before being sent to the vendor
  /// service.
  NewposQPrintJob bitmap(
    Uint8List bytes, {
    NewposQAlignment alignment = NewposQAlignment.center,
    int size = NewposQPrinterDefaults.bitmapSize,
  }) => _add(<String, Object?>{
    'type': 'bitmap',
    'bytes': bytes,
    'alignment': alignment.value,
    'size': size,
  });

  /// Prints a one-dimensional barcode containing [data].
  NewposQPrintJob barcode(
    String data, {
    NewposQBarcodeSymbology symbology = NewposQPrinterDefaults.barcodeSymbology,
    int height = NewposQPrinterDefaults.barcodeHeight,
    int width = NewposQPrinterDefaults.barcodeWidth,
    NewposQBarcodeTextPosition textPosition =
        NewposQPrinterDefaults.barcodeTextPosition,
  }) => _add(<String, Object?>{
    'type': 'barcode',
    'data': data,
    'symbology': symbology.value,
    'height': height,
    'width': width,
    'textPosition': textPosition.value,
  });

  /// Prints a QR code containing [data].
  NewposQPrintJob qrCode(
    String data, {
    int moduleSize = NewposQPrinterDefaults.qrModuleSize,
    NewposQErrorCorrectionLevel errorCorrectionLevel =
        NewposQPrinterDefaults.qrErrorCorrectionLevel,
  }) => _add(<String, Object?>{
    'type': 'qrcode',
    'data': data,
    'moduleSize': moduleSize,
    'errorCorrectionLevel': errorCorrectionLevel.value,
  });

  /// Sends raw printer bytes to the vendor service.
  NewposQPrintJob rawData(Uint8List bytes) =>
      _add(<String, Object?>{'type': 'rawData', 'bytes': bytes});

  /// Sends ESC/POS command bytes to the vendor service.
  NewposQPrintJob escPos(Uint8List bytes) =>
      _add(<String, Object?>{'type': 'escPos', 'bytes': bytes});

  /// Flushes pending operations and feeds paper after printing.
  NewposQPrintJob performPrint({
    int feedLines = NewposQPrinterDefaults.feedLines,
  }) => _add(<String, Object?>{'type': 'performPrint', 'feedLines': feedLines});

  NewposQPrintJob _add(Map<String, Object?> operation) {
    _operations.add(operation);
    return this;
  }
}

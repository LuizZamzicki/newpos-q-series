import 'dart:typed_data';

import 'models.dart';

class NewposQPrintJob {
  NewposQPrintJob();

  final List<Map<String, Object?>> _operations = <Map<String, Object?>>[];

  List<Map<String, Object?>> toJson() => List.unmodifiable(_operations);

  NewposQPrintJob init() => _add(<String, Object?>{'type': 'init'});

  NewposQPrintJob setDepth([int depth = NewposQPrinterDefaults.depth]) =>
      _add(<String, Object?>{'type': 'setDepth', 'depth': depth});

  NewposQPrintJob setFontSize([
    int fontSize = NewposQPrinterDefaults.fontSize,
  ]) => _add(<String, Object?>{'type': 'setFontSize', 'fontSize': fontSize});

  NewposQPrintJob setAlignment([
    NewposQAlignment alignment = NewposQPrinterDefaults.alignment,
  ]) => _add(<String, Object?>{
    'type': 'setAlignment',
    'alignment': alignment.value,
  });

  NewposQPrintJob feedLines([int lines = NewposQPrinterDefaults.feedLines]) =>
      _add(<String, Object?>{'type': 'feedLines', 'lines': lines});

  NewposQPrintJob blankLines({
    int lines = 1,
    int height = NewposQPrinterDefaults.blankLineHeight,
  }) => _add(<String, Object?>{
    'type': 'blankLines',
    'lines': lines,
    'height': height,
  });

  NewposQPrintJob text(String text) =>
      _add(<String, Object?>{'type': 'text', 'text': text});

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

  NewposQPrintJob rawData(Uint8List bytes) =>
      _add(<String, Object?>{'type': 'rawData', 'bytes': bytes});

  NewposQPrintJob escPos(Uint8List bytes) =>
      _add(<String, Object?>{'type': 'escPos', 'bytes': bytes});

  NewposQPrintJob performPrint({
    int feedLines = NewposQPrinterDefaults.feedLines,
  }) => _add(<String, Object?>{'type': 'performPrint', 'feedLines': feedLines});

  NewposQPrintJob _add(Map<String, Object?> operation) {
    _operations.add(operation);
    return this;
  }
}

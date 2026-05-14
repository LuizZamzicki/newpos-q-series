import 'dart:typed_data';

import 'models.dart';

class NewposQPrintJob {
  NewposQPrintJob();

  final List<Map<String, Object?>> _operations = <Map<String, Object?>>[];

  List<Map<String, Object?>> toJson() => List.unmodifiable(_operations);

  NewposQPrintJob init() => _add(<String, Object?>{'type': 'init'});

  NewposQPrintJob setDepth(int depth) =>
      _add(<String, Object?>{'type': 'setDepth', 'depth': depth});

  NewposQPrintJob setFontSize(int fontSize) =>
      _add(<String, Object?>{'type': 'setFontSize', 'fontSize': fontSize});

  NewposQPrintJob setAlignment(NewposQAlignment alignment) => _add(
    <String, Object?>{'type': 'setAlignment', 'alignment': alignment.value},
  );

  NewposQPrintJob feedLines(int lines) =>
      _add(<String, Object?>{'type': 'feedLines', 'lines': lines});

  NewposQPrintJob blankLines({int lines = 1, int height = 24}) => _add(
    <String, Object?>{'type': 'blankLines', 'lines': lines, 'height': height},
  );

  NewposQPrintJob text(String text) =>
      _add(<String, Object?>{'type': 'text', 'text': text});

  NewposQPrintJob formattedText(
    String text, {
    String typeface = 'ST',
    int fontSize = 24,
    NewposQAlignment alignment = NewposQAlignment.left,
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
    int size = 10,
  }) => _add(<String, Object?>{
    'type': 'bitmap',
    'bytes': bytes,
    'alignment': alignment.value,
    'size': size,
  });

  NewposQPrintJob barcode(
    String data, {
    NewposQBarcodeSymbology symbology = NewposQBarcodeSymbology.code128,
    int height = 6,
    int width = 12,
    NewposQBarcodeTextPosition textPosition = NewposQBarcodeTextPosition.below,
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
    int moduleSize = 10,
    NewposQErrorCorrectionLevel errorCorrectionLevel =
        NewposQErrorCorrectionLevel.medium,
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

  NewposQPrintJob performPrint({int feedLines = 160}) =>
      _add(<String, Object?>{'type': 'performPrint', 'feedLines': feedLines});

  NewposQPrintJob _add(Map<String, Object?> operation) {
    _operations.add(operation);
    return this;
  }
}

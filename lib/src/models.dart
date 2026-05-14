/// Printer status codes returned by the Newpos/IPOS service.
enum NewposQPrinterStatus {
  /// Printer is ready.
  normal(0),

  /// Printer has no paper.
  paperless(1),

  /// Thermal head temperature is too high.
  thermalHeadHighTemperature(2),

  /// Motor temperature is too high.
  motorHighTemperature(3),

  /// Printer is currently busy.
  busy(4),

  /// Unknown or unmapped printer error.
  unknownError(5);

  const NewposQPrinterStatus(this.code);

  /// Numeric status code used by the native service.
  final int code;

  /// Converts a native status [code] into a Dart enum value.
  static NewposQPrinterStatus fromCode(int code) {
    return NewposQPrinterStatus.values.firstWhere(
      (status) => status.code == code,
      orElse: () => NewposQPrinterStatus.unknownError,
    );
  }
}

/// Default values used by high-level print helpers.
class NewposQPrinterDefaults {
  const NewposQPrinterDefaults._();

  /// Default print depth.
  static const int depth = 6;

  /// Default text font size.
  static const int fontSize = 24;

  /// Default amount of paper feed after printing.
  static const int feedLines = 160;

  /// Default height used by [NewposQPrintJob.blankLines].
  static const int blankLineHeight = 24;

  /// Default image size parameter used by the vendor service.
  static const int bitmapSize = 10;

  /// Default barcode height.
  static const int barcodeHeight = 6;

  /// Default barcode width.
  static const int barcodeWidth = 12;

  /// Default QR code module size.
  static const int qrModuleSize = 10;

  /// Default text alignment.
  static const NewposQAlignment alignment = NewposQAlignment.left;

  /// Default barcode symbology.
  static const NewposQBarcodeSymbology barcodeSymbology =
      NewposQBarcodeSymbology.code128;

  /// Default barcode text position.
  static const NewposQBarcodeTextPosition barcodeTextPosition =
      NewposQBarcodeTextPosition.below;

  /// Default QR code error correction level.
  static const NewposQErrorCorrectionLevel qrErrorCorrectionLevel =
      NewposQErrorCorrectionLevel.medium;
}

/// Limits accepted by the Newpos printer API.
class NewposQPrinterLimits {
  const NewposQPrinterLimits._();

  /// Minimum print depth.
  static const int minDepth = 1;

  /// Maximum print depth.
  static const int maxDepth = 10;

  /// Minimum paper feed value.
  static const int minFeedLines = 0;

  /// Maximum paper feed value.
  static const int maxFeedLines = 300;

  /// Minimum blank line height.
  static const int minBlankLineHeight = 8;

  /// Maximum blank line height.
  static const int maxBlankLineHeight = 100;

  /// Supported text font sizes.
  static const List<int> fontSizes = <int>[16, 24, 32, 48];

  /// Minimum bitmap size parameter.
  static const int minBitmapSize = 1;

  /// Maximum bitmap size parameter.
  static const int maxBitmapSize = 16;

  /// Maximum bitmap width supported by the printer.
  static const int maxBitmapWidth = 384;

  /// Minimum barcode height.
  static const int minBarcodeHeight = 1;

  /// Maximum barcode height.
  static const int maxBarcodeHeight = 16;

  /// Minimum barcode width.
  static const int minBarcodeWidth = 1;

  /// Maximum barcode width.
  static const int maxBarcodeWidth = 16;

  /// Minimum QR code module size.
  static const int minQrModuleSize = 1;

  /// Maximum QR code module size.
  static const int maxQrModuleSize = 16;
}

/// Horizontal alignment used by text and image operations.
enum NewposQAlignment {
  /// Align content to the left.
  left(0),

  /// Center content.
  center(1),

  /// Align content to the right.
  right(2);

  const NewposQAlignment(this.value);

  /// Numeric value expected by the native printer service.
  final int value;
}

/// Barcode symbologies supported by the vendor service.
enum NewposQBarcodeSymbology {
  /// UPC-A barcode.
  upcA(0),

  /// UPC-E barcode.
  upcE(1),

  /// EAN-13 barcode.
  ean13(2),

  /// EAN-8 barcode.
  ean8(3),

  /// Code 39 barcode.
  code39(4),

  /// Interleaved 2 of 5 barcode.
  itf(5),

  /// Codabar barcode.
  codabar(6),

  /// Code 93 barcode.
  code93(7),

  /// Code 128 barcode.
  code128(8);

  const NewposQBarcodeSymbology(this.value);

  /// Numeric value expected by the native printer service.
  final int value;
}

/// Position of human-readable text printed with a barcode.
enum NewposQBarcodeTextPosition {
  /// Do not print human-readable barcode text.
  none(0),

  /// Print text above the barcode.
  above(1),

  /// Print text below the barcode.
  below(2),

  /// Print text both above and below the barcode.
  both(3);

  const NewposQBarcodeTextPosition(this.value);

  /// Numeric value expected by the native printer service.
  final int value;
}

/// QR code error correction levels supported by the vendor service.
enum NewposQErrorCorrectionLevel {
  /// Low error correction.
  low(0),

  /// Medium error correction.
  medium(1),

  /// Quartile error correction.
  quartile(2),

  /// High error correction.
  high(3);

  const NewposQErrorCorrectionLevel(this.value);

  /// Numeric value expected by the native printer service.
  final int value;
}

/// Column definition used by [NewposQPrintJob.columns].
class NewposQColumn {
  /// Creates a printable column with [text], character [width], and alignment.
  const NewposQColumn({
    required this.text,
    required this.width,
    this.alignment = NewposQAlignment.left,
  });

  /// Text printed in this column.
  final String text;

  /// Column width passed to the vendor service.
  final int width;

  /// Horizontal alignment for this column.
  final NewposQAlignment alignment;
}

/// Status event emitted by the Android printer service broadcast receiver.
class NewposQStatusEvent {
  /// Creates a status event with the Android broadcast [action] and [status].
  const NewposQStatusEvent({required this.action, this.status});

  /// Android broadcast action that produced this event.
  final String action;

  /// Parsed printer status, when the event includes one.
  final NewposQPrinterStatus? status;

  /// Whether this event reports a paper-out state.
  bool get isPaperless => status == NewposQPrinterStatus.paperless;

  /// Creates a status event from a platform channel map.
  static NewposQStatusEvent fromMap(Map<dynamic, dynamic> map) {
    final statusCode = map['status'];
    return NewposQStatusEvent(
      action: map['action'] as String? ?? '',
      status: statusCode is int
          ? NewposQPrinterStatus.fromCode(statusCode)
          : null,
    );
  }
}

enum NewposQPrinterStatus {
  normal(0),
  paperless(1),
  thermalHeadHighTemperature(2),
  motorHighTemperature(3),
  busy(4),
  unknownError(5);

  const NewposQPrinterStatus(this.code);

  final int code;

  static NewposQPrinterStatus fromCode(int code) {
    return NewposQPrinterStatus.values.firstWhere(
      (status) => status.code == code,
      orElse: () => NewposQPrinterStatus.unknownError,
    );
  }
}

enum NewposQAlignment {
  left(0),
  center(1),
  right(2);

  const NewposQAlignment(this.value);

  final int value;
}

enum NewposQBarcodeSymbology {
  upcA(0),
  upcE(1),
  ean13(2),
  ean8(3),
  code39(4),
  itf(5),
  codabar(6),
  code93(7),
  code128(8);

  const NewposQBarcodeSymbology(this.value);

  final int value;
}

enum NewposQBarcodeTextPosition {
  none(0),
  above(1),
  below(2),
  both(3);

  const NewposQBarcodeTextPosition(this.value);

  final int value;
}

enum NewposQErrorCorrectionLevel {
  low(0),
  medium(1),
  quartile(2),
  high(3);

  const NewposQErrorCorrectionLevel(this.value);

  final int value;
}

class NewposQColumn {
  const NewposQColumn({
    required this.text,
    required this.width,
    this.alignment = NewposQAlignment.left,
  });

  final String text;
  final int width;
  final NewposQAlignment alignment;
}

class NewposQStatusEvent {
  const NewposQStatusEvent({required this.action, this.status});

  final String action;
  final NewposQPrinterStatus? status;

  bool get isPaperless => status == NewposQPrinterStatus.paperless;

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

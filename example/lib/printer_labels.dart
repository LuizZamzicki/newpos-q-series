import 'package:newpos_q_series/newpos_q_series.dart';

extension NewposQPrinterStatusLabel on NewposQPrinterStatus {
  String get label {
    switch (this) {
      case NewposQPrinterStatus.normal:
        return 'normal';
      case NewposQPrinterStatus.paperless:
        return 'paperless';
      case NewposQPrinterStatus.thermalHeadHighTemperature:
        return 'thermal head hot';
      case NewposQPrinterStatus.motorHighTemperature:
        return 'motor hot';
      case NewposQPrinterStatus.busy:
        return 'busy';
      case NewposQPrinterStatus.unknownError:
        return 'unknown error';
    }
  }
}

extension NewposQAlignmentLabel on NewposQAlignment {
  String get label {
    switch (this) {
      case NewposQAlignment.left:
        return 'left';
      case NewposQAlignment.center:
        return 'center';
      case NewposQAlignment.right:
        return 'right';
    }
  }
}

extension NewposQBarcodeSymbologyLabel on NewposQBarcodeSymbology {
  String get label {
    switch (this) {
      case NewposQBarcodeSymbology.upcA:
        return 'UPC-A';
      case NewposQBarcodeSymbology.upcE:
        return 'UPC-E';
      case NewposQBarcodeSymbology.ean13:
        return 'EAN13';
      case NewposQBarcodeSymbology.ean8:
        return 'EAN8';
      case NewposQBarcodeSymbology.code39:
        return 'CODE39';
      case NewposQBarcodeSymbology.itf:
        return 'ITF';
      case NewposQBarcodeSymbology.codabar:
        return 'CODABAR';
      case NewposQBarcodeSymbology.code93:
        return 'CODE93';
      case NewposQBarcodeSymbology.code128:
        return 'CODE128';
    }
  }
}

extension NewposQBarcodeTextPositionLabel on NewposQBarcodeTextPosition {
  String get label {
    switch (this) {
      case NewposQBarcodeTextPosition.none:
        return 'none';
      case NewposQBarcodeTextPosition.above:
        return 'above';
      case NewposQBarcodeTextPosition.below:
        return 'below';
      case NewposQBarcodeTextPosition.both:
        return 'both';
    }
  }
}

extension NewposQErrorCorrectionLevelLabel on NewposQErrorCorrectionLevel {
  String get label {
    switch (this) {
      case NewposQErrorCorrectionLevel.low:
        return 'L';
      case NewposQErrorCorrectionLevel.medium:
        return 'M';
      case NewposQErrorCorrectionLevel.quartile:
        return 'Q';
      case NewposQErrorCorrectionLevel.high:
        return 'H';
    }
  }
}

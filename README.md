# newpos_q_series

[![pub.dev](https://img.shields.io/pub/v/newpos_q_series.svg)](https://pub.dev/packages/newpos_q_series)

Flutter plugin for the internal thermal printer available on supported Newpos
Q-series Android devices.

The plugin talks to the vendor IPOS printer service through Android AIDL and
provides a Dart API for receipts, images, barcodes, QR codes, raw bytes,
ESC/POS commands, and printer status events such as paper-out detection.

## Features

- Bind to the Newpos/IPOS internal printer service.
- Print plain and formatted text.
- Print table-like column rows.
- Print bitmap images, including black-and-white artwork.
- Print QR codes and one-dimensional barcodes.
- Send raw bytes and ESC/POS commands.
- Feed paper and print blank lines.
- Listen for printer status events, including paperless alerts.

## Platform Support

| Platform | Status |
| --- | --- |
| Android | Supported |
| iOS | Not supported |
| Web/Desktop | Not supported |

This package requires a Newpos firmware that includes the vendor service:

- Package: `com.iposprinter.iposprinterservice`
- Action: `com.iposprinter.iposprinterservice.IPosPrintService`

On regular Android devices or unsupported firmware, `bind()` returns `false` or
print calls fail because the vendor printer service is not available.

## Installation

Install the package from pub.dev:

```bash
flutter pub add newpos_q_series
```

Or add it manually to your `pubspec.yaml`:

```yaml
dependencies:
  newpos_q_series: ^0.0.1
```

Then run:

```bash
flutter pub get
```

## Basic Usage

```dart
import 'package:newpos_q_series/newpos_q_series.dart';

final printer = PrinterNewposQ();

final connected = await printer.bind();
if (!connected) {
  throw Exception('Newpos printer service not found');
}

await printer.printText(
  'Hello Newpos Q\n\n',
  fontSize: 24,
  alignment: NewposQAlignment.center,
);
```

## Receipts

Use `NewposQPrintJob` for multi-step receipts.

```dart
final job = NewposQPrintJob()
  ..init()
  ..setDepth(6)
  ..formattedText(
    'MY STORE\n',
    fontSize: 32,
    alignment: NewposQAlignment.center,
  )
  ..formattedText('Order #123\n', fontSize: 24)
  ..columns(
    const [
      NewposQColumn(text: 'Item', width: 12),
      NewposQColumn(
        text: 'Qty',
        width: 6,
        alignment: NewposQAlignment.right,
      ),
      NewposQColumn(
        text: 'Total',
        width: 8,
        alignment: NewposQAlignment.right,
      ),
    ],
    continuous: true,
  )
  ..columns(
    const [
      NewposQColumn(text: 'Coffee', width: 12),
      NewposQColumn(
        text: '1',
        width: 6,
        alignment: NewposQAlignment.right,
      ),
      NewposQColumn(
        text: '5.00',
        width: 8,
        alignment: NewposQAlignment.right,
      ),
    ],
  )
  ..qrCode('https://www.setsistema.com.br/')
  ..performPrint(feedLines: 160);

await printer.execute(job);
```

## Images

The printer is thermal, so output is monochrome. PNG/JPEG bytes can be sent to
the plugin and are decoded as Android `Bitmap`s before being passed to the
vendor service.

```dart
final data = await rootBundle.load('assets/logo.png');

final job = NewposQPrintJob()
  ..init()
  ..bitmap(
    data.buffer.asUint8List(),
    alignment: NewposQAlignment.center,
    size: 10,
  )
  ..performPrint(feedLines: 160);

await printer.execute(job);
```

Vendor SDK notes indicate a maximum image width of 384 px. For best results,
prepare images at 384 px wide or less and use high-contrast black-and-white
artwork.

## Barcodes and QR Codes

```dart
final job = NewposQPrintJob()
  ..init()
  ..barcode(
    '7891234567895',
    symbology: NewposQBarcodeSymbology.ean13,
    height: 6,
    width: 12,
    textPosition: NewposQBarcodeTextPosition.below,
  )
  ..qrCode(
    'https://www.setsistema.com.br/',
    moduleSize: 8,
    errorCorrectionLevel: NewposQErrorCorrectionLevel.medium,
  )
  ..performPrint(feedLines: 160);

await printer.execute(job);
```

## Printer Status Events

The plugin exposes printer status broadcasts as a Dart stream.

```dart
final subscription = printer.statusEvents.listen((event) {
  if (event.isPaperless) {
    // Show a dialog, banner, or retry prompt in your app.
  }
});

// Later:
await subscription.cancel();
```

Mapped statuses include:

- `NewposQPrinterStatus.normal`
- `NewposQPrinterStatus.paperless`
- `NewposQPrinterStatus.thermalHeadHighTemperature`
- `NewposQPrinterStatus.motorHighTemperature`
- `NewposQPrinterStatus.busy`
- `NewposQPrinterStatus.unknownError`

## Example App

The `example/` app includes a test panel for:

- connecting to the printer service;
- printing text, columns, images, QR codes, barcodes, raw data, and ESC/POS;
- changing density, font size, alignment, and feed lines;
- displaying paper-out events as an on-screen popup.

Run it on a supported Newpos Q device:

```bash
cd example
flutter pub get
flutter run
```

## Troubleshooting

### `bind()` returns `false`

The vendor printer service was not found. Confirm it exists on the device:

```bash
adb shell pm list packages | grep -i ipos
adb shell dumpsys package com.iposprinter.iposprinterservice
```

### Print command succeeds but nothing prints

Check paper, printer temperature, and whether the device firmware is using the
same IPOS service API. Use the example app's diagnostics and paper-out popup to
confirm status broadcasts.

### `getPrinterStatus()` is slow or unreliable

Some firmware versions may not respond consistently to synchronous status
queries. Prefer `statusEvents` for real-time UI updates.

## Notes

Only the AIDL interfaces required to compile the plugin are included in this
repository. The original vendor SDK package and demo files are intentionally not
included.

## License

MIT License. See [LICENSE](LICENSE).

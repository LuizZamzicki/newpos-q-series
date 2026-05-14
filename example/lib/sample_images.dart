import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

Future<Uint8List> samplePngBytes() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const size = Size(320, 120);
  final background = Paint()..color = Colors.white;
  canvas.drawRect(Offset.zero & size, background);

  final border = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4;
  canvas.drawRect(const Rect.fromLTWH(2, 2, 316, 116), border);

  final title = TextPainter(
    text: const TextSpan(
      text: 'NEWPOS Q',
      style: TextStyle(
        color: Colors.black,
        fontSize: 34,
        fontWeight: FontWeight.w700,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: size.width);
  title.paint(canvas, const Offset(70, 24));

  final subtitle = TextPainter(
    text: const TextSpan(
      text: 'Bitmap test',
      style: TextStyle(color: Colors.black, fontSize: 22),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: size.width);
  subtitle.paint(canvas, const Offset(102, 70));

  return _recordedPngBytes(recorder, size);
}

Future<Uint8List> logoPngBytes() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const size = Size(384, 180);
  canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);

  final black = Paint()..color = Colors.black;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(24, 18, 96, 96),
      const Radius.circular(10),
    ),
    black,
  );
  canvas.drawRect(
    const Rect.fromLTWH(44, 38, 56, 12),
    Paint()..color = Colors.white,
  );
  canvas.drawRect(
    const Rect.fromLTWH(44, 62, 56, 12),
    Paint()..color = Colors.white,
  );
  canvas.drawRect(
    const Rect.fromLTWH(44, 86, 56, 12),
    Paint()..color = Colors.white,
  );

  final title = TextPainter(
    text: const TextSpan(
      text: 'SET SISTEMAS',
      style: TextStyle(
        color: Colors.black,
        fontSize: 30,
        fontWeight: FontWeight.w800,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: 230);
  title.paint(canvas, const Offset(138, 28));

  final subtitle = TextPainter(
    text: const TextSpan(
      text: 'B/W image 384px',
      style: TextStyle(color: Colors.black, fontSize: 22),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: 230);
  subtitle.paint(canvas, const Offset(138, 70));

  canvas.drawRect(const Rect.fromLTWH(24, 136, 336, 4), black);

  final footer = TextPainter(
    text: const TextSpan(
      text: 'Bitmap print test',
      style: TextStyle(color: Colors.black, fontSize: 20),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: size.width);
  footer.paint(canvas, const Offset(66, 148));

  return _recordedPngBytes(recorder, size);
}

Future<Uint8List> patternPngBytes() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const size = Size(384, 160);
  canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);

  final black = Paint()..color = Colors.black;
  for (var row = 0; row < 8; row++) {
    for (var col = 0; col < 16; col++) {
      if ((row + col).isEven) {
        canvas.drawRect(Rect.fromLTWH(col * 24, row * 16, 24, 16), black);
      }
    }
  }

  final labelBackground = Paint()..color = Colors.white;
  canvas.drawRect(const Rect.fromLTWH(42, 48, 300, 64), labelBackground);
  canvas.drawRect(
    const Rect.fromLTWH(42, 48, 300, 64),
    Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3,
  );

  final label = TextPainter(
    text: const TextSpan(
      text: 'B/W PATTERN',
      style: TextStyle(
        color: Colors.black,
        fontSize: 30,
        fontWeight: FontWeight.w800,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: size.width);
  label.paint(canvas, const Offset(92, 64));

  return _recordedPngBytes(recorder, size);
}

Uint8List blackRasterBlock({required int height}) {
  const rowBytes = 48; // 384 printer dots / 8 bits.
  return Uint8List.fromList(
    List<int>.generate(rowBytes * height, (index) {
      final row = index ~/ rowBytes;
      return row.isEven ? 0xFF : 0x00;
    }),
  );
}

Future<Uint8List> _recordedPngBytes(
  ui.PictureRecorder recorder,
  Size size,
) async {
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.toInt(), size.height.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

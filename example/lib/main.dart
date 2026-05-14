import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:newpos_q_series/newpos_q_series.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Newpos Q Printer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF176B5D)),
        useMaterial3: true,
      ),
      home: const PrinterTestPage(),
    );
  }
}

class PrinterTestPage extends StatefulWidget {
  const PrinterTestPage({super.key});

  @override
  State<PrinterTestPage> createState() => _PrinterTestPageState();
}

class _PrinterTestPageState extends State<PrinterTestPage> {
  final PrinterNewposQ _printer = PrinterNewposQ();
  StreamSubscription<NewposQStatusEvent>? _statusSubscription;

  String _platformVersion = 'Unknown';
  String _message = 'Ready';
  String _diagnostics = 'Not checked';
  bool _busy = false;
  bool _bound = false;
  bool _paperlessDialogVisible = false;
  NewposQPrinterStatus? _status;

  int _depth = 6;
  int _fontSize = 24;
  int _feedLines = 160;
  int _blankLineHeight = 24;
  int _bitmapSize = 10;
  int _barcodeHeight = 6;
  int _barcodeWidth = 12;
  int _qrModuleSize = 8;
  NewposQAlignment _alignment = NewposQAlignment.left;
  NewposQBarcodeSymbology _barcodeSymbology = NewposQBarcodeSymbology.code128;
  NewposQBarcodeTextPosition _barcodeTextPosition =
      NewposQBarcodeTextPosition.below;
  NewposQErrorCorrectionLevel _qrCorrection =
      NewposQErrorCorrectionLevel.medium;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPlatformVersion());
    _statusSubscription = _printer.statusEvents.listen(_handleStatusEvent);
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }

  void _handleStatusEvent(NewposQStatusEvent event) {
    if (!mounted) return;
    final status = event.status;
    setState(() {
      if (status != null) {
        _status = status;
      }
      if (event.isPaperless) {
        _message = 'Sem papel';
        _showPaperlessDialog();
      } else if (status == NewposQPrinterStatus.normal) {
        _message = 'Impressora pronta';
        _paperlessDialogVisible = false;
      } else if (status == NewposQPrinterStatus.busy) {
        _message = 'Impressora ocupada';
      } else if (status == NewposQPrinterStatus.thermalHeadHighTemperature) {
        _message = 'Cabeca termica aquecida';
      } else if (status == NewposQPrinterStatus.motorHighTemperature) {
        _message = 'Motor aquecido';
      }
    });
  }

  void _showPaperlessDialog() {
    if (_paperlessDialogVisible) return;
    _paperlessDialogVisible = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Sem papel'),
            content: const Text('Coloque papel na impressora para continuar.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      _paperlessDialogVisible = false;
    });
  }

  Future<void> _loadPlatformVersion() async {
    try {
      final version = await _printer.getPlatformVersion();
      if (!mounted) return;
      setState(() => _platformVersion = version ?? 'Unknown');
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() => _platformVersion = error.message ?? 'Platform error');
    }
  }

  Future<void> _run(String label, Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = '$label...';
    });

    try {
      await action();
      if (!mounted) return;
      setState(() => _message = '$label OK');
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() => _message = error.message ?? '$label failed');
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _connect() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = 'Connecting...';
    });

    try {
      final bound = await _printer.bind();
      final diagnostics = await _printer.diagnostics();
      setState(() {
        _bound = bound;
        _status = null;
        _diagnostics = _formatDiagnostics(diagnostics);
      });
      if (!bound) {
        throw StateError('Printer service not found. Check diagnostics.');
      }
      setState(() {
        _message = 'Connected';
      });
    } on PlatformException catch (error) {
      setState(() => _message = error.message ?? 'Connect failed');
    } catch (error) {
      setState(() => _message = error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _loadDiagnostics() async {
    await _run('Diagnostics', () async {
      final diagnostics = await _printer.diagnostics();
      setState(() => _diagnostics = _formatDiagnostics(diagnostics));
    });
  }

  Future<void> _disconnect() async {
    await _run('Disconnect', () async {
      await _printer.unbind();
      setState(() {
        _bound = false;
        _status = null;
      });
    });
  }

  String _formatDiagnostics(Map<String, Object?> diagnostics) {
    final packageInstalled = diagnostics['packageInstalled'];
    final actionServices = diagnostics['actionServices'];
    final componentServices = diagnostics['componentServices'];
    final bindAttempts = diagnostics['bindAttempts'];
    final serviceClass = diagnostics['serviceClass'];
    final servicePackage = diagnostics['servicePackage'];
    final serviceAction = diagnostics['serviceAction'];
    return 'package=$servicePackage installed=$packageInstalled\n'
        'class=$serviceClass\n'
        'action=$serviceAction\n'
        'actionServices=$actionServices\n'
        'componentServices=$componentServices\n'
        'bindAttempts=$bindAttempts';
  }

  Future<void> _refreshStatus() async {
    await _run('Status', () async {
      final bound = await _printer.isBound();
      final status = bound
          ? await _printer.getPrinterStatus().timeout(
              const Duration(seconds: 3),
              onTimeout: () => NewposQPrinterStatus.unknownError,
            )
          : null;
      setState(() {
        _bound = bound;
        _status = status;
      });
    });
  }

  Future<void> _execute(String label, NewposQPrintJob job) {
    return _run(label, () async {
      await _printer.execute(job, timeout: const Duration(seconds: 15));
      final bound = await _printer.isBound();
      setState(() {
        _bound = bound;
      });
    });
  }

  NewposQPrintJob _baseJob() {
    return NewposQPrintJob()
      ..init()
      ..setDepth(_depth)
      ..setAlignment(_alignment)
      ..setFontSize(_fontSize);
  }

  Future<void> _printPlainText() {
    final job = _baseJob()
      ..text('Plain text print\nNewpos Q-series\n')
      ..performPrint(feedLines: _feedLines);
    return _execute('Plain text', job);
  }

  Future<void> _printFormattedText() {
    final job = _baseJob()
      ..formattedText(
        'Formatted text\nFont $_fontSize - ${_alignment.label}\n',
        fontSize: _fontSize,
        alignment: _alignment,
      )
      ..blankLines(lines: 1, height: 12)
      ..formattedText(
        'Depth $_depth\n',
        fontSize: 24,
        alignment: NewposQAlignment.center,
      )
      ..performPrint(feedLines: _feedLines);
    return _execute('Formatted text', job);
  }

  Future<void> _printColumns() {
    final job = _baseJob()
      ..formattedText(
        'Columns\n',
        fontSize: 32,
        alignment: NewposQAlignment.center,
      )
      ..columns(const <NewposQColumn>[
        NewposQColumn(text: 'Item', width: 12),
        NewposQColumn(text: 'Qty', width: 6, alignment: NewposQAlignment.right),
        NewposQColumn(
          text: 'Total',
          width: 8,
          alignment: NewposQAlignment.right,
        ),
      ], continuous: true)
      ..columns(const <NewposQColumn>[
        NewposQColumn(text: 'Coffee', width: 12),
        NewposQColumn(text: '2', width: 6, alignment: NewposQAlignment.right),
        NewposQColumn(
          text: '10.00',
          width: 8,
          alignment: NewposQAlignment.right,
        ),
      ], continuous: true)
      ..columns(const <NewposQColumn>[
        NewposQColumn(text: 'Snack', width: 12),
        NewposQColumn(text: '1', width: 6, alignment: NewposQAlignment.right),
        NewposQColumn(
          text: '7.50',
          width: 8,
          alignment: NewposQAlignment.right,
        ),
      ])
      ..performPrint(feedLines: _feedLines);
    return _execute('Columns', job);
  }

  Future<void> _printBitmap() async {
    final bytes = await _samplePngBytes();
    final job = _baseJob()
      ..bitmap(bytes, alignment: _alignment, size: _bitmapSize)
      ..performPrint(feedLines: _feedLines);
    return _execute('Image text', job);
  }

  Future<void> _printImageLogo() async {
    final bytes = await _logoPngBytes();
    final job = _baseJob()
      ..bitmap(bytes, alignment: _alignment, size: _bitmapSize)
      ..performPrint(feedLines: _feedLines);
    return _execute('Image logo', job);
  }

  Future<void> _printImagePattern() async {
    final bytes = await _patternPngBytes();
    final job = _baseJob()
      ..bitmap(bytes, alignment: _alignment, size: _bitmapSize)
      ..performPrint(feedLines: _feedLines);
    return _execute('Image pattern', job);
  }

  Future<void> _printBarcode() {
    final job = _baseJob()
      ..barcode(
        '7891234567895',
        symbology: _barcodeSymbology,
        height: _barcodeHeight,
        width: _barcodeWidth,
        textPosition: _barcodeTextPosition,
      )
      ..performPrint(feedLines: _feedLines);
    return _execute('Barcode', job);
  }

  Future<void> _printQrCode() {
    final job = _baseJob()
      ..qrCode(
        'https://example.com/newpos-q',
        moduleSize: _qrModuleSize,
        errorCorrectionLevel: _qrCorrection,
      )
      ..performPrint(feedLines: _feedLines);
    return _execute('QR Code', job);
  }

  Future<void> _printRawData() {
    final job = _baseJob()
      ..rawData(_blackRasterBlock(height: 48))
      ..blankLines(lines: 1, height: 16)
      ..performPrint(feedLines: _feedLines);
    return _execute('Raw data', job);
  }

  Future<void> _printEscPos() {
    final bytes = Uint8List.fromList(<int>[
      0x1B,
      0x40,
      0x1B,
      0x61,
      0x01,
      ...'ESC/POS command\n'.codeUnits,
      0x1B,
      0x61,
      0x00,
      ...'Left aligned line\n\n'.codeUnits,
    ]);
    final job = NewposQPrintJob()
      ..escPos(bytes)
      ..performPrint(feedLines: _feedLines);
    return _execute('ESC/POS', job);
  }

  Future<void> _runFullDemo() async {
    final bitmapBytes = await _samplePngBytes();
    final job = _baseJob()
      ..formattedText(
        'Newpos Q Test\n',
        fontSize: 32,
        alignment: NewposQAlignment.center,
      )
      ..formattedText('Text, table, image, barcode, QR\n', fontSize: 24)
      ..blankLines(lines: 1, height: 12)
      ..columns(const <NewposQColumn>[
        NewposQColumn(text: 'Product', width: 12),
        NewposQColumn(text: 'Qty', width: 6, alignment: NewposQAlignment.right),
        NewposQColumn(
          text: 'Value',
          width: 8,
          alignment: NewposQAlignment.right,
        ),
      ], continuous: true)
      ..columns(const <NewposQColumn>[
        NewposQColumn(text: 'Demo', width: 12),
        NewposQColumn(text: '1', width: 6, alignment: NewposQAlignment.right),
        NewposQColumn(
          text: '0.00',
          width: 8,
          alignment: NewposQAlignment.right,
        ),
      ])
      ..blankLines(lines: 1, height: 12)
      ..bitmap(bitmapBytes, alignment: NewposQAlignment.center, size: 8)
      ..blankLines(lines: 1, height: 12)
      ..barcode('7891234567895')
      ..blankLines(lines: 1, height: 12)
      ..qrCode('https://example.com/newpos-q', moduleSize: 8)
      ..performPrint(feedLines: _feedLines);
    return _execute('Full demo', job);
  }

  Future<Uint8List> _samplePngBytes() async {
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

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _logoPngBytes() async {
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
        text: 'Imagem P&B 384px',
        style: TextStyle(color: Colors.black, fontSize: 22),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 230);
    subtitle.paint(canvas, const Offset(138, 70));

    canvas.drawRect(const Rect.fromLTWH(24, 136, 336, 4), black);

    final footer = TextPainter(
      text: const TextSpan(
        text: 'Teste de impressao bitmap',
        style: TextStyle(color: Colors.black, fontSize: 20),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    footer.paint(canvas, const Offset(66, 148));

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _patternPngBytes() async {
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

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Uint8List _blackRasterBlock({required int height}) {
    const rowBytes = 48; // 384 printer dots / 8 bits.
    return Uint8List.fromList(
      List<int>.generate(rowBytes * height, (index) {
        final row = index ~/ rowBytes;
        return row.isEven ? 0xFF : 0x00;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Newpos Q Printer Test')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _StatusPanel(
              platformVersion: _platformVersion,
              bound: _bound,
              status: _status,
              message: _message,
              diagnostics: _diagnostics,
              busy: _busy,
              onConnect: _connect,
              onDisconnect: _disconnect,
              onRefresh: _refreshStatus,
              onDiagnostics: _loadDiagnostics,
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'Settings',
              children: <Widget>[
                _LabeledSlider(
                  label: 'Depth',
                  value: _depth.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  displayValue: '$_depth',
                  onChanged: (value) => setState(() => _depth = value.round()),
                ),
                _LabeledSlider(
                  label: 'Feed lines',
                  value: _feedLines.toDouble(),
                  min: 0,
                  max: 300,
                  divisions: 30,
                  displayValue: '$_feedLines',
                  onChanged: (value) =>
                      setState(() => _feedLines = value.round()),
                ),
                _LabeledSlider(
                  label: 'Blank height',
                  value: _blankLineHeight.toDouble(),
                  min: 8,
                  max: 100,
                  divisions: 23,
                  displayValue: '$_blankLineHeight',
                  onChanged: (value) =>
                      setState(() => _blankLineHeight = value.round()),
                ),
                const SizedBox(height: 8),
                _ChoiceRow<int>(
                  label: 'Font size',
                  value: _fontSize,
                  values: const <int>[16, 24, 32, 48],
                  labelBuilder: (value) => '$value',
                  onChanged: (value) => setState(() => _fontSize = value),
                ),
                const SizedBox(height: 8),
                _ChoiceRow<NewposQAlignment>(
                  label: 'Alignment',
                  value: _alignment,
                  values: NewposQAlignment.values,
                  labelBuilder: (value) => value.label,
                  onChanged: (value) => setState(() => _alignment = value),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'Printer Commands',
              children: <Widget>[
                _ButtonGrid(
                  buttons: <_ActionButton>[
                    _ActionButton('Init', () {
                      return _execute('Init', NewposQPrintJob()..init());
                    }),
                    _ActionButton('Apply depth', () {
                      return _execute(
                        'Apply depth',
                        NewposQPrintJob()..setDepth(_depth),
                      );
                    }),
                    _ActionButton('Apply font', () {
                      return _execute(
                        'Apply font',
                        NewposQPrintJob()..setFontSize(_fontSize),
                      );
                    }),
                    _ActionButton('Apply align', () {
                      return _execute(
                        'Apply align',
                        NewposQPrintJob()..setAlignment(_alignment),
                      );
                    }),
                    _ActionButton('Feed paper', () {
                      return _execute(
                        'Feed paper',
                        NewposQPrintJob()..feedLines(_feedLines),
                      );
                    }),
                    _ActionButton('Blank lines', () {
                      return _execute(
                        'Blank lines',
                        NewposQPrintJob()
                          ..blankLines(lines: 3, height: _blankLineHeight)
                          ..performPrint(feedLines: _feedLines),
                      );
                    }),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'Print Content',
              children: <Widget>[
                _ButtonGrid(
                  buttons: <_ActionButton>[
                    _ActionButton('Plain text', _printPlainText),
                    _ActionButton('Formatted text', _printFormattedText),
                    _ActionButton('Columns', _printColumns),
                    _ActionButton('Raw data', _printRawData),
                    _ActionButton('ESC/POS', _printEscPos),
                    _ActionButton('Full demo', _runFullDemo),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'Images',
              children: <Widget>[
                _LabeledSlider(
                  label: 'Image size',
                  value: _bitmapSize.toDouble(),
                  min: 1,
                  max: 16,
                  divisions: 15,
                  displayValue: '$_bitmapSize',
                  onChanged: (value) =>
                      setState(() => _bitmapSize = value.round()),
                ),
                _ChoiceRow<NewposQAlignment>(
                  label: 'Image alignment',
                  value: _alignment,
                  values: NewposQAlignment.values,
                  labelBuilder: (value) => value.label,
                  onChanged: (value) => setState(() => _alignment = value),
                ),
                const SizedBox(height: 12),
                _ButtonGrid(
                  buttons: <_ActionButton>[
                    _ActionButton('Text image', _printBitmap),
                    _ActionButton('Logo image', _printImageLogo),
                    _ActionButton('B/W pattern', _printImagePattern),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'Barcode',
              children: <Widget>[
                _DropdownRow<NewposQBarcodeSymbology>(
                  label: 'Symbology',
                  value: _barcodeSymbology,
                  values: NewposQBarcodeSymbology.values,
                  labelBuilder: (value) => value.label,
                  onChanged: (value) =>
                      setState(() => _barcodeSymbology = value),
                ),
                _DropdownRow<NewposQBarcodeTextPosition>(
                  label: 'Text',
                  value: _barcodeTextPosition,
                  values: NewposQBarcodeTextPosition.values,
                  labelBuilder: (value) => value.label,
                  onChanged: (value) =>
                      setState(() => _barcodeTextPosition = value),
                ),
                _LabeledSlider(
                  label: 'Height',
                  value: _barcodeHeight.toDouble(),
                  min: 1,
                  max: 16,
                  divisions: 15,
                  displayValue: '$_barcodeHeight',
                  onChanged: (value) =>
                      setState(() => _barcodeHeight = value.round()),
                ),
                _LabeledSlider(
                  label: 'Width',
                  value: _barcodeWidth.toDouble(),
                  min: 1,
                  max: 16,
                  divisions: 15,
                  displayValue: '$_barcodeWidth',
                  onChanged: (value) =>
                      setState(() => _barcodeWidth = value.round()),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton(
                    onPressed: _busy ? null : _printBarcode,
                    child: const Text('Print barcode'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'QR Code',
              children: <Widget>[
                _DropdownRow<NewposQErrorCorrectionLevel>(
                  label: 'Correction',
                  value: _qrCorrection,
                  values: NewposQErrorCorrectionLevel.values,
                  labelBuilder: (value) => value.label,
                  onChanged: (value) => setState(() => _qrCorrection = value),
                ),
                _LabeledSlider(
                  label: 'Module size',
                  value: _qrModuleSize.toDouble(),
                  min: 1,
                  max: 16,
                  divisions: 15,
                  displayValue: '$_qrModuleSize',
                  onChanged: (value) =>
                      setState(() => _qrModuleSize = value.round()),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton(
                    onPressed: _busy ? null : _printQrCode,
                    child: const Text('Print QR code'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.platformVersion,
    required this.bound,
    required this.status,
    required this.message,
    required this.diagnostics,
    required this.busy,
    required this.onConnect,
    required this.onDisconnect,
    required this.onRefresh,
    required this.onDiagnostics,
  });

  final String platformVersion;
  final bool bound;
  final NewposQPrinterStatus? status;
  final String message;
  final String diagnostics;
  final bool busy;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onRefresh;
  final VoidCallback onDiagnostics;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Device', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Android: $platformVersion'),
            Text('Service: ${bound ? 'connected' : 'disconnected'}'),
            Text('Printer: ${status?.label ?? 'unknown'}'),
            if (status == NewposQPrinterStatus.paperless) ...<Widget>[
              const SizedBox(height: 8),
              const _WarningBanner(message: 'Sem papel na impressora'),
            ],
            Text('Last: $message'),
            const SizedBox(height: 8),
            SelectableText(
              diagnostics,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (busy) ...<Widget>[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton(
                  onPressed: busy ? null : onConnect,
                  child: const Text('Connect'),
                ),
                OutlinedButton(
                  onPressed: busy ? null : onRefresh,
                  child: const Text('Refresh'),
                ),
                OutlinedButton(
                  onPressed: busy ? null : onDiagnostics,
                  child: const Text('Diagnostics'),
                ),
                OutlinedButton(
                  onPressed: busy ? null : onDisconnect,
                  child: const Text('Disconnect'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: colors.onErrorContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.displayValue,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String displayValue;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(width: 96, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: displayValue,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(displayValue, textAlign: TextAlign.end),
        ),
      ],
    );
  }
}

class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.value,
    required this.values,
    required this.labelBuilder,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values.map((item) {
            return ChoiceChip(
              label: Text(labelBuilder(item)),
              selected: item == value,
              onSelected: (_) => onChanged(item),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DropdownRow<T> extends StatelessWidget {
  const _DropdownRow({
    required this.label,
    required this.value,
    required this.values,
    required this.labelBuilder,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          SizedBox(width: 96, child: Text(label)),
          Expanded(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              items: values.map((item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(labelBuilder(item)),
                );
              }).toList(),
              onChanged: (item) {
                if (item != null) onChanged(item);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ButtonGrid extends StatelessWidget {
  const _ButtonGrid({required this.buttons});

  final List<_ActionButton> buttons;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520 ? 3 : 2;
        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: columns == 3 ? 3.1 : 2.4,
          children: buttons.map((button) {
            return FilledButton.tonal(
              onPressed: () => unawaited(button.onPressed()),
              child: Text(button.label, textAlign: TextAlign.center),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ActionButton {
  const _ActionButton(this.label, this.onPressed);

  final String label;
  final Future<void> Function() onPressed;
}

extension on NewposQPrinterStatus {
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

extension on NewposQAlignment {
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

extension on NewposQBarcodeSymbology {
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

extension on NewposQBarcodeTextPosition {
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

extension on NewposQErrorCorrectionLevel {
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:newpos_q_series/newpos_q_series.dart';

import 'printer_labels.dart';
import 'sample_images.dart';
import 'widgets.dart';

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

  int _depth = NewposQPrinterDefaults.depth;
  int _fontSize = NewposQPrinterDefaults.fontSize;
  int _feedLines = NewposQPrinterDefaults.feedLines;
  int _blankLineHeight = NewposQPrinterDefaults.blankLineHeight;
  int _bitmapSize = NewposQPrinterDefaults.bitmapSize;
  int _barcodeHeight = NewposQPrinterDefaults.barcodeHeight;
  int _barcodeWidth = NewposQPrinterDefaults.barcodeWidth;
  int _qrModuleSize = 8;
  NewposQAlignment _alignment = NewposQPrinterDefaults.alignment;
  NewposQBarcodeSymbology _barcodeSymbology =
      NewposQPrinterDefaults.barcodeSymbology;
  NewposQBarcodeTextPosition _barcodeTextPosition =
      NewposQPrinterDefaults.barcodeTextPosition;
  NewposQErrorCorrectionLevel _qrCorrection =
      NewposQPrinterDefaults.qrErrorCorrectionLevel;

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
        _message = 'Out of paper';
        _showPaperlessDialog();
      } else if (status == NewposQPrinterStatus.normal) {
        _message = 'Printer ready';
        _paperlessDialogVisible = false;
      } else if (status == NewposQPrinterStatus.busy) {
        _message = 'Printer busy';
      } else if (status == NewposQPrinterStatus.thermalHeadHighTemperature) {
        _message = 'Thermal head hot';
      } else if (status == NewposQPrinterStatus.motorHighTemperature) {
        _message = 'Motor hot';
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
            title: const Text('Out of paper'),
            content: const Text('Please insert a new paper roll to continue.'),
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
    final bytes = await samplePngBytes();
    final job = _baseJob()
      ..bitmap(bytes, alignment: _alignment, size: _bitmapSize)
      ..performPrint(feedLines: _feedLines);
    return _execute('Image text', job);
  }

  Future<void> _printImageLogo() async {
    final bytes = await logoPngBytes();
    final job = _baseJob()
      ..bitmap(bytes, alignment: _alignment, size: _bitmapSize)
      ..performPrint(feedLines: _feedLines);
    return _execute('Image logo', job);
  }

  Future<void> _printImagePattern() async {
    final bytes = await patternPngBytes();
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
      ..rawData(blackRasterBlock(height: 48))
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
    final bitmapBytes = await samplePngBytes();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Newpos Q Printer Test')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            StatusPanel(
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
            Section(
              title: 'Settings',
              children: <Widget>[
                LabeledSlider(
                  label: 'Depth',
                  value: _depth.toDouble(),
                  min: NewposQPrinterLimits.minDepth.toDouble(),
                  max: NewposQPrinterLimits.maxDepth.toDouble(),
                  divisions:
                      NewposQPrinterLimits.maxDepth -
                      NewposQPrinterLimits.minDepth,
                  displayValue: '$_depth',
                  onChanged: (value) => setState(() => _depth = value.round()),
                ),
                LabeledSlider(
                  label: 'Feed lines',
                  value: _feedLines.toDouble(),
                  min: NewposQPrinterLimits.minFeedLines.toDouble(),
                  max: NewposQPrinterLimits.maxFeedLines.toDouble(),
                  divisions: 30,
                  displayValue: '$_feedLines',
                  onChanged: (value) =>
                      setState(() => _feedLines = value.round()),
                ),
                LabeledSlider(
                  label: 'Blank height',
                  value: _blankLineHeight.toDouble(),
                  min: NewposQPrinterLimits.minBlankLineHeight.toDouble(),
                  max: NewposQPrinterLimits.maxBlankLineHeight.toDouble(),
                  divisions: 23,
                  displayValue: '$_blankLineHeight',
                  onChanged: (value) =>
                      setState(() => _blankLineHeight = value.round()),
                ),
                const SizedBox(height: 8),
                ChoiceRow<int>(
                  label: 'Font size',
                  value: _fontSize,
                  values: NewposQPrinterLimits.fontSizes,
                  labelBuilder: (value) => '$value',
                  onChanged: (value) => setState(() => _fontSize = value),
                ),
                const SizedBox(height: 8),
                ChoiceRow<NewposQAlignment>(
                  label: 'Alignment',
                  value: _alignment,
                  values: NewposQAlignment.values,
                  labelBuilder: (value) => value.label,
                  onChanged: (value) => setState(() => _alignment = value),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Section(
              title: 'Printer Commands',
              children: <Widget>[
                ButtonGrid(
                  buttons: <ActionButton>[
                    ActionButton('Init', () {
                      return _execute('Init', NewposQPrintJob()..init());
                    }),
                    ActionButton('Apply depth', () {
                      return _execute(
                        'Apply depth',
                        NewposQPrintJob()..setDepth(_depth),
                      );
                    }),
                    ActionButton('Apply font', () {
                      return _execute(
                        'Apply font',
                        NewposQPrintJob()..setFontSize(_fontSize),
                      );
                    }),
                    ActionButton('Apply align', () {
                      return _execute(
                        'Apply align',
                        NewposQPrintJob()..setAlignment(_alignment),
                      );
                    }),
                    ActionButton('Feed paper', () {
                      return _execute(
                        'Feed paper',
                        NewposQPrintJob()..feedLines(_feedLines),
                      );
                    }),
                    ActionButton('Blank lines', () {
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
            Section(
              title: 'Print Content',
              children: <Widget>[
                ButtonGrid(
                  buttons: <ActionButton>[
                    ActionButton('Plain text', _printPlainText),
                    ActionButton('Formatted text', _printFormattedText),
                    ActionButton('Columns', _printColumns),
                    ActionButton('Raw data', _printRawData),
                    ActionButton('ESC/POS', _printEscPos),
                    ActionButton('Full demo', _runFullDemo),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Section(
              title: 'Images',
              children: <Widget>[
                LabeledSlider(
                  label: 'Image size',
                  value: _bitmapSize.toDouble(),
                  min: NewposQPrinterLimits.minBitmapSize.toDouble(),
                  max: NewposQPrinterLimits.maxBitmapSize.toDouble(),
                  divisions:
                      NewposQPrinterLimits.maxBitmapSize -
                      NewposQPrinterLimits.minBitmapSize,
                  displayValue: '$_bitmapSize',
                  onChanged: (value) =>
                      setState(() => _bitmapSize = value.round()),
                ),
                ChoiceRow<NewposQAlignment>(
                  label: 'Image alignment',
                  value: _alignment,
                  values: NewposQAlignment.values,
                  labelBuilder: (value) => value.label,
                  onChanged: (value) => setState(() => _alignment = value),
                ),
                const SizedBox(height: 12),
                ButtonGrid(
                  buttons: <ActionButton>[
                    ActionButton('Text image', _printBitmap),
                    ActionButton('Logo image', _printImageLogo),
                    ActionButton('B/W pattern', _printImagePattern),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Section(
              title: 'Barcode',
              children: <Widget>[
                DropdownRow<NewposQBarcodeSymbology>(
                  label: 'Symbology',
                  value: _barcodeSymbology,
                  values: NewposQBarcodeSymbology.values,
                  labelBuilder: (value) => value.label,
                  onChanged: (value) =>
                      setState(() => _barcodeSymbology = value),
                ),
                DropdownRow<NewposQBarcodeTextPosition>(
                  label: 'Text',
                  value: _barcodeTextPosition,
                  values: NewposQBarcodeTextPosition.values,
                  labelBuilder: (value) => value.label,
                  onChanged: (value) =>
                      setState(() => _barcodeTextPosition = value),
                ),
                LabeledSlider(
                  label: 'Height',
                  value: _barcodeHeight.toDouble(),
                  min: NewposQPrinterLimits.minBarcodeHeight.toDouble(),
                  max: NewposQPrinterLimits.maxBarcodeHeight.toDouble(),
                  divisions:
                      NewposQPrinterLimits.maxBarcodeHeight -
                      NewposQPrinterLimits.minBarcodeHeight,
                  displayValue: '$_barcodeHeight',
                  onChanged: (value) =>
                      setState(() => _barcodeHeight = value.round()),
                ),
                LabeledSlider(
                  label: 'Width',
                  value: _barcodeWidth.toDouble(),
                  min: NewposQPrinterLimits.minBarcodeWidth.toDouble(),
                  max: NewposQPrinterLimits.maxBarcodeWidth.toDouble(),
                  divisions:
                      NewposQPrinterLimits.maxBarcodeWidth -
                      NewposQPrinterLimits.minBarcodeWidth,
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
            Section(
              title: 'QR Code',
              children: <Widget>[
                DropdownRow<NewposQErrorCorrectionLevel>(
                  label: 'Correction',
                  value: _qrCorrection,
                  values: NewposQErrorCorrectionLevel.values,
                  labelBuilder: (value) => value.label,
                  onChanged: (value) => setState(() => _qrCorrection = value),
                ),
                LabeledSlider(
                  label: 'Module size',
                  value: _qrModuleSize.toDouble(),
                  min: NewposQPrinterLimits.minQrModuleSize.toDouble(),
                  max: NewposQPrinterLimits.maxQrModuleSize.toDouble(),
                  divisions:
                      NewposQPrinterLimits.maxQrModuleSize -
                      NewposQPrinterLimits.minQrModuleSize,
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

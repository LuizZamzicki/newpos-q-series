import 'package:flutter/material.dart';

import 'printer_test_page.dart';

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

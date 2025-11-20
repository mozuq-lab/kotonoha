import 'package:flutter/material.dart';

/// Main application widget
class KotonohaApp extends StatelessWidget {
  const KotonohaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'kotonoha',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('kotonoha - 文字盤コミュニケーション支援アプリ'),
        ),
      ),
    );
  }
}

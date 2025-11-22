import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/utils/hive_init.dart';

/// 【main関数】: アプリのエントリーポイント
/// 【実装内容】: Hive初期化を実行してからFlutterアプリを起動
/// 【テスト対応】: TC-001（Hive初期化成功テスト）の基盤
/// 🔵 信頼性レベル: 青信号 - TASK-0014の実装詳細に基づく
void main() async {
  // 【Flutter初期化】: WidgetsFlutterBindingの初期化
  // 【実装内容】: async main関数でawaitを使用するために必要
  // 🔵 信頼性レベル: 青信号 - Flutter公式ドキュメントに基づく
  WidgetsFlutterBinding.ensureInitialized();

  // 【Hive初期化】: ローカルストレージの初期化
  // 【実装内容】: TypeAdapter登録とボックスオープンを実行
  // 【テスト対応】: TC-001、TC-002、TC-003
  // 🔵 信頼性レベル: 青信号 - REQ-5003（データ永続化）の実現
  await initHive();

  // 【アプリ起動】: Flutterアプリの起動
  // 【実装内容】: MyAppウィジェットをルートとして起動
  // 🔵 信頼性レベル: 青信号 - Flutter標準パターン
  runApp(const MyApp());
}

/// 【MyAppウィジェット】: アプリのルートウィジェット
/// 【実装内容】: MaterialAppを提供する最上位ウィジェット
/// 🔵 信頼性レベル: 青信号 - Flutter標準パターン
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'kotonoha',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'kotonoha - 文字盤コミュニケーション支援'),
    );
  }
}

/// 【MyHomePageウィジェット】: ホーム画面ウィジェット
/// 【実装内容】: 仮のホーム画面（Phase 2以降で実装予定）
/// 🔴 信頼性レベル: 赤信号 - Phase 1では仮実装
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Phase 1: Hiveローカルストレージセットアップ完了'),
            const SizedBox(height: 20),
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

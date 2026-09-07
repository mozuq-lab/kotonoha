/// AI変換ローディングウィジェット
/// 機能概要: AI変換処理中のローディング表示、3秒超過時の追加メッセージ表示
/// 実装方針: StatefulWidgetでタイマーを管理し、3秒後にメッセージを表示
library;

import 'dart:async';
import 'package:flutter/material.dart';

/// ウィジェット定義: AI変換ローディング表示
/// 3秒超過時にローディングメッセージを表示
class AIConversionLoading extends StatefulWidget {
  /// コンストラクタ: AIConversionLoading
  const AIConversionLoading({
    super.key,
    this.showExtendedMessage = false,
    this.extendedMessageDelaySeconds = 3,
  });

  /// プロパティ定義: 外部から拡張メッセージ表示を制御（テスト用）
  final bool showExtendedMessage;

  /// プロパティ定義: 拡張メッセージ表示までの遅延秒数
  final int extendedMessageDelaySeconds;

  @override
  State<AIConversionLoading> createState() => _AIConversionLoadingState();
}

/// State定義: AIConversionLoadingの状態管理
class _AIConversionLoadingState extends State<AIConversionLoading> {
  /// 状態変数: タイマー参照（dispose時にキャンセル用）
  Timer? _timer;

  /// 状態変数: 拡張メッセージを表示するかどうか
  bool _showMessage = false;

  @override
  void initState() {
    super.initState();

    // 初期化処理: 外部指定がない場合、タイマーを開始
    if (!widget.showExtendedMessage) {
      _startTimer();
    } else {
      _showMessage = true;
    }
  }

  /// メソッド定義: 3秒タイマーを開始
  /// 実装内容: 3秒後に拡張メッセージを表示
  void _startTimer() {
    _timer = Timer(
      Duration(seconds: widget.extendedMessageDelaySeconds),
      () {
        // タイマー完了処理: マウント状態を確認してからsetState
        if (mounted) {
          setState(() {
            _showMessage = true;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    // リソース解放: タイマーをキャンセルしてメモリリークを防止
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // UI構築: ローディングインジケーターと拡張メッセージを表示
    // 実装内容: CircularProgressIndicatorと、3秒後に「AI変換中...」を表示
    return Semantics(
      // アクセシビリティ: スクリーンリーダー用ラベル
      label: _showMessage ? 'AI変換処理中。しばらくお待ちください。' : 'AI変換処理中',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ローディングインジケーター: 常に表示
          const CircularProgressIndicator(),

          // 拡張メッセージ: 3秒後に表示
          if (_showMessage) ...[
            const SizedBox(height: 16),
            const Text(
              'AI変換中...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ],
      ),
    );
  }
}

/// AI変換ボタンウィジェット
///
/// TASK-0068: AI変換UIウィジェット実装
///
/// 【機能概要】: AI変換を実行するボタン、ローディング状態管理、入力バリデーション
/// 【実装方針】: ネットワーク状態と入力テキスト長でボタン有効/無効を制御
/// 【設計方針】: ConsumerStatefulWidgetでRiverpod連携、状態はローカル管理
/// 【テスト対応】: TC-068-001, TC-068-004, TC-068-006〜TC-068-012, TC-068-015
/// 【アクセシビリティ】: Semanticsラベル付与、最小タップサイズ保証
/// 🔵 信頼性レベル: 青信号 - REQ-901, REQ-902, REQ-2006, REQ-3004に基づく
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../network/domain/models/network_state.dart';
import '../../../network/providers/network_provider.dart';
import '../../domain/models/politeness_level.dart';

// =============================================================================
// 定数定義
// =============================================================================

/// 【設定定数】: 入力テキストの最小文字数
/// 【調整可能性】: API仕様変更時に変更が必要
/// 🔵 信頼性レベル: 青信号 - API仕様（api-endpoints.md）
const int kMinInputLength = 2;

/// 【設定定数】: 最小タップターゲットサイズ（ピクセル）
/// 【調整可能性】: アクセシビリティ要件に応じて60pxに拡大可能
/// 🔵 信頼性レベル: 青信号 - REQ-5001（44px以上）
const double kMinTapTargetSize = 44.0;

/// 【設定定数】: ローディングインジケーターのサイズ
/// 🟡 信頼性レベル: 黄信号 - ボタン内表示に適したサイズ
const double _loadingIndicatorSize = 20.0;

/// 【設定定数】: ローディングインジケーターのストローク幅
/// 🟡 信頼性レベル: 黄信号 - 視認性を考慮した太さ
const double _loadingIndicatorStrokeWidth = 2.0;

// =============================================================================
// AIConversionButton
// =============================================================================

/// 【ウィジェット定義】: AI変換ボタン
///
/// 【機能概要】: AI変換を実行するメインボタン
/// 【責務】:
/// - ネットワーク状態に基づくボタン有効/無効制御
/// - 入力テキスト長に基づくバリデーション
/// - ローディング状態の表示
/// - 重複タップ防止
///
/// REQ-901: 短い入力を丁寧な文章に変換
/// REQ-3004: オフライン時はボタン無効化
/// 🔵 信頼性レベル: 青信号
class AIConversionButton extends ConsumerStatefulWidget {
  /// 【コンストラクタ】: AIConversionButton
  ///
  /// 【パラメータ】:
  /// - [inputText]: 変換対象のテキスト（2文字以上必須）
  /// - [politenessLevel]: 丁寧さレベル（REQ-903）
  /// - [onConvert]: 変換処理のコールバック
  /// - [onConversionStart]: 変換開始時の通知（オプション）
  /// - [onConversionComplete]: 変換完了時の通知（オプション）
  /// 🔵 信頼性レベル: 青信号
  const AIConversionButton({
    super.key,
    required this.inputText,
    required this.politenessLevel,
    required this.onConvert,
    this.onConversionStart,
    this.onConversionComplete,
  });

  /// 【プロパティ定義】: 変換対象の入力テキスト
  /// 【制約】: 2文字以上500文字以下（API仕様）
  /// 🔵 信頼性レベル: 青信号 - REQ-901
  final String inputText;

  /// 【プロパティ定義】: 丁寧さレベル
  /// 【用途】: API呼び出し時のパラメータ
  /// 🔵 信頼性レベル: 青信号 - REQ-903
  final PolitenessLevel politenessLevel;

  /// 【プロパティ定義】: 変換実行時のコールバック（変換ロジックを外部から注入）
  /// 【設計方針】: 依存性注入パターンでテスタビリティを確保
  /// 🔵 信頼性レベル: 青信号
  final Future<String> Function() onConvert;

  /// 【プロパティ定義】: 変換開始時のコールバック（オプション）
  /// 【用途】: 親ウィジェットでのUI状態同期
  /// 🟡 信頼性レベル: 黄信号 - UI連携のため
  final VoidCallback? onConversionStart;

  /// 【プロパティ定義】: 変換完了時のコールバック（オプション）
  /// 【用途】: 変換結果の親ウィジェットへの伝達
  /// 🟡 信頼性レベル: 黄信号 - UI連携のため
  final void Function(String result)? onConversionComplete;

  @override
  ConsumerState<AIConversionButton> createState() => _AIConversionButtonState();
}

/// 【State定義】: AIConversionButtonの状態管理
///
/// 【責務】: ローディング状態の管理、ボタン有効/無効判定
/// 🔵 信頼性レベル: 青信号
class _AIConversionButtonState extends ConsumerState<AIConversionButton> {
  /// 【状態変数】: ローディング中かどうか
  /// 【用途】: 重複タップ防止、ローディングインジケーター表示
  /// 🔵 信頼性レベル: 青信号 - REQ-2006
  bool _isLoading = false;

  /// 【メソッド定義】: ボタンが有効かどうかを判定
  ///
  /// 【判定条件】:
  /// 1. ローディング中でないこと
  /// 2. オンライン状態であること
  /// 3. 入力テキストが最小文字数以上であること
  ///
  /// 【パフォーマンス】: 短絡評価で不要な判定をスキップ
  /// 🔵 信頼性レベル: 青信号 - REQ-3004, API仕様
  bool _isButtonEnabled(NetworkState networkState) {
    // 【条件判定】: ローディング中は無効（重複タップ防止）
    // 🟡 信頼性レベル: 黄信号 - REQ-5002から推測
    if (_isLoading) return false;

    // 【条件判定】: オフライン時は無効
    // 🔵 信頼性レベル: 青信号 - REQ-3004
    if (networkState != NetworkState.online) return false;

    // 【条件判定】: 入力テキストが最小文字数未満は無効
    // 🔵 信頼性レベル: 青信号 - API仕様
    if (widget.inputText.length < kMinInputLength) return false;

    return true;
  }

  /// 【メソッド定義】: AI変換を実行
  ///
  /// 【処理フロー】:
  /// 1. ローディング状態開始
  /// 2. 変換開始コールバック呼び出し
  /// 3. 変換処理実行
  /// 4. 変換完了コールバック呼び出し
  /// 5. ローディング状態終了
  ///
  /// 【エラーハンドリング】: finallyブロックで確実にローディング状態を解除
  /// 【セキュリティ】: マウント状態を確認してからsetStateを呼び出し
  /// 🔵 信頼性レベル: 青信号 - REQ-901
  Future<void> _executeConversion() async {
    // 【状態更新】: ローディング開始
    setState(() {
      _isLoading = true;
    });

    // 【コールバック呼び出し】: 変換開始を通知
    widget.onConversionStart?.call();

    try {
      // 【変換実行】: 外部から注入された変換ロジックを実行
      // 🔵 信頼性レベル: 青信号 - REQ-901
      final result = await widget.onConvert();

      // 【コールバック呼び出し】: 変換完了を通知
      widget.onConversionComplete?.call(result);
    } finally {
      // 【状態更新】: ローディング終了（マウント状態を確認）
      // 【安全性確保】: アンマウント後のsetState呼び出しを防止
      // 🟡 信頼性レベル: 黄信号 - Flutterベストプラクティス
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 【状態取得】: ネットワーク状態を監視
    // 【リアクティブ更新】: ネットワーク状態変化時に自動再描画
    // 🔵 信頼性レベル: 青信号 - REQ-3004
    final networkState = ref.watch(networkProvider);
    final isEnabled = _isButtonEnabled(networkState);

    // 【UI構築】: AI変換ボタン
    // 🔵 信頼性レベル: 青信号 - REQ-901
    return Semantics(
      // 【アクセシビリティ】: スクリーンリーダー用ラベル
      // 🟡 信頼性レベル: 黄信号 - REQ-5001から推測
      label: _isLoading ? 'AI変換中' : 'AI変換ボタン',
      button: true,
      enabled: isEnabled,
      child: SizedBox(
        // 【アクセシビリティ対応】: 最小タップターゲットサイズを保証
        // 🔵 信頼性レベル: 青信号 - REQ-5001
        height: kMinTapTargetSize,
        child: ElevatedButton(
          // 【タップ処理】: 有効時のみ変換を実行
          onPressed: isEnabled ? _executeConversion : null,
          child: _isLoading
              // 【ローディング表示】: 変換中はインジケーターを表示
              // 🔵 信頼性レベル: 青信号 - REQ-2006
              ? const SizedBox(
                  width: _loadingIndicatorSize,
                  height: _loadingIndicatorSize,
                  child: CircularProgressIndicator(
                    strokeWidth: _loadingIndicatorStrokeWidth,
                  ),
                )
              // 【通常表示】: 「AI変換」ラベル
              // 🔵 信頼性レベル: 青信号 - REQ-901
              : const Text('AI変換'),
        ),
      ),
    );
  }
}

// =============================================================================
// OfflineIndicator
// =============================================================================

/// 【ウィジェット定義】: オフライン状態インジケーター
///
/// 【機能概要】: オフライン時に視覚的なフィードバックを提供
/// 【責務】: ネットワーク状態の表示のみ（状態変更は行わない）
///
/// REQ-3004: オフライン時の状態表示
/// 🔵 信頼性レベル: 青信号
class OfflineIndicator extends ConsumerWidget {
  /// 【コンストラクタ】: OfflineIndicator
  /// 🔵 信頼性レベル: 青信号
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 【状態取得】: ネットワーク状態を監視
    // 🔵 信頼性レベル: 青信号 - REQ-3004
    final networkState = ref.watch(networkProvider);

    // 【条件判定】: オフライン時のみ表示
    if (networkState != NetworkState.offline) {
      return const SizedBox.shrink();
    }

    // 【UI構築】: オフライン状態表示
    // 🔵 信頼性レベル: 青信号 - REQ-3004
    return Semantics(
      // 【アクセシビリティ】: スクリーンリーダー用ラベル
      // 🟡 信頼性レベル: 黄信号 - REQ-5001から推測
      label: 'オフライン状態です。AI変換機能は利用できません。',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 16, color: Colors.orange),
            SizedBox(width: 4),
            Text(
              'オフライン',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

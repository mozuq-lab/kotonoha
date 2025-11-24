/// 緊急画面ウィジェット
///
/// TASK-0047: 緊急音・画面赤表示実装
/// 関連要件: REQ-304（画面赤表示）、FR-004〜FR-008
/// 信頼性レベル: 青信号（要件定義書ベース）
///
/// 緊急呼び出し中に表示されるフルスクリーンオーバーレイ。
/// 赤い背景、「緊急呼び出し中」メッセージ、リセットボタンを表示。
///
/// ## 使用例
///
/// ```dart
/// // 緊急状態の時にオーバーレイとして表示
/// if (emergencyState == EmergencyStateEnum.alertActive) {
///   EmergencyAlertScreen(
///     onReset: () => ref.read(emergencyStateProvider.notifier).resetEmergency(),
///   );
/// }
/// ```
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/features/emergency/presentation/widgets/emergency_confirmation_dialog.dart';

// =============================================================================
// 定数定義
// =============================================================================

/// 緊急画面のUI定数
///
/// 緊急画面のサイズ・スタイル設定を一元管理。
/// 将来的にAppSizesへの統合を検討。
abstract class _EmergencyAlertConstants {
  /// リセットボタンの最小幅
  static const double resetButtonMinWidth = 120.0;

  /// リセットボタンの最小高さ
  static const double resetButtonMinHeight = 56.0;

  /// 警告アイコンのサイズ（80px以上必須）
  static const double iconSize = 100.0;

  /// 緊急メッセージのフォントサイズ
  static const double messageFontSize = 32.0;

  /// リセットボタンのフォントサイズ
  static const double buttonFontSize = 18.0;

  /// 警告メッセージのフォントサイズ
  static const double warningFontSize = 16.0;

  /// セマンティクスラベル: 緊急画面
  static const String semanticsLabelScreen = '緊急呼び出し中';

  /// セマンティクスラベル: リセットボタン
  static const String semanticsLabelResetButton = '緊急呼び出しを解除';
}

/// 緊急画面ウィジェット
///
/// 緊急呼び出し中に表示されるフルスクリーンオーバーレイ。
///
/// デザイン仕様:
/// - 背景: 赤色（全画面）
/// - アイコン: 白色の警告アイコン（80px以上）
/// - メッセージ: 「緊急呼び出し中」（白文字）
/// - リセットボタン: 白背景・黒文字
/// - オプション: 警告メッセージ（マナーモード時など）
///
/// アクセシビリティ:
/// - Semantics「緊急呼び出し中」を設定
/// - リセットボタンは44x44px以上
/// - タップのみで操作完結
///
/// 使用例:
/// ```dart
/// // オーバーレイとして表示
/// Stack(
///   children: [
///     // 通常の画面コンテンツ
///     NormalScreen(),
///     // 緊急画面（alertActive時のみ表示）
///     if (state == EmergencyStateEnum.alertActive)
///       EmergencyAlertScreen(
///         onReset: () => notifier.resetEmergency(),
///       ),
///   ],
/// )
/// ```
class EmergencyAlertScreen extends StatefulWidget {
  /// リセットボタンタップ時のコールバック
  final VoidCallback onReset;

  /// 警告メッセージ（オプション）
  ///
  /// マナーモード時や音量ゼロ時に表示する警告。
  /// 例: 「マナーモードのため音が鳴りません」
  final String? warningMessage;

  /// EmergencyAlertScreen を作成する
  ///
  /// [onReset] - リセットボタンタップ時のコールバック（必須）
  /// [warningMessage] - 警告メッセージ（オプション）
  const EmergencyAlertScreen({
    super.key,
    required this.onReset,
    this.warningMessage,
  });

  @override
  State<EmergencyAlertScreen> createState() => _EmergencyAlertScreenState();
}

/// EmergencyAlertScreen の状態管理クラス
class _EmergencyAlertScreenState extends State<EmergencyAlertScreen> {
  /// 処理中フラグ（連続タップ防止用）
  bool _isProcessing = false;

  // ---------------------------------------------------------------------------
  // 定数（TextStyleはconst化のためstaticで定義）
  // ---------------------------------------------------------------------------

  /// 緊急メッセージのテキストスタイル
  static const TextStyle _messageTextStyle = TextStyle(
    color: Colors.white,
    fontSize: _EmergencyAlertConstants.messageFontSize,
    fontWeight: FontWeight.bold,
  );

  /// リセットボタンのテキストスタイル
  static const TextStyle _buttonTextStyle = TextStyle(
    fontSize: _EmergencyAlertConstants.buttonFontSize,
    fontWeight: FontWeight.bold,
  );

  /// 警告メッセージのテキストスタイル
  static const TextStyle _warningTextStyle = TextStyle(
    color: Colors.black,
    fontSize: _EmergencyAlertConstants.warningFontSize,
    fontWeight: FontWeight.bold,
  );

  // ---------------------------------------------------------------------------
  // イベントハンドラ
  // ---------------------------------------------------------------------------

  /// リセットボタンタップ処理（連続タップ防止付き）
  ///
  /// 連続タップを防止するため、一度タップされると
  /// [_isProcessing]フラグがtrueになり、以降のタップは無視される。
  void _handleReset() {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    widget.onReset();
  }

  // ---------------------------------------------------------------------------
  // ビルドメソッド
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // テーマに応じた緊急色を取得
    final emergencyColor =
        EmergencyConfirmationDialog.getEmergencyColor(context);

    return Semantics(
      label: _EmergencyAlertConstants.semanticsLabelScreen,
      child: Material(
        color: emergencyColor,
        child: SizedBox.expand(
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 警告アイコン
                _buildWarningIcon(),
                const SizedBox(height: AppSizes.paddingLarge),

                // 緊急メッセージ
                _buildEmergencyMessage(),
                const SizedBox(height: AppSizes.paddingMedium),

                // 警告メッセージ（オプション）
                if (widget.warningMessage != null) ...[
                  _buildWarningMessage(),
                  const SizedBox(height: AppSizes.paddingLarge),
                ] else
                  const SizedBox(height: AppSizes.paddingXLarge),

                // リセットボタン
                _buildResetButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // プライベートウィジェット構築メソッド
  // ---------------------------------------------------------------------------

  /// 警告アイコンを構築
  ///
  /// 赤い背景に映える白色の警告アイコン。
  /// サイズは80px以上（アクセシビリティ要件）。
  Widget _buildWarningIcon() {
    return const Icon(
      Icons.warning,
      color: Colors.white,
      size: _EmergencyAlertConstants.iconSize,
    );
  }

  /// 緊急メッセージを構築
  ///
  /// 「緊急呼び出し中」のメインメッセージを白文字で表示。
  Widget _buildEmergencyMessage() {
    return const Text(
      _EmergencyAlertConstants.semanticsLabelScreen,
      style: _messageTextStyle,
    );
  }

  /// 警告メッセージを構築（マナーモード時など）
  ///
  /// 音が鳴らない状況（マナーモード、音量ゼロなど）で
  /// ユーザーに視覚的なフィードバックを提供。
  Widget _buildWarningMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMedium,
        vertical: AppSizes.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: Colors.yellow.shade700,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
      ),
      child: Text(
        widget.warningMessage!,
        style: _warningTextStyle,
        textAlign: TextAlign.center,
      ),
    );
  }

  /// リセットボタンを構築
  ///
  /// 緊急状態を解除するためのボタン。
  /// - 白背景・黒文字で視認性を確保
  /// - 最小タップターゲット44x44px以上（アクセシビリティ要件）
  /// - 連続タップ防止機能付き
  Widget _buildResetButton() {
    return Semantics(
      label: _EmergencyAlertConstants.semanticsLabelResetButton,
      button: true,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _handleReset,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          minimumSize: const Size(
            _EmergencyAlertConstants.resetButtonMinWidth,
            _EmergencyAlertConstants.resetButtonMinHeight,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingLarge,
            vertical: AppSizes.paddingMedium,
          ),
        ),
        child: const Text(
          'リセット',
          style: _buttonTextStyle,
        ),
      ),
    );
  }
}

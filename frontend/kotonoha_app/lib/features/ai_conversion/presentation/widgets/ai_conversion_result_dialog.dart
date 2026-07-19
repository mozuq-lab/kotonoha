/// AI変換結果表示・選択ダイアログ ウィジェット
///
/// TASK-0069: AI変換結果表示・選択UI
/// 要件: REQ-902（AI変換結果表示・採用選択）、REQ-904（再生成・元の文使用）
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
///
/// AI変換の結果を表示し、ユーザーが「採用」「再生成」「元の文を使う」
/// の選択ができるダイアログ。
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_colors.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/core/constants/app_text_styles.dart';
import 'package:kotonoha_app/features/ai_conversion/domain/models/politeness_level.dart';

/// ダイアログの最大幅
const double kDialogMaxWidth = 400.0;

/// ダイアログの最小幅
const double kDialogMinWidth = 300.0;

/// 変換結果表示エリアの最大高さ
const double kResultAreaMaxHeight = 200.0;

/// AI変換結果表示・選択ダイアログ
///
/// REQ-902: AI変換結果を表示し、採用・却下を選択可能
/// REQ-904: 再生成または元の文を使用できる機能を提供
///
/// デザイン仕様:
/// - タイトル: 「AI変換結果」
/// - 元の文セクション: ラベル + 元のテキスト表示
/// - 変換結果セクション: ラベル + 変換後テキスト表示（強調）
/// - 丁寧さレベル表示: 使用したレベルを表示
/// - 「採用」ボタン: プライマリカラー、大きめサイズ
/// - 「再生成」「元の文を使う」ボタン: セカンダリカラー、横並び
/// - ダイアログ外タップでは閉じない（barrierDismissible: false）
/// - 連続タップ防止機能
///
/// 使用例:
/// ```dart
/// AIConversionResultDialog.show(
///   context: context,
///   originalText: '水 ぬるく',
///   convertedText: 'お水をぬるめでお願いします',
///   politenessLevel: PolitenessLevel.polite,
///   onAdopt: (result) {
///     Navigator.of(context).pop();
///     inputController.text = result;
///   },
///   onRegenerate: () {
///     Navigator.of(context).pop();
///     startAIConversion();
///   },
///   onUseOriginal: (original) {
///     Navigator.of(context).pop();
///     inputController.text = original;
///   },
/// );
/// ```
class AIConversionResultDialog extends StatefulWidget {
  /// 元の入力テキスト
  final String originalText;

  /// 変換後のテキスト
  final String convertedText;

  /// 使用した丁寧さレベル
  final PolitenessLevel politenessLevel;

  /// 「採用」タップ時コールバック
  final void Function(String result) onAdopt;

  /// 「再生成」タップ時コールバック
  final VoidCallback onRegenerate;

  /// 「元の文を使う」タップ時コールバック
  final void Function(String original) onUseOriginal;

  /// AIConversionResultDialogを作成する
  ///
  /// [originalText] - 元の入力テキスト（必須）
  /// [convertedText] - 変換後のテキスト（必須）
  /// [politenessLevel] - 使用した丁寧さレベル（必須）
  /// [onAdopt] - 「採用」タップ時のコールバック（必須）
  /// [onRegenerate] - 「再生成」タップ時のコールバック（必須）
  /// [onUseOriginal] - 「元の文を使う」タップ時のコールバック（必須）
  const AIConversionResultDialog({
    super.key,
    required this.originalText,
    required this.convertedText,
    required this.politenessLevel,
    required this.onAdopt,
    required this.onRegenerate,
    required this.onUseOriginal,
  });

  /// ダイアログを表示するヘルパーメソッド
  ///
  /// barrierDismissible: false で誤操作防止（REQ-5002）
  static Future<void> show({
    required BuildContext context,
    required String originalText,
    required String convertedText,
    required PolitenessLevel politenessLevel,
    required void Function(String result) onAdopt,
    required VoidCallback onRegenerate,
    required void Function(String original) onUseOriginal,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AIConversionResultDialog(
        originalText: originalText,
        convertedText: convertedText,
        politenessLevel: politenessLevel,
        onAdopt: onAdopt,
        onRegenerate: onRegenerate,
        onUseOriginal: onUseOriginal,
      ),
    );
  }

  @override
  State<AIConversionResultDialog> createState() =>
      _AIConversionResultDialogState();
}

/// AIConversionResultDialogの状態管理クラス
class _AIConversionResultDialogState extends State<AIConversionResultDialog> {
  /// 処理中フラグ（連続タップ防止用）
  bool _isProcessing = false;

  /// 高コントラストモードかどうか判定
  bool _isHighContrastMode(ThemeData theme) =>
      theme.colorScheme.primary == AppColors.primaryHighContrast;

  /// ダークモードかどうか判定
  bool _isDarkMode(ThemeData theme) => theme.brightness == Brightness.dark;

  /// テーマに応じたプライマリボタンの色を取得
  Color _getPrimaryButtonColor(ThemeData theme) {
    if (_isHighContrastMode(theme)) return AppColors.primaryHighContrast;
    if (_isDarkMode(theme)) return AppColors.primaryDark;
    return AppColors.primaryLight;
  }

  /// テーマに応じたセカンダリボタンの背景色を取得
  Color _getSecondaryButtonColor(ThemeData theme) {
    if (_isHighContrastMode(theme)) return AppColors.cancelButtonHighContrast;
    if (_isDarkMode(theme)) return AppColors.cancelButtonDark;
    return AppColors.cancelButtonLight;
  }

  /// テーマに応じたセカンダリボタンのテキスト色を取得
  Color _getSecondaryButtonTextColor(ThemeData theme) {
    if (_isDarkMode(theme) && !_isHighContrastMode(theme)) return Colors.black;
    return Colors.white;
  }

  /// テーマに応じた変換結果の背景色を取得
  Color _getResultBackgroundColor(ThemeData theme) {
    if (_isHighContrastMode(theme)) return Colors.yellow.withValues(alpha: 0.3);
    if (_isDarkMode(theme)) return AppColors.primaryDark.withValues(alpha: 0.2);
    return AppColors.primaryLight.withValues(alpha: 0.1);
  }

  /// ボタンタップ処理（連続タップ防止付き）
  void _handleTap(VoidCallback callback) {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    callback();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondaryButtonColor = _getSecondaryButtonColor(theme);
    final secondaryTextColor = _getSecondaryButtonTextColor(theme);

    return Semantics(
      label: 'AI変換結果ダイアログ',
      child: AlertDialog(
        title: Text(
          'AI変換結果',
          style: AppTextStyles.headingMedium,
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: kDialogMaxWidth,
            minWidth: kDialogMinWidth,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOriginalTextSection(theme),
                const SizedBox(height: AppSizes.paddingMedium),
                _buildConvertedTextSection(theme),
              ],
            ),
          ),
        ),
        actions: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAdoptButton(theme),
              const SizedBox(height: AppSizes.paddingSmall),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: _buildRegenerateButton(
                      secondaryButtonColor,
                      secondaryTextColor,
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingSmall),
                  Expanded(
                    child: _buildUseOriginalButton(theme),
                  ),
                ],
              ),
            ],
          ),
        ],
        actionsPadding: const EdgeInsets.all(AppSizes.paddingMedium),
      ),
    );
  }

  /// 元の文セクションを構築
  ///
  /// 【AA対応】: ラベル文字色にColors.grey(#9E9E9E)を使用していたため、
  /// 背景（白系サーフェス）との組み合わせで約2.8:1しかなくWCAG AA（4.5:1）未達だった。
  /// テーマのcolorScheme.onSurfaceは各テーマのサーフェス色との組み合わせで
  /// AAを大きく上回るよう定義済み（ライト/高コントラスト: 黒文字で約21:1、
  /// ダーク: 白文字で約16.7:1）であるため、これをそのまま使用する。
  Widget _buildOriginalTextSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '元の文',
          style: AppTextStyles.bodySmall.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSizes.paddingXSmall),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
          ),
          child: Text(
            widget.originalText,
            style: AppTextStyles.bodyMedium,
          ),
        ),
      ],
    );
  }

  /// 変換結果セクションを構築
  Widget _buildConvertedTextSection(ThemeData theme) {
    final resultBackgroundColor = _getResultBackgroundColor(theme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '変換結果',
              style: AppTextStyles.bodySmall.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: AppSizes.paddingSmall),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingSmall,
                vertical: AppSizes.paddingXSmall,
              ),
              decoration: BoxDecoration(
                color: _getPrimaryButtonColor(theme).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall),
              ),
              child: Text(
                widget.politenessLevel.displayName,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.paddingXSmall),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(
            maxHeight: kResultAreaMaxHeight,
          ),
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          decoration: BoxDecoration(
            color: resultBackgroundColor,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
            border: Border.all(
              color: _getPrimaryButtonColor(theme),
              width: 2,
            ),
          ),
          child: SingleChildScrollView(
            child: Text(
              widget.convertedText,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 「採用」ボタンを構築
  ///
  /// 【AA対応】: 従来は背景色（テーマのプライマリカラー）に関わらず
  /// 文字色をColors.white固定にしていたため、ライトテーマの
  /// primaryLight(#2196F3)+白文字で約3.1:1しかなくWCAG AA（4.5:1）未達だった。
  /// 各テーマのcolorScheme.onPrimaryは背景（colorScheme.primary）との組み合わせで
  /// AAを満たすよう定義済み（ライト: 黒文字で約6.7:1、ダーク: 白文字で約4.6:1、
  /// 高コントラスト: 白文字で約21:1）であるため、これをそのまま使用する。
  Widget _buildAdoptButton(ThemeData theme) {
    final backgroundColor = _getPrimaryButtonColor(theme);
    final foregroundColor = theme.colorScheme.onPrimary;
    return SizedBox(
      width: double.infinity,
      height: AppSizes.recommendedTapTarget,
      child: ElevatedButton(
        onPressed: _isProcessing
            ? null
            : () => _handleTap(() => widget.onAdopt(widget.convertedText)),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          minimumSize: const Size(
            double.infinity,
            AppSizes.minTapTarget,
          ),
        ),
        child: Text('採用', style: AppTextStyles.buttonLarge),
      ),
    );
  }

  /// 「再生成」ボタンを構築
  Widget _buildRegenerateButton(Color backgroundColor, Color textColor) {
    return SizedBox(
      height: AppSizes.minTapTarget,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : () => _handleTap(widget.onRegenerate),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          minimumSize: const Size(
            AppSizes.dialogButtonMinWidth,
            AppSizes.minTapTarget,
          ),
        ),
        child: Text('再生成', style: AppTextStyles.button),
      ),
    );
  }

  /// 「元の文を使う」ボタンを構築
  Widget _buildUseOriginalButton(ThemeData theme) {
    return SizedBox(
      height: AppSizes.minTapTarget,
      child: OutlinedButton(
        onPressed: _isProcessing
            ? null
            : () => _handleTap(() => widget.onUseOriginal(widget.originalText)),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(
            AppSizes.dialogButtonMinWidth,
            AppSizes.minTapTarget,
          ),
          side: BorderSide(
            color: _getPrimaryButtonColor(theme),
          ),
        ),
        child: Text('元の文を使う', style: AppTextStyles.button),
      ),
    );
  }
}

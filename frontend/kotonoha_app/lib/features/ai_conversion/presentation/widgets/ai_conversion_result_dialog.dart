/// AI変換結果表示・選択ダイアログ ウィジェット
/// AI変換の結果を表示し、ユーザーが「採用」「再生成」「キャンセル」
/// の選択ができるダイアログ。
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_colors.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/core/utils/spoken_label.dart';
import 'package:kotonoha_app/core/constants/app_text_styles.dart';
import 'package:kotonoha_app/core/themes/app_visual_theme.dart';
import 'package:kotonoha_app/features/ai_conversion/domain/exceptions/ai_conversion_exception.dart';
import 'package:kotonoha_app/features/ai_conversion/domain/models/politeness_level.dart';
import 'package:kotonoha_app/features/ai_conversion/presentation/widgets/politeness_level_selector.dart';

/// ダイアログの最大幅
const double kDialogMaxWidth = 400.0;

/// ダイアログの最小幅
const double kDialogMinWidth = 300.0;

/// 変換結果表示エリアの最大高さ
const double kResultAreaMaxHeight = 200.0;

/// AI変換結果表示・選択ダイアログ
/// AI変換結果を表示し、採用・却下を選択可能
/// 再生成、またはキャンセルして入力をそのまま残せる
/// デザイン仕様
/// タイトル: 「AI変換結果」
/// 元の文セクション: ラベル + 元のテキスト表示
/// 変換結果セクション: ラベル + 変換後テキスト表示（強調）
/// 丁寧さレベル表示: 使用したレベルを表示
/// 「採用」ボタン: プライマリカラーの塗り、大きめサイズ
/// 「再生成」ボタン: プライマリカラーの枠、「キャンセル」ボタン: 灰色の枠。横並び
/// ダイアログ外タップでは閉じない（barrierDismissible: false）
/// 連続タップ防止機能
/// 使用例
/// ```dart
/// AIConversionResultDialog.show(
/// context: context
/// originalText: '水 ぬるく'
/// convertedText: 'お水をぬるめでお願いします'
/// politenessLevel: PolitenessLevel.polite
/// onAdopt: (result) {
/// inputController.text = result;
/// }
/// onRegenerate:  {
/// startAIConversion;
/// }
/// );
/// ```
/// 重要showヘルパー経由で表示した場合、ボタンタップ時にダイアログは
/// show内部で自動的に閉じられる（builderのdialogContextでpopする）。
/// そのためコールバック側でNavigator.popを呼んではならない。
/// showDialogはroot Navigatorにダイアログを積む一方、呼び出し元contextは
/// go_routerのShellRoute配下branch Navigatorに属するため
/// 呼び出し元contextでのpopはダイアログではなく背後のページを弾いてしまう。
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

  /// 「キャンセル」タップ時コールバック。入力には触れず、閉じるだけ
  final VoidCallback onCancel;

  /// 丁寧さを選び直したときの変換処理。
  /// 今と違う丁寧さを選ぶと呼ばれ、返った文でダイアログ内の変換結果を
  /// 差し替える（ダイアログは閉じない）。失敗は例外で返し、ダイアログ内に
  /// 告げる。変換を待つ間も「採用」「キャンセル」は押せる（閉じ込めない）。
  final Future<String> Function(PolitenessLevel level) onLevelChanged;

  /// AIConversionResultDialogを作成する
  /// [originalText] - 元の入力テキスト（必須）
  /// [convertedText] - 変換後のテキスト（必須）
  /// [politenessLevel] - 使用した丁寧さレベル（必須）
  /// [onAdopt] - 「採用」タップ時のコールバック（必須）
  /// [onRegenerate] - 「再生成」タップ時のコールバック（必須）
  /// [onCancel] - 「キャンセル」タップ時のコールバック（必須）
  const AIConversionResultDialog({
    super.key,
    required this.originalText,
    required this.convertedText,
    required this.politenessLevel,
    required this.onAdopt,
    required this.onRegenerate,
    required this.onCancel,
    required this.onLevelChanged,
  });

  /// ダイアログを表示するヘルパーメソッド
  /// barrierDismissible: false で誤操作防止
  /// pop責任このヘルパーはbuilderに渡されるdialogContext（root Navigator上）で
  /// ダイアログ自身を閉じるため、コールバック側でNavigator.popを呼ぶ必要はない。
  /// 呼び出し元のcontextはgo_router ShellRoute配下のbranch Navigatorに属するため
  /// そちらでpopするとダイアログではなく背後ページがpopされてしまう。
  static Future<void> show({
    required BuildContext context,
    required String originalText,
    required String convertedText,
    required PolitenessLevel politenessLevel,
    required void Function(String result) onAdopt,
    required VoidCallback onRegenerate,
    required Future<String> Function(PolitenessLevel level) onLevelChanged,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AIConversionResultDialog(
        originalText: originalText,
        convertedText: convertedText,
        politenessLevel: politenessLevel,
        onAdopt: (result) {
          Navigator.of(dialogContext).pop();
          onAdopt(result);
        },
        onRegenerate: () {
          Navigator.of(dialogContext).pop();
          onRegenerate();
        },
        // キャンセルは入力に触れず、閉じるだけ
        onCancel: () => Navigator.of(dialogContext).pop(),
        onLevelChanged: onLevelChanged,
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

  /// 表示中の変換結果と丁寧さ（丁寧さを選び直すと差し替わる）
  late String _convertedText = widget.convertedText;
  late PolitenessLevel _politenessLevel = widget.politenessLevel;

  /// 丁寧さを選び直して変換し直している最中か
  bool _isChangingLevel = false;

  /// 選び直した丁寧さでの変換に失敗したときの告知
  String? _levelChangeError;

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

  /// テーマに応じた変換結果ボックスの背景色を取得
  /// AA対応: 以前は `primary.withValues(alpha: 0.1〜0.3)` の半透明色を
  /// 使っていたため、実際の色はダイアログ背景との合成結果に依存し
  /// コントラスト比を計算・検証できなかった。合成後と同じ色を不透明な
  /// 定数として持つことで、見た目を変えずに検証可能にする。
  Color _getResultBackgroundColor(ThemeData theme) {
    if (_isHighContrastMode(theme)) {
      return AppColors.aiResultContainerHighContrast;
    }
    if (_isDarkMode(theme)) return AppColors.aiResultContainerDark;
    return AppColors.aiResultContainerLight;
  }

  /// テーマに応じた変換結果の枠線色を取得
  /// AA対応: 以前はテーマのプライマリ色をそのまま枠線に使っていたため
  /// ライトで 2.60:1（ボックス背景）／2.87:1（ダイアログ背景）と
  /// 非テキスト基準(3:1)未達だった。枠線は「隣接する色」の双方から
  /// 3:1 以上離す必要があるため、専用色を用意する。
  Color _getResultOutlineColor(ThemeData theme) {
    if (_isHighContrastMode(theme)) {
      return AppColors.aiResultOutlineHighContrast;
    }
    if (_isDarkMode(theme)) return AppColors.aiResultOutlineDark;
    return AppColors.aiResultOutlineLight;
  }

  /// 丁寧さを選び直し、その丁寧さで変換し直した結果に差し替える
  Future<void> _changeLevel(PolitenessLevel level) async {
    if (level == _politenessLevel || _isProcessing || _isChangingLevel) return;
    setState(() {
      _isChangingLevel = true;
      _levelChangeError = null;
    });
    try {
      final text = await widget.onLevelChanged(level);
      if (!mounted) return;
      setState(() {
        _convertedText = text;
        _politenessLevel = level;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _levelChangeError = e is AIConversionException
            ? e.message
            : 'AI変換に失敗しました。しばらく待ってから再度お試しください。';
      });
    } finally {
      if (mounted) setState(() => _isChangingLevel = false);
    }
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

    return Semantics(
      label: spokenLabel('AI変換結果ダイアログ'),
      child: AlertDialog(
        title: Text(
          'AI変換結果',
          semanticsLabel: spokenLabel('AI変換結果'),
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
                    child: _buildRegenerateButton(theme),
                  ),
                  const SizedBox(width: AppSizes.paddingSmall),
                  Expanded(
                    child: _buildCancelButton(theme),
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
  /// AA対応: ラベル文字色にColors.grey(#9E9E9E)を使用していたため
  /// 背景（白系サーフェス）との組み合わせで約2.8:1しかなくWCAG AA（4.5:1）未達だった。
  /// テーマのcolorScheme.onSurfaceは各テーマのサーフェス色との組み合わせで
  /// AAを大きく上回るよう定義済み（ライト/高コントラスト: 黒文字で約21:1
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
    final resultOutlineColor = _getResultOutlineColor(theme);

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
          ],
        ),
        const SizedBox(height: AppSizes.paddingXSmall),
        // 丁寧さの選択は結果の文より上に置く。結果が長いときや文字を
        // 拡大したときに、ダイアログ内をスクロールしないと届かない位置へ
        // 押し出されないようにするため。
        PolitenessLevelSelector(
          selectedLevel: _politenessLevel,
          enabled: !_isProcessing && !_isChangingLevel,
          onLevelChanged: _changeLevel,
        ),
        if (_isChangingLevel)
          const Padding(
            padding: EdgeInsets.only(top: AppSizes.paddingXSmall),
            child: LinearProgressIndicator(),
          ),
        if (_levelChangeError != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSizes.paddingXSmall),
            child: Text(
              _levelChangeError!,
              semanticsLabel: spokenLabel(_levelChangeError!),
              style: AppTextStyles.bodySmall.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        const SizedBox(height: AppSizes.paddingSmall),
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
              color: resultOutlineColor,
              width: 2,
            ),
          ),
          child: SingleChildScrollView(
            child: Text(
              _convertedText,
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
  /// AA対応: 従来は背景色（テーマのプライマリカラー）に関わらず
  /// 文字色をColors.white固定にしていたため、ライトテーマの
  /// primaryLight(#2196F3)+白文字で約3.1:1しかなくWCAG AA（4.5:1）未達だった。
  /// 各テーマのcolorScheme.onPrimaryは背景（colorScheme.primary）との組み合わせで
  /// AAを満たすよう定義済み（ライト: 黒文字で約6.7:1、ダーク: 白文字で約4.6:1
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
            : () => _handleTap(() => widget.onAdopt(_convertedText)),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          minimumSize: const Size(
            double.infinity,
            AppSizes.minTapTarget,
          ),
        ).copyWith(side: filledButtonSide(backgroundColor, theme.colorScheme)),
        child: Text('採用', style: AppTextStyles.buttonLarge),
      ),
    );
  }

  /// 「再生成」ボタンを構築
  /// 灰色の塗りでは押せないボタンやキャンセルに見えた（iPad、2026-10-18）。
  /// 操作なので基本色の枠と文字にする。色は変換結果ボックスの枠と同じで、
  /// ダイアログ背景に対して枠 3:1・文字 4.5:1 を満たす。枠は 2px にし、高コントラスト
  /// （枠も文字も黒）で 1px の「キャンセル」と見分ける。押せないとき（丁寧さを選び直して
  /// 待つ間）は、基本色の枠のままだと押せそうに見えるので、薄い灰色にする。
  Widget _buildRegenerateButton(ThemeData theme) {
    final color = _getResultOutlineColor(theme);
    return SizedBox(
      height: AppSizes.minTapTarget,
      child: OutlinedButton(
        onPressed: _isProcessing || _isChangingLevel
            ? null
            : () => _handleTap(widget.onRegenerate),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          minimumSize: const Size(
            AppSizes.dialogButtonMinWidth,
            AppSizes.minTapTarget,
          ),
        ).copyWith(
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.disabled)
                  ? theme.colorScheme.outline.withValues(alpha: 0.38)
                  : color,
              width: 2,
            ),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('再生成', style: AppTextStyles.button),
        ),
      ),
    );
  }

  /// 「キャンセル」ボタンを構築
  /// 取りやめなので、操作（基本色）と見分けられる灰色の枠と本文の色の文字にする。
  Widget _buildCancelButton(ThemeData theme) {
    return SizedBox(
      height: AppSizes.minTapTarget,
      child: OutlinedButton(
        onPressed: _isProcessing ? null : () => _handleTap(widget.onCancel),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurface,
          minimumSize: const Size(
            AppSizes.dialogButtonMinWidth,
            AppSizes.minTapTarget,
          ),
          side: BorderSide(color: theme.colorScheme.outline),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('キャンセル', style: AppTextStyles.button),
        ),
      ),
    );
  }
}

/// エラーダイアログ/スナックバー ウィジェット
///
/// TASK-0078: エラーUI・エラーメッセージ実装
///
/// 信頼性レベル: 青信号（要件定義書ベース）
/// 関連要件:
/// - NFR-204: 分かりやすい日本語エラーメッセージ
/// - EDGE-001: ネットワークエラー時の再試行オプション
/// - EDGE-002: AI変換エラー時のフォールバック
/// - EDGE-004: TTS再生エラー時のメッセージ
library;

import 'package:flutter/material.dart';

import '../themes/theme_colors.dart';

// =============================================================================
// エラースナックバーの配色
// =============================================================================

/// 設定定数: エラースナックバーの背景色（Colors.red[700] 相当）
const Color _snackBarBackground = Color(0xFFD32F2F);

/// 設定定数: エラースナックバーの前景色
/// 背景 #D32F2F に対し 4.98:1 で WCAG 2.1 AA (4.5:1) を満たす。
/// 信頼性レベル: 青信号 - 高コントラスト要件
const Color _snackBarForeground = Color(0xFFFFFFFF);

// =============================================================================
// 元テキスト表示ボックスの配色
// =============================================================================

/// 型定義: 元テキストボックスの配色一式
typedef OriginalTextBoxColors = ({
  Color background,
  Color border,
  Color label,
  Color body,
});

/// 機能概要: テーマの明暗に応じた元テキストボックスの配色を返す
///
/// 従来は背景を `Colors.grey[100]` (#F5F5F5) に固定し、本文は色未指定で
/// テーマ継承にしていた。そのためダークテーマでは白文字が near-white 背景に
/// 載り 1.09:1 と判読不能だった。またラベルの `Colors.grey[600]` は
/// テーマを問わず 4.23:1 でテキストのAA基準(4.5:1)未達だった。
///
/// 判定基準:
/// - 本文・ラベル（テキスト）: ボックス背景に対し 4.5:1 以上
/// - 枠線（非テキスト）: ダイアログ背景に対し 3:1 以上
///   ボックス背景はダイアログ背景と近いため、枠線が唯一の境界になる
///
/// 信頼性レベル: 青信号 - 高コントラスト要件
OriginalTextBoxColors originalTextBoxColors(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark
      // 背景 #2A2A2A に対し 本文14.4:1 / ラベル7.6:1、枠線はダイアログ背景に5.1:1
      ? (
          background: const Color(0xFF2A2A2A),
          border: const Color(0xFF8E8E8E),
          label: const Color(0xFFBDBDBD),
          body: const Color(0xFFFFFFFF),
        )
      // 背景 #EEEEEE に対し 本文13.9:1 / ラベル5.8:1、枠線はダイアログ背景に4.7:1
      // （高コントラストの白背景に対しても 5.1:1）
      : (
          background: const Color(0xFFEEEEEE),
          border: const Color(0xFF6E6E6E),
          label: const Color(0xFF5C5C5C),
          body: const Color(0xFF212121),
        );
}

// =============================================================================
// 汎用エラーダイアログ
// =============================================================================

/// 汎用エラーダイアログを表示する
///
/// [context] BuildContext
/// [title] ダイアログのタイトル
/// [message] エラーメッセージ
/// [showRetry] 再試行ボタンを表示するかどうか
/// [onRetry] 再試行ボタンのコールバック
///
/// NFR-204: 分かりやすい日本語エラーメッセージ
Future<void> showErrorDialog({
  required BuildContext context,
  required String title,
  required String message,
  bool showRetry = false,
  VoidCallback? onRetry,
}) async {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700]),
          const SizedBox(width: 8),
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(message),
      actions: [
        if (showRetry && onRetry != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry();
            },
            child: const Text('再試行'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

// =============================================================================
// エラースナックバー
// =============================================================================

/// エラースナックバーを表示する
///
/// [context] BuildContext
/// [message] エラーメッセージ
/// [showRetry] 再試行ボタンを表示するかどうか
/// [onRetry] 再試行ボタンのコールバック
/// [duration] 表示時間（デフォルト4秒）
///
/// NFR-204: 分かりやすい日本語エラーメッセージ
void showErrorSnackBar({
  required BuildContext context,
  required String message,
  bool showRetry = false,
  VoidCallback? onRetry,
  Duration duration = const Duration(seconds: 4),
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          // 背景を固定色にしているため本文色も明示する。
          // 色を指定しないと SnackBar のコンテンツ色（colorScheme.onInverseSurface）
          // を継承し、ダークテーマでは #1E1E1E が #D32F2F 背景に載って
          // 3.35:1 とAA未達になる。同じ Row の Icon / SnackBarAction は
          // もともと白を明示しており、本文だけが浮いていた。
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: _snackBarForeground),
            ),
          ),
        ],
      ),
      backgroundColor: _snackBarBackground,
      duration: duration,
      action: showRetry && onRetry != null
          ? SnackBarAction(
              label: '再試行',
              textColor: Colors.white,
              onPressed: onRetry,
            )
          : null,
    ),
  );
}

// =============================================================================
// ネットワークエラーダイアログ (EDGE-001)
// =============================================================================

/// ネットワークエラーダイアログを表示する
///
/// EDGE-001: ネットワークエラー時の再試行オプション
///
/// [context] BuildContext
/// [onRetry] 再試行ボタンのコールバック
/// [onCancel] キャンセルボタンのコールバック（オプション）
Future<void> showNetworkErrorDialog({
  required BuildContext context,
  required VoidCallback onRetry,
  VoidCallback? onCancel,
}) async {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.wifi_off, color: warningIconColor(context)),
          const SizedBox(width: 8),
          const Text('ネットワークエラー'),
        ],
      ),
      content: const Text(
        'インターネットに接続できませんでした。\n'
        '接続を確認して再度お試しください。',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onCancel?.call();
          },
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onRetry();
          },
          child: const Text('再試行'),
        ),
      ],
    ),
  );
}

/// ネットワークエラースナックバーを表示する
///
/// EDGE-001: ネットワークエラー時の再試行オプション
void showNetworkErrorSnackBar({
  required BuildContext context,
  required VoidCallback onRetry,
}) {
  showErrorSnackBar(
    context: context,
    message: '接続できませんでした',
    showRetry: true,
    onRetry: onRetry,
  );
}

// =============================================================================
// AI変換エラーダイアログ (EDGE-002)
// =============================================================================

/// AI変換エラーダイアログを表示する
///
/// EDGE-002: AI変換エラー時のフォールバック
///
/// [context] BuildContext
/// [originalText] 元のテキスト（フォールバック用）
/// [onUseOriginal] 元のテキストを使用するコールバック
/// [onRetry] 再試行ボタンのコールバック（オプション）
Future<void> showAIConversionErrorDialog({
  required BuildContext context,
  required String originalText,
  required VoidCallback onUseOriginal,
  VoidCallback? onRetry,
}) async {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.auto_fix_off, color: warningIconColor(context)),
          const SizedBox(width: 8),
          const Text('AI変換エラー'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI変換に失敗しました。\n'
            '元のテキストをそのまま使用することができます。',
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final boxColors = originalTextBoxColors(context);
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: boxColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: boxColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '元のテキスト:',
                      style: TextStyle(
                        fontSize: 12,
                        color: boxColors.label,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      originalText,
                      style: TextStyle(fontSize: 14, color: boxColors.body),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        if (onRetry != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry();
            },
            child: const Text('再試行'),
          ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onUseOriginal();
          },
          child: const Text('元のテキストを使用'),
        ),
      ],
    ),
  );
}

// =============================================================================
// TTS再生エラーダイアログ (EDGE-004)
// =============================================================================

/// TTS再生エラーダイアログを表示する
///
/// EDGE-004: TTS再生エラー時のメッセージ
///
/// [context] BuildContext
/// [onRetry] 再試行ボタンのコールバック（オプション）
Future<void> showTTSErrorDialog({
  required BuildContext context,
  VoidCallback? onRetry,
}) async {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.volume_off, color: warningIconColor(context)),
          const SizedBox(width: 8),
          const Text('読み上げエラー'),
        ],
      ),
      content: const Text(
        '読み上げに失敗しました。\n'
        'テキストは画面に表示されています。\n\n'
        '音量や端末の設定を確認してください。',
      ),
      actions: [
        if (onRetry != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry();
            },
            child: const Text('再試行'),
          ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// TTS再生エラースナックバーを表示する
///
/// EDGE-004: TTS再生エラー時のメッセージ
void showTTSErrorSnackBar({
  required BuildContext context,
  VoidCallback? onRetry,
}) {
  showErrorSnackBar(
    context: context,
    message: '読み上げに失敗しました。テキストは画面に表示されています。',
    showRetry: onRetry != null,
    onRetry: onRetry,
    duration: const Duration(seconds: 5),
  );
}

// =============================================================================
// 汎用エラーメッセージ定数
// =============================================================================

/// エラーメッセージ定数クラス
///
/// NFR-204: 分かりやすい日本語エラーメッセージ
class ErrorMessages {
  ErrorMessages._();

  /// ネットワークエラーメッセージ
  static const String networkError = '接続できませんでした。インターネット接続を確認してください。';

  /// タイムアウトエラーメッセージ
  static const String timeoutError = '接続がタイムアウトしました。しばらくしてから再度お試しください。';

  /// サーバーエラーメッセージ
  static const String serverError = 'サーバーに問題が発生しました。しばらくしてから再度お試しください。';

  /// AI変換エラーメッセージ
  static const String aiConversionError = 'AI変換に失敗しました。元のテキストを使用できます。';

  /// TTS再生エラーメッセージ
  static const String ttsError = '読み上げに失敗しました。端末の設定を確認してください。';

  /// 不明なエラーメッセージ
  static const String unknownError = 'エラーが発生しました。しばらくしてから再度お試しください。';

  /// データ保存エラーメッセージ
  static const String saveError = 'データの保存に失敗しました。';

  /// データ読み込みエラーメッセージ
  static const String loadError = 'データの読み込みに失敗しました。';
}

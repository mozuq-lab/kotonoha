/// エラーダイアログ/スナックバー ウィジェット
///
/// TASK-0078: エラーUI・エラーメッセージ実装
///
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
/// 関連要件:
/// - NFR-204: 分かりやすい日本語エラーメッセージ
/// - EDGE-001: ネットワークエラー時の再試行オプション
/// - EDGE-002: AI変換エラー時のフォールバック
/// - EDGE-004: TTS再生エラー時のメッセージ
library;

import 'package:flutter/material.dart';

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
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: Colors.red[700],
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
          Icon(Icons.wifi_off, color: Colors.orange[700]),
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
          Icon(Icons.auto_fix_off, color: Colors.orange[700]),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '元のテキスト:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  originalText,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
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
          Icon(Icons.volume_off, color: Colors.orange[700]),
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

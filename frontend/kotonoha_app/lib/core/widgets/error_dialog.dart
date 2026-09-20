/// エラーダイアログ/スナックバー ウィジェット
/// 分かりやすい日本語エラーメッセージ
/// ネットワークエラー時の再試行オプション
/// AI変換エラー時のフォールバック
/// TTS再生エラー時のメッセージ
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/shared/widgets/confirmation_dialog.dart';

import '../themes/theme_colors.dart';

// エラースナックバーの配色

/// 設定定数: エラースナックバーの背景色（Colors.red[700] 相当）
const Color _snackBarBackground = Color(0xFFD32F2F);

/// 設定定数: エラースナックバーの前景色
/// 背景 #D32F2F に対し 4.98:1 で WCAG 2.1 AA (4.5:1) を満たす。
const Color _snackBarForeground = Color(0xFFFFFFFF);

// エラースナックバー

/// エラースナックバーを表示する
/// [context] BuildContext
/// [message] エラーメッセージ
/// [showRetry] 再試行ボタンを表示するかどうか
/// [onRetry] 再試行ボタンのコールバック
/// [duration] 表示時間（デフォルト4秒）
/// 分かりやすい日本語エラーメッセージ
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

/// ネットワークエラースナックバーを表示する
/// ネットワークエラー時の再試行オプション
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

// TTS再生エラーダイアログ

/// TTS再生エラーダイアログを表示する
/// TTS再生エラー時のメッセージ
/// [context] BuildContext
/// [onRetry] 再試行ボタンのコールバック（オプション）
Future<void> showTTSErrorDialog({
  required BuildContext context,
  VoidCallback? onRetry,
}) async {
  return showDialog(
    context: context,
    builder: (context) => ConfirmationDialogLayout.build(
      title: Row(
        children: [
          Icon(Icons.volume_off, color: warningIconColor(context)),
          const SizedBox(width: 8),
          // 見出しは折り返せるようにする。`Expanded` が無いと、
          // 幅 320・倍率 1.0 でも右へあふれてボタンが切れる（台帳 L-133）
          const Expanded(child: Text('読み上げエラー')),
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
/// TTS再生エラー時のメッセージ
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

// 汎用エラーメッセージ定数

/// エラーメッセージ定数クラス
/// 分かりやすい日本語エラーメッセージ
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

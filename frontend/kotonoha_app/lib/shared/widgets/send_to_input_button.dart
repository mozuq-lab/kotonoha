/// 「入力欄へ」ボタン
///
/// 改善: 定型文・履歴・お気に入りタップ = 即時読み上げのみで、
/// 「入力欄に入れて編集してからAI変換したい」という導線が存在しなかった
/// （REQ-102未実装、ヘルプの「すばやく入力できます」との齟齬）。
///
/// 定型文・履歴・お気に入りの各アイテムから、そのテキストを直接
/// 文字盤の入力欄に送り込むための明示的な操作ボタン。
/// タップ時の動作:
/// - 入力欄が空の場合: そのまま挿入してホーム画面へ遷移する
/// - 入力欄が空でない場合: 置換確認ダイアログを表示し、確定後にホーム画面へ遷移する
///
/// 既存の「タップ=即時読み上げ」動作とは独立した別ボタンとして提供し、
/// 既存動作を維持する。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/core/router/app_router.dart';
import 'package:kotonoha_app/features/character_board/providers/input_buffer_provider.dart';

/// 「入力欄へ」ボタンウィジェット
///
/// アイコン+ラベル表示、タップターゲット44px以上（REQ-5001準拠）。
class SendToInputButton extends ConsumerWidget {
  /// 「入力欄へ」ボタンを作成する。
  ///
  /// [text] - 入力欄に送るテキスト
  const SendToInputButton({super.key, required this.text});

  /// 入力欄に送るテキスト
  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      label: '入力欄へ',
      hint: 'タップするとこの内容を入力欄にセットします',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall),
          onTap: text.isEmpty
              ? null
              : () =>
                  sendTextToInputBuffer(context: context, ref: ref, text: text),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: AppSizes.minTapTarget,
              minHeight: AppSizes.minTapTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingXSmall,
                vertical: AppSizes.paddingXSmall,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.input, size: AppSizes.iconSizeSmall, color: color),
                  Text(
                    '入力欄へ',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// テキストを入力バッファへ送り、ホーム画面へ遷移する。
///
/// 入力バッファが空の場合はそのまま挿入する。
/// 空でない場合は置換確認ダイアログを表示し、「置き換える」が選択された
/// 場合のみ上書きする（確認なしの末尾追加はしない）。
///
/// テスト等、[SendToInputButton]を経由せず直接呼び出す用途にも使えるよう
/// トップレベル関数として公開する。
Future<void> sendTextToInputBuffer({
  required BuildContext context,
  required WidgetRef ref,
  required String text,
}) async {
  if (text.isEmpty) return;

  final currentBuffer = ref.read(inputBufferProvider);
  if (currentBuffer.isEmpty) {
    ref.read(inputBufferProvider.notifier).setText(text);
    _goHome(context);
    return;
  }

  final shouldReplace = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('入力欄へ'),
          content: const Text('入力中の内容を置き換えて入力欄にセットします。よろしいですか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('置き換える'),
            ),
          ],
        ),
      ) ??
      false;

  if (!shouldReplace) return;

  ref.read(inputBufferProvider.notifier).setText(text);
  if (context.mounted) _goHome(context);
}

void _goHome(BuildContext context) {
  if (!context.mounted) return;
  context.go(AppRoutes.home);
}
